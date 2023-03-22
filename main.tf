resource "aws_s3_bucket" "sftp_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sftp_bucket_encryption" {
  bucket = aws_s3_bucket.sftp_bucket.id

  rule {
        apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "sftp_bucket_public_access_block" {
  bucket = aws_s3_bucket.sftp_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_object" "novartis_dev_object" {
  bucket = aws_s3_bucket.sftp_bucket.id
  key    = "novartis-dev/"
  server_side_encryption = "AES256"
}

resource "aws_s3_object" "novartis_prod_object" {
  bucket = aws_s3_bucket.sftp_bucket.id
  key    = "novartis-prod/"
  server_side_encryption = "AES256"
}

resource "aws_iam_policy" "policy" {
  for_each = fileset(path.module, "policy_documents/*")
  
  name = trimsuffix(basename(each.value), ".json")
  policy = file(each.value)
}


resource "aws_iam_role" "role" {
  for_each = fileset(path.module, "role_documents/*")
  name = trimsuffix(basename(each.value), ".json")

  assume_role_policy = file(each.value)
}

resource "aws_iam_role_policy_attachment" "read-attach" {
  role       = aws_iam_role.role["role_documents/s3_bucket_read_role.json"].name
  policy_arn =  aws_iam_policy.policy["policy_documents/s3_bucket_read_policy.json"].arn
}

resource "aws_iam_role_policy_attachment" "write-attach" {
  role       = aws_iam_role.role["role_documents/s3_bucket_write_role.json"].name
  policy_arn =  aws_iam_policy.policy["policy_documents/s3_bucket_write_policy.json"].arn
}

data "aws_route53_zone" "hosted_zone" {
  name         = var.hosted_zone_name
}

resource "aws_transfer_server" "sftp_server" {
  domain = "S3"
  protocols = ["SFTP"]
  endpoint_type = "PUBLIC"
  identity_provider_type = "SERVICE_MANAGED"
  security_policy_name = "TransferSecurityPolicy-2020-06"
}

resource "aws_transfer_tag" "zone_id" {
  resource_arn = aws_transfer_server.sftp_server.arn
  key          = "aws:transfer:route53HostedZoneId"
  value        = "/hostedzone/${data.aws_route53_zone.hosted_zone.zone_id}"
}

resource "aws_transfer_tag" "hostname" {
  resource_arn = aws_transfer_server.sftp_server.arn
  key          = "aws:transfer:customHostname"
  value        = var.sftp_hostname
}

resource "aws_route53_record" "sftp_record" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = var.sftp_hostname
  type    = "CNAME"
  ttl     = 5
  records        = ["${aws_transfer_server.sftp_server.endpoint}"]
}

resource "aws_transfer_user" "sftp_users" {
  for_each = var.sftp_users

  server_id = aws_transfer_server.sftp_server.id
  user_name = each.value.user_name
  role      = aws_iam_role.role["role_documents/${each.value.role}.json"].arn

  home_directory_type = "LOGICAL"
  home_directory_mappings {
        entry  = "/"
        target = "/${aws_s3_bucket.sftp_bucket.id}/${each.value.home_dir}"
    }
}
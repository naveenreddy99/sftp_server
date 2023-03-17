bucket_name = "mm-sftp-service1"
sftp_hostname = "sftp.nave.com" #"sftp.markmonitor.com"
hosted_zone_name = "nave.com" #"markmonitor.com."

sftp_users = {
    "novartis_dev"              = { user_name = "novartis_dev"
                                    role = "s3_bucket_read_role"
                                    home_dir = "novartis-dev"
                                    }
    "hiddenmaster_novartis_dev" = { user_name = "hiddenmaster_novartis_dev"
                                    role = "s3_bucket_write_role"
                                    home_dir = "novartis-dev"
                                    }
    "novartis_prod"              = { user_name = "novartis_prod"
                                    role = "s3_bucket_read_role"
                                    home_dir = "novartis-prod"
                                    }
    "hiddenmaster_novartis_dev" = { user_name = "hiddenmaster_novartis_prod"
                                    role = "s3_bucket_write_role"
                                    home_dir = "novartis-prod"
                                    }

}
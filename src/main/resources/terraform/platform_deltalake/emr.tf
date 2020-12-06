
resource "aws_emr_cluster" "cluster" {
  name          = var.cluster_name
  release_label = "emr-6.1.0"
  applications = ["Spark","Hadoop","Zeppelin"]
  log_uri = "s3n://${var.logs_bucket_name}/emr/logs/"
  keep_job_flow_alive_when_no_steps = true


  ec2_attributes {
    subnet_id                         = var.main_subnet_id
    emr_managed_master_security_group = var.security_group_id
    emr_managed_slave_security_group  = var.security_group_id
    instance_profile                  = aws_iam_instance_profile.emr_profile.arn
    key_name = aws_key_pair.generated_key.key_name
  }



  master_instance_group {
    instance_type = "m5a.2xlarge"
  }

  core_instance_group {
    instance_count = 1
    instance_type  = "m5a.xlarge"
  }

  service_role = aws_iam_role.service_role.arn
}




# IAM Role for EC2 Instance Profile
resource "aws_iam_role" "iam_emr_profile_role" {
  name = "iam_emr_tr_dataplatform_profile_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group_rule" "whitelist_known_ips_to_master" {
  from_port = 22
  protocol = "TCP"
  security_group_id = var.security_group_id
  to_port = 22
  type = "ingress"
  cidr_blocks = [var.known_ip_cidrs]
}

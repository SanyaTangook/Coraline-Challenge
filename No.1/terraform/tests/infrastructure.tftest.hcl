# These tests use Terraform's mock AWS provider. No AWS credentials or cloud
# resources are required to run them.
mock_provider "aws" {
  # The AWS provider validates IAM policy JSON during planning, so mocked IAM
  # policy-document data must remain valid JSON rather than a placeholder.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_ssm_parameter" {
    defaults = {
      value = "ami-0123456789abcdef0"
    }
  }
}

run "postgres_is_private_and_encrypted" {
  command = plan

  assert {
    condition     = aws_db_instance.postgres.publicly_accessible == false
    error_message = "PostgreSQL RDS must not be publicly accessible."
  }

  assert {
    condition     = aws_db_instance.postgres.manage_master_user_password == true
    error_message = "PostgreSQL credentials must be managed by RDS in Secrets Manager."
  }

  assert {
    condition     = aws_db_instance.postgres.deletion_protection == true
    error_message = "PostgreSQL deletion protection must remain enabled."
  }

  assert {
    condition     = aws_db_instance.postgres.multi_az == true
    error_message = "The production baseline must use Multi-AZ RDS."
  }
}

run "ec2_bootstraps_metabase_with_mocked_values" {
  command = plan

  variables {
    name                    = "mock-app-network"
    metabase_database_name  = "metabase"
    metabase_allowed_cidrs  = ["203.0.113.10/32"]
  }

  assert {
    condition     = aws_instance.app.instance_type == "t4g.micro"
    error_message = "The expected mock instance type was not selected."
  }

  assert {
    condition     = aws_instance.app.associate_public_ip_address == true
    error_message = "Metabase EC2 must have a public IP for external access."
  }

  assert {
    condition     = length(aws_security_group.ec2.ingress) == 1
    error_message = "Metabase should have exactly one mocked inbound rule."
  }
}

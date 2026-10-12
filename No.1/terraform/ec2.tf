# AWS maintains this public parameter with the current Amazon Linux 2023 ARM64
# AMI ID. It is more reliable than matching an AMI name, which changes when
# AWS updates the kernel release.
data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

resource "aws_iam_role" "ec2_ssm" {
  name_prefix        = "${var.name}-ec2-ssm-"
  description        = "Allows the EC2 instance to connect through AWS Systems Manager"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "ec2_read_rds_secret" {
  statement {
    sid       = "ReadMetabaseDatabaseCredentials"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.postgres.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_role_policy" "ec2_read_rds_secret" {
  name   = "read-rds-master-secret"
  role   = aws_iam_role.ec2_ssm.id
  policy = data.aws_iam_policy_document.ec2_read_rds_secret.json
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name_prefix = "${var.name}-ec2-ssm-"
  role        = aws_iam_role.ec2_ssm.name
}

# Metabase is reachable on TCP/3000 only from metabase_allowed_cidrs. It can
# make outbound connections for package updates and SSM; PostgreSQL access
# stays private in the VPC and is allowed by the RDS security group.
resource "aws_security_group" "ec2" {
  name_prefix = "${var.name}-ec2-"
  description = "Metabase web access and outbound access for SSM and updates"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = toset(var.metabase_allowed_cidrs)

    content {
      description = "Metabase web UI"
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "HTTPS and package update traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-ec2"
  })
}

resource "aws_instance" "app" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type          = var.ec2_instance_type
  subnet_id              = module.vpc.public_subnets[0]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name
  vpc_security_group_ids = [aws_security_group.ec2.id]

  monitoring                  = true
  associate_public_ip_address = true
  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/templates/metabase-bootstrap.sh.tftpl", {
    aws_region       = var.aws_region
    rds_secret_arn   = aws_db_instance.postgres.master_user_secret[0].secret_arn
    metabase_db_name = var.metabase_database_name
    metabase_image   = var.metabase_image
  })

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = var.ec2_root_volume_size_gib
  }

  tags = merge(var.tags, {
    Name = "${var.name}-app"
  })
}

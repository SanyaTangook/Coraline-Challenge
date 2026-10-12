variable "aws_region" {
  description = "AWS region in which to create the network."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Short, unique name used to identify network resources."
  type        = string
  default     = "app-network"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,32}$", var.name))
    error_message = "name must be 3-32 lowercase letters, numbers, or hyphens."
  }
}

variable "availability_zone" {
  description = "Availability Zone for the public subnet and first private database subnet."
  type        = string
  default     = "us-east-1a"
}

variable "secondary_availability_zone" {
  description = "Second Availability Zone for the RDS DB subnet group."
  type        = string
  default     = "us-east-1b"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "IPv4 CIDR block for the single public subnet. It must be inside vpc_cidr."
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.public_subnet_cidr))
    error_message = "public_subnet_cidr must be a valid IPv4 CIDR block."
  }
}

variable "private_db_subnet_cidr_a" {
  description = "IPv4 CIDR block for the first private database subnet."
  type        = string
  default     = "10.0.11.0/24"

  validation {
    condition     = can(cidrnetmask(var.private_db_subnet_cidr_a))
    error_message = "private_db_subnet_cidr_a must be a valid IPv4 CIDR block."
  }
}

variable "private_db_subnet_cidr_b" {
  description = "IPv4 CIDR block for the second private database subnet."
  type        = string
  default     = "10.0.12.0/24"

  validation {
    condition     = can(cidrnetmask(var.private_db_subnet_cidr_b))
    error_message = "private_db_subnet_cidr_b must be a valid IPv4 CIDR block."
  }
}

variable "flow_log_retention_in_days" {
  description = "Number of days to retain VPC Flow Logs in CloudWatch."
  type        = number
  default     = 90

  validation {
    condition     = var.flow_log_retention_in_days >= 1
    error_message = "flow_log_retention_in_days must be at least 1."
  }
}

variable "postgres_engine_version" {
  description = "Optional PostgreSQL engine version. Set null to use AWS's default supported version."
  type        = string
  default     = null
  nullable    = true
}

variable "db_instance_class" {
  description = "RDS instance class for PostgreSQL."
  type        = string
  default     = "db.t4g.medium"
}

variable "db_allocated_storage_gib" {
  description = "Initial gp3 storage allocation, in GiB."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage_gib" {
  description = "Maximum storage autoscaling limit, in GiB."
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Name of the initial PostgreSQL database."
  type        = string
  default     = "app"
}

variable "database_username" {
  description = "Master username. Its password is managed in AWS Secrets Manager by RDS."
  type        = string
  default     = "dbadmin"
}

variable "db_multi_az" {
  description = "Whether to create a standby instance in the second DB subnet."
  type        = bool
  default     = true
}

variable "db_backup_retention_days" {
  description = "Number of days to retain automated RDS backups."
  type        = number
  default     = 7

  validation {
    condition     = var.db_backup_retention_days >= 7 && var.db_backup_retention_days <= 35
    error_message = "db_backup_retention_days must be between 7 and 35 for this production baseline."
  }
}

variable "ec2_instance_type" {
  description = "Graviton instance type for the application EC2 instance."
  type        = string
  default     = "t4g.micro"
}

variable "ec2_root_volume_size_gib" {
  description = "Size of the encrypted EC2 root volume, in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.ec2_root_volume_size_gib >= 8
    error_message = "ec2_root_volume_size_gib must be at least 8 GiB."
  }
}

variable "metabase_database_name" {
  description = "PostgreSQL database RDS creates for Metabase application metadata."
  type        = string
  default     = "metabase"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.metabase_database_name))
    error_message = "metabase_database_name must begin with a lowercase letter and use only lowercase letters, numbers, and underscores."
  }
}

variable "metabase_image" {
  description = "Pinned Docker image for Metabase."
  type        = string
  default     = "metabase/metabase:v0.53.0"
}

variable "metabase_allowed_cidrs" {
  description = "IPv4 CIDR blocks permitted to open the public Metabase UI on TCP/3000. Replace the default with trusted IP addresses for production."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.metabase_allowed_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every metabase_allowed_cidrs value must be a valid IPv4 CIDR block."
  }
}

variable "tags" {
  description = "Tags applied to all supported AWS resources."
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

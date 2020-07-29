variable "region" {
  description = "Region to deploy VPC"
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "Existing VPC to use (specify this, if you don't want to create new VPC)"
  default     = ""
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "10.10.0.0/16"
}

variable "subnet_id_primary" {
    description = "Existing Subnet id primary to use"
    default = ""
}

variable "subnet_id_secondary" {
    description = "Existing Subnet id secondary"
    default = ""
}

variable "subnet_id_third" {
    description = "Existing Subnet id third"
    default = ""
}

variable "subnet_id_fourth" {
    description = "Existing Subnet id third"
    default = ""
}

variable "subnet_cidr_primary" {
    description = "The CIDR block for the 1st subnet"
    default = "10.10.101.0/24"
}

variable "subnet_cidr_secondary" {
    description = "The CIDR block for the 2nd subnet"
    default = "10.10.102.0/24"
}

variable "subnet_cidr_third" {
    description = "The CIDR block for the 3rd subnet"
    default = "10.10.103.0/24"
}

variable "subnet_cidr_fourth" {
    description = "The CIDR block for the 3rd subnet"
    default = "10.10.104.0/24"
}

variable "cidr_block_sec_grp_ssh" {
    description = "The CIDR block for the 3rd subnet"
    default = "0.0.0.0/0"
}

variable "cidr_block_sec_grp_https" {
    description = "The CIDR block for the 3rd subnet"
    default = "0.0.0.0/0"
}

variable "cidr_block_sec_grp_http" {
    description = "The CIDR block for the 3rd subnet"
    default = "0.0.0.0/0"
}

variable "cidr_block_sec_grp_frontend" {
    description = "The CIDR block for the 3rd subnet"
    default = "0.0.0.0/0"
}

variable "cidr_block_sec_grp_backend" {
    description = "The CIDR block for the 3rd subnet"
    default = "0.0.0.0/0"
}

variable "cidr_block_sec_grp_webapp" {
    description = "The CIDR block for the 3rd subnet"
    default = "0.0.0.0/0"
}

variable "cidr_block_sec_grp_statsd"{
    description = "The CIDR block for statsd group"
    default = "0.0.0.0/0"
}

variable "cidr_block_sec_grp_outbound" {
    description = "The CIDR block for the 3rd subnet"
    default = "0.0.0.0/0"
}

variable "db_master_password" {
    description = "Password for master db in RDS"
    type = "string"
}

variable "db_master_username" {
    description = "Username for master db in RDS"
    type = "string"
    default = "csye6225su2020"
}

variable "db_identifier" {
    description = "Username for master db in RDS"
    default = "csye6225-su2020"
}

variable "publicly_accessible" {
    description = "Public accessibility of RDS subnet ip"
    default = false
}

variable "s3_bucket_name" {
    description = "s3 bucket name"
    default = "webapp.aishwarya.patil"
}

variable "ssh_key_name" {
    description = "SSH key name for ec2"
    default = "csye_6225_ami_ssh"
}

variable "backend_port" {
    description = "Backend port"
    default = 5000
}

variable "frontend_port" {
    description = "Frontend port"
    default = 3000
}

variable "statsd_port" {
    description = "StatsD port"
    default = 8125
}

variable "db_port" {
    description = "DB port"
    default = 3306
}

variable "storage_rds" {
    description = "Allocate storage for RDS"
    default = 20
}

variable "rds_engine" {
    description = "RDS Engine"
    default = "mysql"
}

variable "rds_engine_version" {
    description = "RDS Engine Version"
    default = "5.7"
}

variable "rds_instance_class" {
    description = "RDS Instance Class"
    default = "db.t3.micro"
}

variable "rds_instance_name" {
    description = "RDS Instance Name"
    default = "csye6225"
}

variable "ami_image_name" {
    description = "AMI image name"
    default = "csye6225_ubuntu_image"
}

variable "root_block_device_volume_type" {
    description = "Root Block device Volume type"
    default = "gp2"
}

variable "root_block_device_volume_size" {
    description = "Root Block device Volume size"
    default = 20
}

variable "prod_access_key"{
    description = "Prod access key id"
}

variable "prod_secret_key"{
    description = "Prod secret access key"
}

variable "ami_owner" {
    description = "User that created the ami"
    default = 112710657666
}

variable "code_deploy_s3_bucket_name" {
    description = "Bucket name for code deploy"
    default = "codedeploy.neucloudwebapp.me"
}


variable "circleci_user_name" {
    description = "Circleci user name"
    default = "circleci"
}

variable "aws_account_id" {
    description = "AWS account id for attaching policy"
    default = 918568617781
}

variable "code_deploy_application_name" {
    description = "Code Deploy application name"
    default = "csye6225-webapp"
}

variable "code_deploy_group_name" {
    description = "Code Deployment group name"
    default = "csye6225-webapp-deployment"
}

variable "ec2_tag_value" {
    description = "EC2 tag value"
    default = "csye6225_ec2"
}

variable "code_deploy_config_name" {
    description = "Code Deployed Config name"
    default = "CodeDeployDefault.AllAtOnce"
}

variable "domain_name" {
    description = "Domain name for prod"
    default = "prod.neucloudwebapp.me."
}

variable "r53_zone_id" {
    description = "Zone Id for Prod Route 53"
    default = "Z09843643E1PAHJ5TFG98"
}

variable "lambda_function_name" {
    description = "Lambda Function Name"
    default = "lambda_webapp"
}

variable "key_usage" {
    description = "Key usage for KMS attribute"
    default = "ENCRYPT_DECRYPT"
}
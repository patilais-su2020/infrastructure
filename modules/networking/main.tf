provider "aws" {
    region = "${var.region}"
}

resource "aws_vpc" "selected" {
    cidr_block = "${var.cidr}"
    enable_dns_hostnames = true
    enable_dns_support = true
    assign_generated_ipv6_cidr_block = false
    enable_classiclink_dns_support = true

    tags = {
        Name = "csye6225-vpc"
    }
}

data "aws_availability_zones" "available" {
    state = "available"
}


resource "aws_subnet" "primary-subnet" {
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    vpc_id            = "${aws_vpc.selected.id}"
    cidr_block = "${var.subnet_cidr_primary}"
    map_public_ip_on_launch = true

    tags = {
        Name = "csye-subnet-primary"
    }
}

resource "aws_subnet" "secondary-subnet" {
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
    vpc_id            = "${aws_vpc.selected.id}"
    cidr_block = "${var.subnet_cidr_secondary}"
    map_public_ip_on_launch = true

    tags = {
        Name = "csye-subnet-secondary"
    }
}

resource "aws_subnet" "third-subnet" {
    availability_zone       = "${data.aws_availability_zones.available.names[2]}"
    vpc_id                  = "${aws_vpc.selected.id}"
    cidr_block              = "${var.subnet_cidr_third}"
    map_public_ip_on_launch = true

    tags = {
        Name = "csye-subnet-third"
    }
}

resource "aws_subnet" "fourth-subnet" {
    availability_zone       = "${data.aws_availability_zones.available.names[1]}"
    vpc_id                  = "${aws_vpc.selected.id}"
    cidr_block              = "${var.subnet_cidr_fourth}"

    tags = {
        Name = "csye-subnet-fourth"
    }
}

resource "aws_internet_gateway" "vpc_gway" {
  vpc_id = "${aws_vpc.selected.id}"

  tags = {
    Name = "internet-gateway"
  }
}

#Route Table for VPC
resource "aws_route_table" "dev_routetable" {
    vpc_id = "${aws_vpc.selected.id}"
}

#Default Route for the above route table
resource "aws_route" "dev_default_route" {
    route_table_id = "${aws_route_table.dev_routetable.id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.vpc_gway.id}"
     depends_on = [
        "aws_route_table.dev_routetable",
        "aws_internet_gateway.vpc_gway"
    ]
}

#Attaching primary subnet to route table
resource "aws_route_table_association" "priamry-routetable-association" {
    subnet_id = "${aws_subnet.primary-subnet.id}"
    route_table_id = "${aws_route_table.dev_routetable.id}"
}

#Attaching secondary subnet to route table
resource "aws_route_table_association" "secondary-routetable-association" {
    subnet_id = "${aws_subnet.secondary-subnet.id}"
    route_table_id = "${aws_route_table.dev_routetable.id}"
}

#Attaching third subnet to route table
resource "aws_route_table_association" "third-routetable-association" {
    subnet_id = "${aws_subnet.third-subnet.id}"
    route_table_id = "${aws_route_table.dev_routetable.id}"
}

#Attaching fourth subnet to route table
resource "aws_route_table_association" "fourth-routetable-association" {
    subnet_id = "${aws_subnet.fourth-subnet.id}"
    route_table_id = "${aws_route_table.dev_routetable.id}"
}

#Attaching Security Group to EC2 instance
resource "aws_security_group" "application_sec_grp" {
  name        = "application_sec_grp"
  description = "Setting inbound and outbound traffic"
  vpc_id      = "${aws_vpc.selected.id}"

 ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block_sec_grp_ssh}"]
  }

  ingress {
    description = "Https from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block_sec_grp_https}"]
  }

  ingress {
    description = "Http for VPC"
    from_port   = 80
    to_port     = 80
    protocol    = 6
    cidr_blocks = ["${var.cidr_block_sec_grp_http}"]
  }

  ingress {
    description = "Frontend Port for webapp"
    from_port   = "${var.frontend_port}"
    to_port     = "${var.frontend_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block_sec_grp_frontend}"]
  }

  ingress {
    description = "Backend Port for webapp"
    from_port   = "${var.backend_port}"
    to_port     = "${var.backend_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block_sec_grp_backend}"]
  }

  ingress {
    description = "Proxy Port for webapp"
    from_port   = "${var.proxy_port}"
    to_port     = "${var.proxy_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block_sec_grp_webapp}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr_block_sec_grp_outbound}"]
  }

  tags = {
    Name = "application_sec_grp"
  }
}

#Creating DB Security for RDS
resource "aws_security_group" "database_sec_grp" {
  name        = "database_sec_grp"
  description = "Setting inbound and outbound traffic"
  vpc_id      = "${aws_vpc.selected.id}"

  ingress {
    description = "Database port for webapp"
    from_port   = "${var.db_port}"
    to_port     = "${var.db_port}"
    protocol    = "tcp"
    security_groups = ["${aws_security_group.application_sec_grp.id}"]
  }

  tags = {
    Name = "database_sec_grp"
  }
}

#Creating S3
resource "aws_s3_bucket" "webapp_s3_bucket" {
  bucket = "${var.s3_bucket_name}"
  acl    = "private"
  force_destroy = true

  #Default server side encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }

  lifecycle_rule {

    enabled = true

    noncurrent_version_transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

#Creating a subnet group for RDS instance
resource "aws_db_subnet_group" "rds_db_subnet_grp" {
  name       = "rds_db_subnet_grp"
  subnet_ids = ["${aws_subnet.fourth-subnet.id}","${aws_subnet.third-subnet.id}"]

  tags = {
    Name = "My DB subnet group"
  }
}

#Creating an AWS instance
resource "aws_db_instance" "rds_instance" {
  allocated_storage    = var.storage_rds
  engine               = var.rds_engine
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class
  multi_az             = false
  identifier           = var.db_identifier
  name                 = var.rds_instance_name
  username             = var.db_master_username
  password             = var.db_master_password
  publicly_accessible  = var.publicly_accessible
  db_subnet_group_name = aws_db_subnet_group.rds_db_subnet_grp.name
  vpc_security_group_ids = [aws_security_group.database_sec_grp.id]
  skip_final_snapshot = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "tag:Name"
    values = [var.ami_image_name]
  }

  owners = ["112710657666"]
}

#Creating EC2 instance
resource "aws_instance" "csye_6225_ec2" {
  ami                     = "${data.aws_ami.ubuntu.id}"
  instance_type           = "t2.micro"
  vpc_security_group_ids  = ["${aws_security_group.application_sec_grp.id}"] 
  subnet_id               = "${aws_subnet.primary-subnet.id}"
  disable_api_termination = false
  key_name                = "${var.ssh_key_name}"
  iam_instance_profile    = "${aws_iam_instance_profile.ec2_profile.name}"
  user_data = <<-EOF
          #!/bin/bash
          echo "db_hostname=${aws_db_instance.rds_instance.address}">>/home/ubuntu/.bashrc
          echo "db_username=${var.db_master_username}">>/home/ubuntu/.bashrc
          echo "db_password=${var.db_master_password}">>/home/ubuntu/.bashrc
          echo "s3_bucket_name=${var.s3_bucket_name}">>/home/ubuntu/.bashrc
      EOF  
  root_block_device {
    volume_type           =  var.root_block_device_volume_type
    volume_size           =  var.root_block_device_volume_size
    delete_on_termination = true
  }

  depends_on = [
    aws_db_instance.rds_instance
  ] 
  
  tags = {
    Name = "csye6225_ec2"
  }
}

#Creating DynamoDb 
resource "aws_dynamodb_table" "csye-dynamodb-table" {
  name           = "csye6225"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}



#Creating IAM policy
resource "aws_iam_policy" "WebAppS3" {
  name        = "WebAppS3"
  description = "S3 bucket policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "s3:PutObject",
              "s3:GetObject",
              "s3:DeleteObject"
          ],
          "Effect": "Allow",
          "Resource": [
              "arn:aws:s3:::${var.s3_bucket_name}",
              "arn:aws:s3:::${var.s3_bucket_name}/*"
          ]
      }
  ]
}
EOF
}

resource "aws_iam_role" "ec2_s3_role" {
  name = "EC2-CSYE6225"

  assume_role_policy = "${file("ec2s3role.json")}"

  tags = {
    Name = "EC2-Iam role"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_s3_attach" {
  role       = "${aws_iam_role.ec2_s3_role.name}"
  policy_arn = "${aws_iam_policy.WebAppS3.arn}"
}

#Profile for attachment to EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = "${aws_iam_role.ec2_s3_role.name}"
}

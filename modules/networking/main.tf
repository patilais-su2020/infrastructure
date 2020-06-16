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
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
    vpc_id            = "${aws_vpc.selected.id}"
    cidr_block = "${var.subnet_cidr_third}"
    map_public_ip_on_launch = true

    tags = {
        Name = "csye-subnet-third"
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
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block_sec_grp_frontend}"]
  }

  ingress {
    description = "Backend Port for webapp"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block_sec_grp_backend}"]
  }

  ingress {
    description = "Proxy Port for webapp"
    from_port   = 5000
    to_port     = 5000
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
  vpc_id = "${aws_vpc.selected.id}"
  ingress {
    description = "Database port for webapp"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = ["${aws_security_group.application_sec_grp.id}"]
  }

  tags = {
    Name = "database_sec_grp"
  }
}

#Creating S3
resource "aws_s3_bucket" "webapp_s3_bucket" {
  bucket = "webapp.aishwarya.patil"
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

#Creating Subnet for RDS instance
resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = ["${aws_subnet.frontend.id}", "${aws_subnet.backend.id}"]

  tags = {
    Name = "My DB subnet group"
  }
}

#Creating an AWS instance
resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  multi_az             = "false"
  identifier           = "${var.db_identifier}"
  name                 = "webappdb"
  username             = "${var.db_master_username}"
  password             = "${var.db_master_password}"
  parameter_group_name = "default.mysql5.7"
}


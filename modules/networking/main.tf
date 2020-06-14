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
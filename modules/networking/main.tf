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
    security_groups = ["${aws_security_group.load_balancer_sec_grp.id}"]
  }

  ingress {
    description = "Https from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = ["${aws_security_group.load_balancer_sec_grp.id}"]
  }

  ingress {
    description = "Http for VPC"
    from_port   = 80
    to_port     = 80
    protocol    = 6
    security_groups = ["${aws_security_group.load_balancer_sec_grp.id}"]
  }

  ingress {
    description = "Frontend Port for webapp"
    from_port   = "${var.frontend_port}"
    to_port     = "${var.frontend_port}"
    protocol    = "tcp"
    security_groups = ["${aws_security_group.load_balancer_sec_grp.id}"]
  }

  ingress {
    description = "Backend Port for webapp"
    from_port   = "${var.backend_port}"
    to_port     = "${var.backend_port}"
    protocol    = "tcp"
    security_groups = ["${aws_security_group.load_balancer_sec_grp.id}"]
  }

  ingress {
    description = "StatsD Port for cloudwatch"
    from_port   = "${var.statsd_port}"
    to_port     = "${var.statsd_port}"
    protocol    = "tcp"
    security_groups = ["${aws_security_group.load_balancer_sec_grp.id}"]
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
  name_regex = "^csye6225_a4_.*"

  owners = ["${var.ami_owner}"]
}

#Creating EC2 instance
# resource "aws_instance" "csye_6225_ec2" {
#   ami                     = "${data.aws_ami.ubuntu.id}"
#   instance_type           = "t2.micro"
#   vpc_security_group_ids  = ["${aws_security_group.application_sec_grp.id}"] 
#   subnet_id               = "${aws_subnet.primary-subnet.id}"
#   disable_api_termination = false
#   key_name                = var.ssh_key_name
#   iam_instance_profile    = "${aws_iam_instance_profile.ec2_profile.name}"
#   user_data = <<-EOF
#           #!/bin/bash
#           echo export "AWS_ACCESS_KEY_ID=${var.prod_access_key}" | sudo tee -a /etc/environment
#           echo export "AWS_SECRET_ACCESS_KEY=${var.prod_secret_key}" | sudo tee -a /etc/environment
#           echo export "AWS_REGION=${var.region}" | sudo tee -a /etc/environment
#           echo export "db_name=${var.rds_instance_name}" | sudo tee -a /etc/environment
#           echo export "db_hostname=${aws_db_instance.rds_instance.address}" | sudo tee -a /etc/environment
#           echo export "db_username=${var.db_master_username}" | sudo tee -a /etc/environment
#           echo export "db_password=${var.db_master_password}" | sudo tee -a /etc/environment
#           echo export "s3_bucket_name=${var.s3_bucket_name}" | sudo tee -a /etc/environment
#       EOF  
#   root_block_device {
#     volume_type           =  var.root_block_device_volume_type
#     volume_size           =  var.root_block_device_volume_size
#     delete_on_termination = true
#   }

#   depends_on = [
#     aws_db_instance.rds_instance
#   ] 
  
#   tags = {
#     Name = "csye6225_ec2"
#   }
# }

#Creating DynamoDb 
resource "aws_dynamodb_table" "csye-dynamodb-table" {
  name           = "csye6225"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "UUID"

  attribute {
    name = "UUID"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}



#Creating IAM policy for S3 bucket 
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
              "arn:aws:s3:::${var.s3_bucket_name}/*"
          ]
      }
  ]
}
EOF
}


#--------------------------------------------------------------------------
#------------------------------ Code Deploy -------------------------------

#Creating IAM policy for S3 bucket 
resource "aws_iam_policy" "CodeDeploy-EC2-S3" {
  name        = "CodeDeploy-EC2-S3"
  description = "CodeDeploy S3 bucket policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "s3:List*",
              "s3:Get*"
          ],
          "Effect": "Allow",
          "Resource": [
              "arn:aws:s3:::${var.code_deploy_s3_bucket_name}/*"
          ]
      }
  ]
}
EOF
}


#Creating role for CodeDeploy-EC2-To-S3
resource "aws_iam_role" "CodeDeployEC2ServiceRole" {
  name = "CodeDeployEC2ServiceRole"

  assume_role_policy = "${file("ec2s3role.json")}"

  tags = {
    Name = "EC2-Code-Deploy-Iam role"
  }
}


resource "aws_iam_role_policy_attachment" "code_deploy_ec2_attach" {
  role       = "${aws_iam_role.CodeDeployEC2ServiceRole.name}"
  policy_arn = "${aws_iam_policy.CodeDeploy-EC2-S3.arn}"
}

#Attaching cloud watch policy to ec2 instance
resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerRole" {
  role       = "${aws_iam_role.CodeDeployEC2ServiceRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#Attaching cloud watch policy to ec2 instance
resource "aws_iam_role_policy_attachment" "CloudWatchAgentAdminServerRole" {
  role       = "${aws_iam_role.CodeDeployEC2ServiceRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}


resource "aws_iam_role_policy_attachment" "ec2_s3_webapp_attach" {
  role       = "${aws_iam_role.CodeDeployEC2ServiceRole.name}"
  policy_arn = "${aws_iam_policy.WebAppS3.arn}"
}

#Profile for attachment to EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = "${aws_iam_role.CodeDeployEC2ServiceRole.name}"
}


#----------------------------------- Creating policies for Circleci user ------------------------------------


resource "aws_iam_policy" "CircleCI-Upload-To-S3" {
  name        = "CircleCI-Upload-To-S3"
  description = "CircleCI upload to S3 bucket policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "s3:List*",
              "s3:Get*",
              "s3:Put*"
          ],
          "Effect": "Allow",
          "Resource": [
              "arn:aws:s3:::${var.code_deploy_s3_bucket_name}/*"
          ]
      }
  ]
}
EOF
}

resource "aws_iam_policy" "CircleCI-Code-Deploy" {
  name        = "CircleCI-Code-Deploy"
  description = "CircleCI code deploy to S3 bucket policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetApplicationRevision"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.region}:${var.aws_account_id}:application:${var.code_deploy_application_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.region}:${var.aws_account_id}:deploymentconfig:CodeDeployDefault.OneAtATime",
        "arn:aws:codedeploy:${var.region}:${var.aws_account_id}:deploymentconfig:CodeDeployDefault.HalfAtATime",
        "arn:aws:codedeploy:${var.region}:${var.aws_account_id}:deploymentconfig:CodeDeployDefault.AllAtOnce"
      ]
    }
  ]
}
EOF
}


resource "aws_iam_policy" "circleci-ec2-ami" {
  name        = "circleci-ec2-ami"
  description = "CircleCI user policy to attach to ec2 ami"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CopyImage",
        "ec2:CreateImage",
        "ec2:CreateKeypair",
        "ec2:CreateSecurityGroup",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteKeyPair",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteSnapshot",
        "ec2:DeleteVolume",
        "ec2:DeregisterImage",
        "ec2:DescribeImageAttribute",
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeRegions",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSnapshots",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume",
        "ec2:GetPasswordData",
        "ec2:ModifyImageAttribute",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifySnapshotAttribute",
        "ec2:RegisterImage",
        "ec2:RunInstances",
        "ec2:StopInstances",
        "ec2:TerminateInstances"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


#Upload to S3
resource "aws_iam_user_policy_attachment" "circleci_upload_s3_attach" {
  user       = "${var.circleci_user_name}"
  policy_arn = "${aws_iam_policy.CircleCI-Upload-To-S3.arn}"
}

#Circleci to code deploy
resource "aws_iam_user_policy_attachment" "circleci_code_deploy_attach" {
  user       = "${var.circleci_user_name}"
  policy_arn = "${aws_iam_policy.CircleCI-Code-Deploy.arn}"
}

#Circleci to 
resource "aws_iam_user_policy_attachment" "circleci_ec2_ami_attach" {
  user       = "${var.circleci_user_name}"
  policy_arn = "${aws_iam_policy.circleci-ec2-ami.arn}"
}


#--------------------------------------- Code Deploy Roles and Policies ---------------------------------
#Creating role for CodeDeploy-To-S3
resource "aws_iam_role" "CodeDeployServiceRole" {
  name = "CodeDeployServiceRole"

  assume_role_policy = "${file("codeDeployService.json")}"

  tags = {
    Name = "Code-Deploy-Iam role"
  }
}

resource "aws_iam_role_policy_attachment" "code_deploy_attach" {
  role       = "${aws_iam_role.CodeDeployServiceRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

#---------------------------------- Code Deploy Application -------------------------------------------
#Code Deployment App
resource "aws_codedeploy_app" "code_deploy_app" {
  compute_platform = "Server"
  name             = "${var.code_deploy_application_name}"
}

#Code Deployment Group
resource "aws_codedeploy_deployment_group" "code_deploy_webapp_group" {
  app_name               = "${aws_codedeploy_app.code_deploy_app.name}"
  deployment_config_name = "${var.code_deploy_config_name}"
  deployment_group_name  = "${var.code_deploy_group_name}"
  service_role_arn       = "${aws_iam_role.CodeDeployServiceRole.arn}"
  autoscaling_groups     = ["${aws_autoscaling_group.ag_ec2_instance.name}"]

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  ec2_tag_set {
      ec2_tag_filter {
        key   = "Name"
        type  = "KEY_AND_VALUE"
        value = "${var.ec2_tag_value}"
      }
    }
}

#------------------------------------- Launch Configuration --------------------------------------
resource "aws_launch_configuration" "asg_launch_config" {
  name   = "asg_launch_config"
  image_id      = "${data.aws_ami.ubuntu.id}" 
  instance_type = "t2.micro"
  key_name = var.ssh_key_name
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.ec2_profile.name}"
  security_groups  = ["${aws_security_group.application_sec_grp.id}"] 
  
  root_block_device {
    volume_type           =  var.root_block_device_volume_type
    volume_size           =  var.root_block_device_volume_size
    delete_on_termination = true
  }

  depends_on = [
    aws_db_instance.rds_instance
  ] 
  user_data = <<-EOF
          #!/bin/bash
          echo export "AWS_ACCESS_KEY_ID=${var.prod_access_key}" | sudo tee -a /etc/environment
          echo export "AWS_SECRET_ACCESS_KEY=${var.prod_secret_key}" | sudo tee -a /etc/environment
          echo export "AWS_REGION=${var.region}" | sudo tee -a /etc/environment
          echo export "db_name=${var.rds_instance_name}" | sudo tee -a /etc/environment
          echo export "db_hostname=${aws_db_instance.rds_instance.address}" | sudo tee -a /etc/environment
          echo export "db_username=${var.db_master_username}" | sudo tee -a /etc/environment
          echo export "db_password=${var.db_master_password}" | sudo tee -a /etc/environment
          echo export "s3_bucket_name=${var.s3_bucket_name}" | sudo tee -a /etc/environment
      EOF
}

#--------------------------------------- Security Group for Load Balancer --------------------------------

#Attaching Security Group to EC2 instance
resource "aws_security_group" "load_balancer_sec_grp" {
  name        = "load_balancer_sec_grp"
  description = "Setting inbound and outbound traffic for load balancer"
  vpc_id      = "${aws_vpc.selected.id}"

  ingress {
    description = "Http for VPC"
    from_port   = 80
    to_port     = 80
    protocol    = 6
    cidr_blocks = ["${var.cidr_block_sec_grp_http}"]
  } 

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr_block_sec_grp_outbound}"]
  }

  tags = {
    Name = "load_balancer_sec_grp"
  }
}


#--------------------------------------------- Load Balancer ----------------------------------------------

#Load Balancer for Webapp
resource "aws_lb" "webapp-load-balancer" {
  name               = "webapp-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.load_balancer_sec_grp.id}"]
  subnets            = ["${aws_subnet.primary-subnet.id}", "${aws_subnet.secondary-subnet.id}", "${aws_subnet.third-subnet.id}"]
  tags = {
    Name = "webapp-load-balancer"
  }
}

#Load Balancer Target Group for load balancer
resource "aws_lb_target_group" "target_group_lb_webapp" {
  name     = "target-group-lb-webapp"
  vpc_id   = "${aws_vpc.selected.id}"
  port     = 3000
  protocol = "HTTP"

  health_check {
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
    path = "/"
    port = 80
  }
}

#Load Balancer Listener
resource "aws_lb_listener" "lb_listener_2" {
  load_balancer_arn = "${aws_lb.webapp-load-balancer.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group_lb_webapp.arn}"
  }
}

#Route53 
data "aws_route53_zone" "mydomain_r53" {
  zone_id = var.r53_zone_id
  vpc_id = "${aws_vpc.selected.id}"
}

resource "aws_route53_record" "dns_record" {
  zone_id = "${data.aws_route53_zone.mydomain_r53.zone_id}"
  name    = "${var.domain_name}"
  type    = "A"

  alias {
    name                   = "${aws_lb.webapp-load-balancer.dns_name}"
    zone_id                = "${aws_lb.webapp-load-balancer.zone_id}"
    evaluate_target_health = true
  }
}

#--------------------------------------- Auto-Scaling Group ---------------------------------
resource "aws_autoscaling_group" "ag_ec2_instance" {
  name                      = "ag_ec2_instance"
  max_size                  = 5
  min_size                  = 2
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.asg_launch_config.name}"
  vpc_zone_identifier       = ["${aws_subnet.primary-subnet.id}", "${aws_subnet.secondary-subnet.id}", "${aws_subnet.third-subnet.id}"]
  target_group_arns         = ["${aws_lb_target_group.target_group_lb_webapp.arn}"]

  default_cooldown          = 60

  tag {
    key                 = "Name"
    value               = "csye6225_ec2"
    propagate_at_launch = true
  }
}

#------------------------------ Auto Scaling Policies and Cloud Watch Alarm ----------------------------------

# Auto-Scaling Policy for Scale Up
resource "aws_autoscaling_policy" "ag-scaleup-cpu-policy" {
    name = "ag-scaleup-cpu-policy"
    autoscaling_group_name = "${aws_autoscaling_group.ag_ec2_instance.name}"
    adjustment_type = "ChangeInCapacity"
    scaling_adjustment = "1"
    cooldown = "60"
    policy_type = "SimpleScaling"
}

#Cloud Watch alarm for Scale Up
resource "aws_cloudwatch_metric_alarm" "cloudWatch-scaleup-cpu-alarm" {
    alarm_name = "cloudWatch-scaleup-cpu-alarm"
    alarm_description = "Scale up when CPU usage > 5%"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "60"
    statistic = "Average"
    threshold = "5"
    dimensions = {
      "AutoScalingGroupName" = "${aws_autoscaling_group.ag_ec2_instance.name}"
    }
    actions_enabled = true
    alarm_actions = ["${aws_autoscaling_policy.ag-scaleup-cpu-policy.arn}"]
}

# Auto-Scaling Policy for Scale Down
resource "aws_autoscaling_policy" "ag-scaledown-cpu-policy" {
    name = "ag-scaledown-cpu-policy"
    autoscaling_group_name = "${aws_autoscaling_group.ag_ec2_instance.name}"
    adjustment_type = "ChangeInCapacity"
    scaling_adjustment = "-1"
    cooldown = "60"
    policy_type = "SimpleScaling"
}

#Cloud Watch alarm for Scale Down
resource "aws_cloudwatch_metric_alarm" "cloudWatch-scaledown-cpu-alarm" {
    alarm_name = "cloudWatch-scaledown-cpu-alarm"
    alarm_description = "Scale up when CPU usage < 3%"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "60"
    statistic = "Average"
    threshold = "3"
    dimensions = {
      "AutoScalingGroupName" = "${aws_autoscaling_group.ag_ec2_instance.name}"
    }
    actions_enabled = true
    alarm_actions = ["${aws_autoscaling_policy.ag-scaledown-cpu-policy.arn}"]
}

#-------------------------------------------- SNS ---------------------------------------------
resource "aws_sns_topic" "password_reset" {
	name = "password_reset"
}
#------------------------------------------- Lambda -------------------------------------------
resource "aws_iam_role" "role_for_sns_lambda" {
  name = "role_for_sns_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy"  "lambda_log_policy" {
  name = "lambda_log_policy"
  description = "Policy for Updating Lambda logs to CloudWatch"
  policy = <<EOF
{
    "Version":"2012-10-17",
    "Statement":[
      {
        "Action":[
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect":"Allow",
        "Resource":"arn:aws:logs:::*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo" {
	role = "${aws_iam_role.role_for_sns_lambda.name}"
	policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_route53" {
	role = "${aws_iam_role.role_for_sns_lambda.name}"
	policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_SNS" {
	role = "${aws_iam_role.role_for_sns_lambda.name}"
	policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_SES" {
	role = "${aws_iam_role.role_for_sns_lambda.name}"
	policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatchlogs" {
	role = "${aws_iam_role.role_for_sns_lambda.name}"
	policy_arn = "${aws_iam_policy.lambda_log_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "lambda_basicExecutionRole" {
  role = "${aws_iam_role.role_for_sns_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_DynamoDBExecutionRole" {
  role = "${aws_iam_role.role_for_sns_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"
}

resource "aws_sns_topic_subscription" "password_reset_sns" {
	topic_arn = "${aws_sns_topic.password_reset.arn}"
	protocol = "lambda"
	endpoint = "${aws_lambda_function.send_email.arn}"
}

resource "aws_lambda_permission" "lambda_invoke_permission" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.send_email.function_name}"
  principal = "sns.amazonaws.com"
  source_arn = "${aws_sns_topic.password_reset.arn}"
}

#-------------------------------------------- LAMBDA function ------------------------------------------
resource "aws_lambda_function" "send_email" {
  filename = "resetpassword.zip"
  function_name = "${var.lambda_function_name}"
  role = "${aws_iam_role.role_for_sns_lambda.arn}"
  handler = "resetpassword.handler"
  runtime = "nodejs12.x"
  memory_size = 512
  timeout = 25

  environment {
    variables = {
      aws_region = "${var.region}"
    }
  }
}

#--------------------------------- EC2 instance role -------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ec2_SNS" {
	role = "${aws_iam_role.CodeDeployEC2ServiceRole.name}"
	policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}


#----------------------------- CircleCi user policy attachment ---------------------------------
#Creating IAM policy for Lambda Access
resource "aws_iam_policy" "LambdaAccess" {
  name        = "LambdaAccess"
  description = "Lambda access policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:CreateFunction",
                "lambda:UpdateFunctionEventInvokeConfig",
                "lambda:TagResource",
                "lambda:UpdateEventSourceMapping",
                "lambda:InvokeFunction",
                "lambda:PublishLayerVersion",
                "lambda:DeleteProvisionedConcurrencyConfig",
                "lambda:UpdateFunctionConfiguration",
                "lambda:InvokeAsync",
                "lambda:CreateEventSourceMapping",
                "lambda:UntagResource",
                "lambda:PutFunctionConcurrency",
                "lambda:UpdateAlias",
                "lambda:UpdateFunctionCode",
                "lambda:DeleteLayerVersion",
                "lambda:PutProvisionedConcurrencyConfig",
                "lambda:DeleteAlias",
                "lambda:PutFunctionEventInvokeConfig",
                "lambda:DeleteFunctionEventInvokeConfig",
                "lambda:DeleteFunction",
                "lambda:PublishVersion",
                "lambda:DeleteFunctionConcurrency",
                "lambda:DeleteEventSourceMapping",
                "lambda:CreateAlias"
            ],
            "Resource": "arn:aws:lambda:${var.region}:918568617781:function:${var.lambda_function_name}"
        }
    ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "lambda_update_access" {
  user       = "${var.circleci_user_name}"
  policy_arn = "${aws_iam_policy.LambdaAccess.arn}"
}
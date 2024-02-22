# Create a vpc 
resource "aws_vpc" "terra_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "my_vpc"
  }
}
# Create an internet gateway
resource "aws_internet_gateway" "terra_IGW" {
  vpc_id = aws_vpc.terra_vpc.id
  tags = {
    name = "my_IGW"
  }
}
# Create a custom route table
resource "aws_route_table" "terra_route_table" {
  vpc_id = aws_vpc.terra_vpc.id
  tags = {
    name = "my_route_table"
  }
}
# create route
resource "aws_route" "terra_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id  = aws_internet_gateway.terra_IGW.id
  route_table_id = aws_route_table.terra_route_table.id
}
# create a subnet
resource "aws_subnet" "terra_subnet" {
  vpc_id = aws_vpc.terra_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.availability_zone
  
  tags = {
    name = "my_subnet"
  }
}

resource "aws_subnet" "private-subnet-1" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = var.availability_zone2
  tags = {
    Name = "private-subnet-1"
  }
}

# associate internet gateway to the route table by using subnet
resource "aws_route_table_association" "terra_assoc" {
  subnet_id = aws_subnet.terra_subnet.id
  route_table_id = aws_route_table.terra_route_table.id
}
# create security group to allow ingoing ports
resource "aws_security_group" "terra_SG" {
  name        = "sec_group"
  description = "security group for the EC2 instance"
  vpc_id      = aws_vpc.terra_vpc.id
  ingress = [
    {
      description      = "https traffic"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0", aws_vpc.terra_vpc.cidr_block]
      ipv6_cidr_blocks  = []
      prefix_list_ids   = []
      security_groups   = []
      self              = false
    },
    {
      description      = "http traffic"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0", aws_vpc.terra_vpc.cidr_block]
      ipv6_cidr_blocks  = []
      prefix_list_ids   = []
      security_groups   = []
      self              = false
    },
    {
      description      = "ssh"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0", aws_vpc.terra_vpc.cidr_block]
      ipv6_cidr_blocks  = []
      prefix_list_ids   = []
      security_groups   = []
      self              = false
    }
  ]
  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "Outbound traffic rule"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  tags = {
    name = "allow_web"
  }
}

# create a network interface with private ip from step 4
resource "aws_network_interface" "terra_net_interface" {
  subnet_id = aws_subnet.terra_subnet.id
  security_groups = [aws_security_group.terra_SG.id]
}
# assign a elastic ip to the network interface created in step 7
resource "aws_eip" "terra_eip" {
  domain = vpc
  network_interface = aws_network_interface.terra_net_interface.id
  associate_with_private_ip = aws_network_interface.terra_net_interface.private_ip
  depends_on = [aws_internet_gateway.terra_IGW, aws_instance.terra_ec2]
}
# create an ubuntu server and install/enable apache2
resource "aws_instance" "terra_ec2" {
  ami = var.ami
  instance_type = var.instance_type
  availability_zone = var.availability_zone
  key_name = "ec2_key"
  
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.terra_net_interface.id
  }
  
  user_data = file("${path.module}/user_data.sh")
  
  tags = {
    name = "web_server"
  }
}

resource "aws_lb" "web" {
  name               = "terra-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terra_SG.id]
  subnets            = [for subnet in aws_subnet.terra_subnet : subnet.id]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "web-lb"
    enabled = true
  }

  tags = {
    Environment = "test"
  }
}

resource "aws_launch_template" "template" {
  name_prefix     = "test"
  image_id        = var.ami
  instance_type   = var.instance_type

  network_interfaces {
  security_groups = [aws_security_group.terra_SG]
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 40
      encrypted             = true
      delete_on_termination = true
    }
  }
}

resource "aws_autoscaling_group" "autoscale" {
  name                  = "web-autoscaling-group"  
  availability_zones    = [var.availability_zone]
  desired_capacity      = 3
  max_size              = 6
  min_size              = 3
  health_check_type     = "EC2"
  termination_policies  = ["OldestInstance"]
  vpc_zone_identifier   = [aws_subnet.terra_subnet]

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }
}

# resource "tls_self_signed_cert" "self_signed" {
#   #   key_algorithm   = tls_private_key.web_app_key.algorithm
#   private_key_pem = tls_private_key.web_app_key.private_key_pem
#   subject {
#     common_name = "test.example.com"
#   }
#   validity_period_hours = 8760

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#   ]
#   dns_names = ["test.example.com"]
# }

# resource "aws_lb_listener_certificate" "web_app_cert" {
#   listener_arn    = aws_lb_listener.https_rule.arn
#   **certificate_arn = tls_self_signed_cert.self_signed.?**
# }
data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  owners = ["137112412989"] # Amazon
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2b", "eu-west-2c", "eu-west-2d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  subnet_id = module.blog_vpc.public_subnets[0]

  user_data = <<-EOF
#!/bin/bash
dnf install -y java-17-amazon-corretto tomcat
systemctl enable tomcat
systemctl start tomcat
EOF

  vpc_security_group_ids = [module.blog_sg.id]

  tags = {
    Name = "HelloWorld"
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"
  name = "blog_new"

  vpc_id = module.blog_vpc.vpc_id

  # ingress_rules = ["http-80-tcp" , "https-443-tcp"]
  # ingress_cidr_blocks = ["0.0.0.0/0"]

  ingress_rules = {
    http = {
      from_port = "80"
      to_port = "80"
      ip_protocol = "tcp"
      cidr_ipv4 = "0.0.0.0/0"
      description = "http allow on port 80"
    }
    https = {
      from_port = "443"
      to_port = "443"
      ip_protocol = "tcp"
      cidr_ipv4 = "0.0.0.0/0"
      description = "allow inbound from htpps on port 443"
    }
  }

  egress_rules = {
    all =  {
      ip_protocol = "-1"
      cidr_ipv4 = "0.0.0.0/0"
    }
    
  }

  # egress_rules = ["all-all"]
  # egress_cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group" "blog" {
  name        = "blog"
  description = "Allow http and https in. Allow everything out"

  vpc_id =  module.blog_vpc.vpc_id
}

resource "aws_security_group_rule" "blog_http_in" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group_rule" "blog_https_in" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group_rule" "blog_everything_out" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}

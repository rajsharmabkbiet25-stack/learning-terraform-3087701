data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  owners = [var.ami_filter.owner] 
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc"
  cidr = "${var.environment.network_prefix}.0.0/16"

  azs             = ["us-west-2b", "us-west-2c", "us-west-2d"]
  private_subnets = ["${var.environment.network_prefix}.1.0/24", "${var.environment.network_prefix}.2.0/24", "${var.environment.network_prefix}.3.0/24"]
  public_subnets  = ["${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = var.environment.name
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

module "web_alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "web-alb"
  vpc_id  = module.blog_vpc.vpc_id
  subnets = module.blog_vpc.public_subnets

  # Security Group
  security_groups = [module.blog_sg.id]

  

  listeners = {
    blog-http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_arn = aws_lb_target_group.blog.arn
      }
    }
    
  }

  tags = {
    Environment = "dev"
  }
}

resource "aws_lb_target_group" "blog" {
  name     = "blog"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.blog_vpc.vpc_id
}

module "blog_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.2.1"

  name = "blog"

  min_size = var.min_size
  max_size = var.max_size

  vpc_zone_identifier = module.blog_vpc.public_subnets
  launch_template_name = "blog"
  // vpc_security_group_ids = [module.blog_sg.id]
  security_groups = [module.blog_sg.id]

  image_id           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  traffic_source_attachments = {
    alb = {
      traffic_source_identifier = aws_lb_target_group.blog.arn
      traffic_source_type = "elbv2"
    }
  }
}


variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.micro"
}


variable "ami_filter" {
  description = "Name and owner for ami"
  type = object ({
    name = string
    owner = string
  })

  default ={
    name = "al2023-ami-*-x86_64"
    owner = "137112412989" # Amazon
  }
  
}

variable "environment" {
  description = "deployment environment"
  type = object ({
    name = string
    network_prefix = string
  })

  default = {
    name = "dev"
    network_prefix = "10.0"
  }
}

variable min_size {
  description = "min_size"
  default = 1
}

variable max_size {
  description = "max_size"
  default = 2
}


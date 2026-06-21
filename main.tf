data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  owners = ["137112412989"] # Amazon
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.app_ami.id
  instance_type = "t3.micro"

  user_data = <<-EOF
#!/bin/bash
dnf install -y java-17-amazon-corretto tomcat
systemctl enable tomcat
systemctl start tomcat
EOF

  tags = {
    Name = "HelloWorld"
  }
}

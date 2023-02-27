variable "awsprops" {
  type = map(string)
  //Maps are a collection of string keys and string values.
  default = {
    region       = "us-east-1"
    ami          = "ami-06878d265978313ca"
    itype        = "t2.micro"
    publicip     = true
    secgroupname = "BBOT-Class"
    keyname      = "bbotTraining"
  } 
}

#Declare the public key variable
#The Ansible "Intialize and Execute Terraform" block specifies the variable
#file where it can find the value for "public_key" 
variable "public_key" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = lookup(var.awsprops, "region")
}

#Assign the keyname
#Assign the contents of public key from the "public_key" variable
#Push a local RSA public key up to the AWS tenant
resource "aws_key_pair" "bbotTraining" {
    key_name = "bbotTraining"
    public_key = var.public_key
}

resource "aws_security_group" "bbot-training-sg" {
  name        = lookup(var.awsprops, "secgroupname")
  description = lookup(var.awsprops, "secgroupname")

  // To Allow SSH Transport
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 7474 Transport
  ingress {
    from_port   = 7474
    protocol    = "tcp"
    to_port     = 7474
    cidr_blocks = ["0.0.0.0/0"]
  }
  
    // To Allow Port 7687 Transport
  ingress {
    from_port   = 7687
    protocol    = "tcp"
    to_port     = 7687
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_instance" "bbot-class-student-pc" {
  ami                         = lookup(var.awsprops, "ami")
  instance_type               = lookup(var.awsprops, "itype")
  associate_public_ip_address = lookup(var.awsprops, "publicip")
  key_name                    = lookup(var.awsprops, "keyname")
  vpc_security_group_ids      = [aws_security_group.bbot-training-sg.id]

  root_block_device {
    delete_on_termination = true
    //iops                  = 150
    volume_size           = 50
    volume_type           = "gp2"
  }
  user_data = <<EOF
            #!/bin/bash
            dd if=/dev/zero of=/swapfile bs=1M count=2048
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
            EOF
            
  tags = {
    Name        = "BBOT"
    Environment = "TRAINING"
    OS          = "UBUNTU"
    Managed     = "IAC"
  }

  depends_on = [aws_security_group.bbot-training-sg]
}


output "ec2instance" {
  value = aws_instance.bbot-class-student-pc.public_ip
}

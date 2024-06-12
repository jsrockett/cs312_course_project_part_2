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
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
}

resource "aws_security_group" "minecraft_security" {
  ingress {
    description = "Minecraft port"
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Send Anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Minecraft Security Group"
  }
}

resource "aws_instance" "minecraft_instance" {
  ami                         = "ami-0bfac9aa66a558bd8"
  instance_type               = "t4g.small"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.minecraft_security.id]
  key_name                    = "my-key-pair"

  tags = {
    Name = "minecraft_instance"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("my-key-pair.pem")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "minecraft_server_install.sh"
    destination = "/tmp/minecraft_server_install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/minecraft_server_install.sh",
      "/tmp/minecraft_server_install.sh"
    ]
  }
}

resource "aws_eip" "minecraft_eip" {
  instance = aws_instance.minecraft_instance.id
}

output "ec2_eip" {
  value = ["${aws_eip.minecraft_eip.*.public_ip}"]
}

output "ec2_id" {
  value = ["${aws_instance.minecraft_instance.*.id}"]
}

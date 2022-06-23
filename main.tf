provider "aws" {
  profile = "webapp"
}

// added local module to this root module
module "vpc" {
  source = "./modules/vpc"

}

// create security group for EC2 
resource "aws_security_group" "allow_tls" {
  name        = "webapp_EC2_SG"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc

  dynamic "ingress" {
    for_each = var.ec2_ingress
    content {
      from_port   = ingress.value["port"]
      to_port     = ingress.value["port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ingress.value["cidr_blocks"]
      description = ingress.value["description"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "webapp_EC2_SG"
    Created_By  = module.vpc.common_tags["Created_By"]
    Environment = module.vpc.common_tags["Environment"]
  }
  lifecycle {
    create_before_destroy = true
  }
}

// create security group for RDS 
resource "aws_security_group" "allow_tls_rds" {
  name        = "webapp_RDS_SG"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "webapp_RDS_SG"
    Created_By  = module.vpc.common_tags["Created_By"]
    Environment = module.vpc.common_tags["Environment"]
  }
  lifecycle {
    create_before_destroy = true
  }
}
// fetch latest ami available for ubuntu 20.04
data "aws_ami" "webapp_server_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}
// create EC2 instance
resource "aws_instance" "webapp_server" {
  ami                         = data.aws_ami.webapp_server_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_sub.id
  security_groups             = [aws_security_group.allow_tls.id]
  key_name                    = aws_key_pair.webapp.key_name
  associate_public_ip_address = true
  tags = {
    Name        = "webapp_server"
    Created_By  = module.vpc.common_tags["Created_By"]
    Environment = module.vpc.common_tags["Environment"]
  }
  //depends_on = [aws_db_instance.webapp_rds] 

}

// allocate an EIP 
resource "aws_eip" "webapp_eip" {
  vpc = true
  tags = {
    Name        = "webapp_eip"
    Created_By  = module.vpc.common_tags["Created_By"]
    Environment = module.vpc.common_tags["Environment"]
  }
}
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.webapp_server.id
  allocation_id = aws_eip.webapp_eip.id
  depends_on    = [aws_instance.webapp_server]

}

// generate a RSA private key
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// save the RSA private key locally
resource "local_file" "rsa_key_file" {
  content  = tls_private_key.rsa_key.private_key_pem
  filename = "webapp.pem"
  provisioner "local-exec" {
    command = "chmod 400 webapp.pem"
  }
}

// register the private key with aws by generating a key-pair 
resource "aws_key_pair" "webapp" {
  key_name   = "webapp"
  public_key = tls_private_key.rsa_key.public_key_openssh
}

// create RDS instance 
resource "aws_db_instance" "webapp_rds" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_password
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  db_subnet_group_name   = module.vpc.db_subnetgrp
  vpc_security_group_ids = [aws_security_group.allow_tls_rds.id]
  depends_on             = [aws_instance.webapp_server]

  tags = {
    Name        = "webapp_RDS"
    Created_By  = module.vpc.common_tags["Created_By"]
    Environment = module.vpc.common_tags["Environment"]
  }

}

resource "null_resource" "null" {

  provisioner "local-exec" {
    command = "sed -i 's#ansible_host=.*#ansible_host=${aws_eip.webapp_eip.public_ip}#g' ansible/inventory.txt && ansible-playbook -i ansible/inventory.txt ansible/webapp_playbook.yml --private-key=${local_file.rsa_key_file.filename} -e 'domain=${var.domain}' -e 'dbhost=${aws_db_instance.webapp_rds.address}' -e 'dbname=${var.db_name}' -e 'dbuser=${var.db_user}' -e 'dbpass=${var.db_password}'"
  }
}

output "webapp_server" {
  value = "IP for webapp server: ${aws_eip.webapp_eip.public_ip} \n Point this IP against ${var.domain} on domain-control panel"

}
provider "aws" {
  region = "eu-west-3"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "crapi-gw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a"
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.crapi-gw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg" {
  name        = "crapi-sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8025
    to_port     = 8025
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_interface" "eni" {
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.sg.id]
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh_key"
  public_key = file("~/.ssh/id_rsa_crapi.pub")
}

data "cloudinit_config" "server_config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = templatefile("../resources/cloud-init.txt", {})
  }
}


resource "aws_instance" "vm" {
  ami           = "ami-006f2a24e73d7a5d8" # Ubuntu Server 22.04 LTS
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ssh_key.key_name

  subnet_id                   = aws_subnet.subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]

  user_data = data.cloudinit_config.server_config.rendered

  root_block_device {
    volume_size = 8
  }

  tags = {
    Name = "crapi-vm"
  }

  depends_on = [aws_network_interface.eni] 
}

resource "aws_eip" "eip" {
  instance = aws_instance.vm.id
}

output "public_ip" {
  value = aws_instance.vm.public_ip
}

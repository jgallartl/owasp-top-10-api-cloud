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

resource "aws_network_interface" "eni" {
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.sg.id]
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh_key"
  public_key = file("~/.ssh/id_rsa_crapi.pub")
}

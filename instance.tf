resource "aws_instance" "webapp_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  security_groups             = var.security_group_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet[0].id

  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }

  disable_api_termination = false

  tags = {
    Name = "AppInstance"
  }
}



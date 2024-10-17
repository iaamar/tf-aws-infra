resource "aws_instance" "webapp_instance" {
  ami           = "a04"
  instance_type = "t2.micro" # You can choose any instance type as per your needs
  #   key_name               = "<your_key_nam e>" # Optional, if you want SSH access
  security_groups             = [aws_security_group.app_security_group.name]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet[*].id

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

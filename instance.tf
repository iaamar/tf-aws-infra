# resource "aws_instance" "webapp_instance" {
#   ami                    = var.ami_id
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.public_subnet[0].id
#   vpc_security_group_ids = [var.security_group_id]

#   root_block_device {
#     volume_size           = 25
#     volume_type           = "gp2"
#     delete_on_termination = true
#   }

#   disable_api_termination = false

#   tags = {
#     Name = "WebAppInstance"
#   }
#   associate_public_ip_address = true
# }



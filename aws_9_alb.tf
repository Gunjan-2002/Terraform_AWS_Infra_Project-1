resource "aws_lb" "myalb" {
  name               = "myalb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysg.id]
  subnets            = [aws_subnet.sub-1.id, aws_subnet.sub-2.id]

  enable_deletion_protection = true


  tags = {
    Name = "myalb-tf"
  }
}
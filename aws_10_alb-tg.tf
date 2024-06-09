resource "aws_lb_target_group" "myalb-tg" {
  name     = "myalb-tf-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "myalb-tga-1" {
  target_group_arn = aws_lb_target_group.myalb-tg.arn
  target_id        = aws_instance.myfirstec2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "myalb-tga-2" {
  target_group_arn = aws_lb_target_group.myalb-tg.arn
  target_id        = aws_instance.mysecondec2.id
  port             = 80
}
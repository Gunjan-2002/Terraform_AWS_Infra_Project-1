resource "aws_lb_listener" "myalb-listner" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myalb-tg.arn
  }
}

output "loadBalancerEndpoint" {
  value = aws_lb.myalb.dns_name
}
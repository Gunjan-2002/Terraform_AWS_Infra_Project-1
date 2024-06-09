resource "aws_route_table_association" "myrta_1" {
  subnet_id      = aws_subnet.sub-1.id
  route_table_id = aws_route_table.myrt.id
}

resource "aws_route_table_association" "myrta_2" {
  subnet_id      = aws_subnet.sub-2.id
  route_table_id = aws_route_table.myrt.id
}
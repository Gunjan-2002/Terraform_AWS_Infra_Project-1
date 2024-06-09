resource "aws_route_table" "myrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"                 #Destination
    gateway_id = aws_internet_gateway.igw.id #Target
  }

  tags = {
    Name = "myrt"
  }
}
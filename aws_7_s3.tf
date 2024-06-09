resource "aws_s3_bucket" "mys3" {
  bucket = "my-tf-s3-bucket-terraform-project"

  tags = {
    Name = "my-tf-s3-bucket-terraform-project"
  }
}
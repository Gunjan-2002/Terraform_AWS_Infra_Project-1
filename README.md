Project Overview:
In this project, we will set up the infrastructure shown in the image above on AWS using Terraform. This includes a VPC, 2 public subnets, an internet gateway, a Security Group, 2 EC2 instances in different availability zones, an application load balancer, an S3 bucket, and more.

First, we will create a VPC with a CIDR of 10.0.0.0/16. Inside it, we will create 2 public subnets with CIDRs of 10.0.1.0/24 and 10.0.2.0/24. Next, we will create an internet gateway so that resources in our VPC can access the internet. Then, we will set up route tables to define routes that help subnets manage traffic according to rules. After that, we will create a security group with inbound and outbound rules. We will then launch 2 EC2 instances with the same security group in 2 different availability zones, i.e., 2 different subnets. Next, we will create an S3 bucket. After creating all these resources, we will set up an application load balancer to distribute traffic to these 2 EC2 instances.

This is the project overview. Now, we will go through the step-by-step process to create the infrastructure using Terraform.



Prerequisites:
Install AWS CLI and Terraform on your machine.

Create an IAM user with administrative access, or grant access to specific services by editing policies.

Configure the AWS account in your CLI by providing the access key and secret key.

Follow these steps:
Create a provider block to interact with the various resources supported by AWS. You must configure the provider with the correct credentials before you can use it.

provider.tf


COPY
 terraform {
   required_providers {
     aws = {
       source = "hashicorp/aws"
       version = "5.53.0"
     }
   }
 }

 provider "aws" {
   region = "us-east-1"
 }
You can refer this document for Provider Resource

Terraform Provider Resource

Now, create the VPC resource.

aws_1_vpc.tf


COPY
 resource "aws_vpc" "myvpc" {
   cidr_block = var.cidr_block
 }
You can refer this document for VPC Resource

Terraform AWS VPC Resource

Now, create a variables.tf file for defining variables and a variables.tfvars file to declare them. These two files will contain all the variables needed for our project, and I will add content to them in further steps as required.

variables.tf


COPY
 variable "cidr_block" {
   type = string
 }
variables.tfvars


COPY
 cidr_block = "0.0.0.0/16"
After creating the VPC, we will now create 2 public subnets in 2 different availability zones within that VPC.

aws_2_subnet.tf


COPY
 resource "aws_subnet" "sub-1" {
   vpc_id     = aws_vpc.myvpc.id
   cidr_block = "10.0.1.0/24"
   availability_zone = "us-east-1a"
   map_public_ip_on_launch = true

   tags = {
     Name = "sub-1"
   }
 }

 resource "aws_subnet" "sub-2" {
   vpc_id     = aws_vpc.myvpc.id
   cidr_block = "10.0.2.0/24"
   availability_zone = "us-east-1b"
   map_public_ip_on_launch = true

   tags = {
     Name = "sub-2"
   }
 }
You can refer this documentation for Subnet.

Terraform AWS Subnet Resource

As we know, when we create a Virtual Private Network, resources inside any subnet do not have internet access by default. So now, we will create an Internet Gateway.

aws_3_igw.tf


COPY
 resource "aws_internet_gateway" "igw" {
   vpc_id = aws_vpc.myvpc.id

   tags = {
     Name = "myigw"
   }
 }
You can refer this documentation for Internet Gateway.

Terraform AWS Internet Gateway Resource

Even after creating the Internet gateway, resources in subnets still don't have internet access. This is because subnets don't know how to route traffic. So, we need to create a route table to tell the subnets where to route the traffic. In the route table, we define routes and then associate the table with the subnets.

aws_4_rt.tf


COPY
 resource "aws_route_table" "myrt" {
   vpc_id = aws_vpc.myvpc.id

   route {
     cidr_block = "0.0.0.0/0"  #Destination
     gateway_id = aws_internet_gateway.igw.id  #Target
   }

   tags = {
     Name = "myrt"
   }
 }
You can refer this documentation for Route Table.

Terraform AWS Route Table Resource

Now we will create a resource to link a route table with a subnet. In this project, we are associating the same route table with both subnets, but in real life, we can create multiple route tables and associate them with different subnets.

aws_5_rta.tf


COPY
 resource "aws_route_table_association" "myrta_1" {
   subnet_id      = aws_subnet.sub-1.id
   route_table_id = aws_route_table.myrt.id
 }

 resource "aws_route_table_association" "myrta_2" {
   subnet_id      = aws_subnet.sub-2.id
   route_table_id = aws_route_table.myrt.id
 }
You can refer this documentation for Route Table Association.

Terraform AWS Route Table Association Resource

Now we will create a Security Group inside the VPC we created.

aws_6_sg.tf


COPY
 resource "aws_security_group" "mysg" {
   name_prefix = "web-sg-"
   description = "Security group in myvpc"
   vpc_id = aws_vpc.myvpc.id

   ingress {
     description = "HTTP from VPC"
     from_port        = 80
     to_port          = 80
     protocol = "tcp"
     cidr_blocks      = ["0.0.0.0/0"]
   }

   ingress {
     description = "SSH from VPC"
     from_port        = 22
     to_port          = 22
     protocol = "tcp"
     cidr_blocks      = ["0.0.0.0/0"]
   }

   egress {
     from_port        = 0
     to_port          = 0
     protocol         = "-1"
     cidr_blocks      = ["0.0.0.0/0"]
   }

   tags = {
     Name = "web-sg"
   }
 }
You can refer this documentation for Security Group.

Terraform AWS Security Group Resource

Create an S3 bucket for demonstration purposes.

aws_7_s3.tf


COPY
 resource "aws_s3_bucket" "mys3" {
   bucket = "my-tf-s3-bucket-terraform-project"

   tags = {
     Name = "my-tf-s3-bucket-terraform-project"
   }
 }
You can refer this documentation for S3 Bucket.

Terraform AWS S3 Resource

Now we will create 2 EC2 instances in the two different subnets we created earlier in the VPC. We are fetching the AMI ID from the data block so that we don't need to hard code the AMI ID in the aws_instance resource.

aws_8_ec2.tf


COPY
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "myfirstec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id              = aws_subnet.sub-1.id
  user_data              = base64encode(file("aws_user-data_1.sh"))

  tags = {
    Name = "myfirstec2"
  }
}

resource "aws_instance" "mysecondec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id              = aws_subnet.sub-2.id
  user_data              = base64encode(file("aws_user-data_2.sh"))

  tags = {
    Name = "mysecondec2"
  }
}
You can refer this documentation for EC2 Instance.

Terraform AWS EC2 Resource

Next, we will create the Load Balancer itself. We will use an Application Load Balancer (ALB) in this example, which operates at the application layer (Layer 7) and provides advanced routing capabilities.

aws_9_alb.tf


COPY
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
You can refer this documentation for Application Load Balancer.

Terraform AWS Application Load Balancer Resource

After creating the Load Balancer, we need to define a target group. The target group specifies the instances that will receive traffic from the Load Balancer.

aws_10_alb-tg.tf


COPY
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
You can refer this documentation for ALB Target Group & Target Group Attachment.

Terraform AWS Target Group Resource

Finally, we will create a listener to forward incoming requests to the target group. The listener listens for incoming connections on the Load Balancer and forwards them to the target group based on the specified rules.

aws_11_alb-lisn.tf


COPY
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
You can refer this documentation for creating ALB Listener Rules.

Terraform AWS ALB Listener Resource

With these resources defined, we have successfully set up a Load Balancer that distributes traffic across our EC2 instances, improving the overall availability and reliability of our application.

Now run the commands below to verify if the resources we created are valid.


COPY
terraform fmt  # This command will format the code with proper indentation

COPY
terraform validate
Run this command to initialize the providers, so that Terraform can access AWS resources.


COPY
terraform init
Before running the terraform apply command, we need to check what will be created.


COPY
terraform plan
Now, finally, run this command to create the infrastructure on AWS.


COPY
terraform apply --auto-approve
Conclusion
By following the steps in this project, we have successfully set up a robust and scalable infrastructure on AWS using Terraform. This setup includes a VPC with two public subnets, an internet gateway, route tables, a security group, two EC2 instances in different availability zones, an S3 bucket, and an Application Load Balancer to distribute traffic across the EC2 instances. Using Terraform ensures consistent and repeatable infrastructure deployment, which improves the reliability and manageability of your applications.

References and Further Reading
Terraform Registry: The Terraform Registry hosts a wide variety of community-maintained modules that you can use to simplify your Terraform configurations.

AWS Documentation: AWS's official documentation provides detailed information about all AWS services, including EC2, VPC, S3, and Load Balancers. It's an essential resource for understanding how to effectively use AWS services.

By exploring these references, you'll gain a deeper understanding of how to effectively use Terraform and AWS, enabling you to build scalable, secure, and cost-efficient cloud infrastructure.

Thank You
Thank you for reading this article on setting up AWS infrastructure using Terraform. I hope you found it informative and helpful. If you have any questions, feedback, or suggestions, please leave a comment below. Your input is invaluable and helps me improve the content I create.

If you enjoyed this article, consider sharing it with your network and following me for more insights and tutorials on cloud computing, DevOps, and other tech topics. Together, we can continue to learn and grow in our understanding of these powerful tools and technologies.

Happy Terraforming!

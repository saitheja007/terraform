provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "demo-server" {
  
  ami = "ami-0440d3b780d96b29d"
  key_name = "sai-key"
  instance_type =  "t2.micro"
  subnet_id = aws_subnet.demo-subnet.id
  vpc_security_group_ids = [ aws_security_group.demo-vpc-sg.id ]
  associate_public_ip_address = true  # Enables public IP for the instance

  tags = {
    Name = "Demo-server"
  }
  user_data = <<-EOF
              #!/bin/bash
              # Install Ansible
              sudo yum update
              sudo yum install -y ansible
              EOF

  
}

// creating a VPC

resource "aws_vpc" "demo-vpc" {
       cidr_block = "10.30.0.0/16"
       tags = {
        Name = "demo-vpc"
     }
   }

// creating a subnet

resource "aws_subnet" "demo-subnet" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = "10.30.1.0/24"

  tags = {
    Name = "demo-subnet"
  }
}

//creating the Internet Gateway

resource "aws_internet_gateway" "demo-IGW" {
  vpc_id = aws_vpc.demo-vpc.id

  tags = {
    Name = "demo-IGW"
  }
}

// Create a route table 

resource "aws_route_table" "demo-public-rt" {
    vpc_id = aws_vpc.demo-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.demo-IGW.id
    }
    tags = {
      Name = "demo-public-rt"
    }
}

// Associate subnet with route table

resource "aws_route_table_association" "demo-rt-association" {
    subnet_id = aws_subnet.demo-subnet.id
    route_table_id = aws_route_table.demo-public-rt.id
}

// creating the Security Group

resource "aws_security_group" "demo-vpc-sg" {
  name        = "demo-vpc-sg"
  vpc_id = aws_vpc.demo-vpc.id
  description = "Example security group allowing SSH inbound and outbound to public"

  // Inbound rule for SSH access from the public
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Outbound rule allowing all traffic to the public
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"   // -1 indicates all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Additional rules can be added as needed
}


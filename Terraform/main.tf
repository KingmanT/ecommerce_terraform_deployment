provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "custom_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "custom_vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id
  tags = {
    Name = "igw"
  }
}

# Public Subnet in us-east-1a
resource "aws_subnet" "public_subnet_1a" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet_1a"
  }
}

# Public Subnet in us-east-1b
resource "aws_subnet" "public_subnet_1b" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet_1b"
  }
}

# Private Subnet in us-east-1a
resource "aws_subnet" "private_subnet_1a" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private_subnet_1a"
  }
}

# Private Subnet in us-east-1b
resource "aws_subnet" "private_subnet_1b" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private_subnet_1b"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc_1a" {
  subnet_id      = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_1b" {
  subnet_id      = aws_subnet.public_subnet_1b.id
  route_table_id = aws_route_table.public_rt.id
}

# NAT Gateway for Private Subnets
resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1a.id
  tags = {
    Name = "nat_gateway"
  }
}

# Route Table for Private Subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.custom_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "private_rt"
  }
}

resource "aws_route_table_association" "private_rt_assoc_1a" {
  subnet_id      = aws_subnet.private_subnet_1a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_assoc_1b" {
  subnet_id      = aws_subnet.private_subnet_1b.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group for Public EC2 Instances
resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.custom_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "public_sg"
  }
}

# Security Group for Private EC2 Instances
resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.custom_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "private_sg"
  }
}

# Public EC2 Instances
resource "aws_instance" "public_ec2_1a" {
  ami           = "ami-0c55b159cbfafe1f0" # Replace with your preferred AMI
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet_1a.id
  security_groups = [aws_security_group.public_sg.name]
  tags = {
    Name = "public_ec2_1a"
  }
}

resource "aws_instance" "public_ec2_1b" {
  ami           = "ami-0c55b159cbfafe1f0" # Replace with your preferred AMI
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet_1b.id
  security_groups = [aws_security_group.public_sg.name]
  tags = {
    Name = "public_ec2_1b"
  }
}

# Private EC2 Instances
resource "aws_instance" "private_ec2_1a" {
  ami           = "ami-0c55b159cbfafe1f0" # Replace with your preferred AMI
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_subnet_1a.id
  security_groups = [aws_security_group.private_sg.name]
  tags = {
    Name = "private_ec2_1a"
  }
}

resource "aws_instance" "private_ec2_1b" {
  ami           = "ami-0c55b159cbfafe1f0" # Replace with your preferred AMI
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_subnet_1b.id
  security_groups = [aws_security_group.private_sg.name]
  tags = {
    Name = "private_ec2_1b"
  }
}

# Load Balancer
resource "aws_lb" "public_lb" {
  name               = "public-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_sg.id]
  subnets            = [aws_subnet.public_subnet_1a.id, aws_subnet.public_subnet_1b.id]
  tags = {
    Name = "public_lb"
  }
}

resource "aws_lb_target_group" "public_tg" {
  name     = "public-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom_vpc.id
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    matcher             = "200"
    path                = "/"
  }
}

resource "aws_lb_target_group_attachment" "public_ec2_1a_tg_attachment" {
  target_group_arn = aws_lb_target_group.public_tg.arn
  target_id        = aws_instance.public_ec2_1a.id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "public_ec2_1b_tg_attachment" {
  target_group_arn = aws_lb_target_group.public_tg.arn
  target_id        = aws_instance.public_ec2_1b.id
  port             = 3000
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.public_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg.arn
  }
}

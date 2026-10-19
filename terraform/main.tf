resource "aws_vpc" "task_03_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "task_03_vpc"

  }
}

resource "aws_subnet" "task_03_subnet" {
  vpc_id                  = aws_vpc.task_03_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "task_03_subnet"
  }
}

resource "aws_s3_bucket" "task_03_bucket" {
  bucket = "task-03-sai-app-files-20261019"

  tags = {
    Name        = "Task_03_bucket"
    Environment = "Development"
    Project     = "Task_03"
  }
}

resource "aws_internet_gateway" "task_03_igw" {
  vpc_id = aws_vpc.task_03_vpc.id

  tags = {
    Name = "task_03_igw"
  }
}

resource "aws_route_table" "task_03_route_table" {
  vpc_id = aws_vpc.task_03_vpc.id

  tags = {
    Name = "task_03_route_table"
  }
}

resource "aws_route" "task_03_route" {
  route_table_id         = aws_route_table.task_03_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.task_03_igw.id
}

resource "aws_route_table_association" "task_03_route_table_association" {
  subnet_id      = aws_subnet.task_03_subnet.id
  route_table_id = aws_route_table.task_03_route_table.id
}

resource "aws_security_group" "task_03_sg" {
  name        = "task_03_sg"
  description = "Security group for task 03"
  vpc_id      = aws_vpc.task_03_vpc.id


  ingress {
    description = "SSH from my current IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["106.215.171.249/32"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "task_03_sg"
  }
}

resource "aws_iam_role" "task_03_ec2role" {
  name        = "ec2-s3-role"
  description = "Allows EC2 to assume a role for S3 access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "task_03_ec2_role"
  }
}

resource "aws_iam_role_policy" "task_03_s3_policy" {
  name = "task-03-s3-access"
  role = aws_iam_role.task_03_ec2role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = aws_s3_bucket.task_03_bucket.arn
      },
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = "${aws_s3_bucket.task_03_bucket.arn}/*"
      }
    ]
  })
}
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "task_03_ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.task_03_subnet.id
  key_name                    = "task-03-key"
  vpc_security_group_ids      = [aws_security_group.task_03_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.task_03_instance_profile.name
  associate_public_ip_address = true

  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "task_03_ec2"
  }
}

resource "aws_iam_instance_profile" "task_03_instance_profile" {
  name = "task-03-ec2-instance-profile"
  role = aws_iam_role.task_03_ec2role.name
}
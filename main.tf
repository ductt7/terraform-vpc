# main.tf
provider "aws" {
  region = "ap-southeast-1"  # Replace with your desired region
}

# Create VPC
resource "aws_vpc" "ductt_vpc" {
  cidr_block = "10.11.0.0/16"
}

locals {
  private = ["10.11.3.0/24", "10.11.4.0/24"]
  public  = ["10.11.1.0/24", "10.11.2.0/24"]
  zone    = ["ap-southeast-1a", "ap-southeast-1b"]
}

# Create Internet Gateway
resource "aws_internet_gateway" "ductt_igw" {
  vpc_id = aws_vpc.ductt_vpc.id
}

# Create Route Table for Public Subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.ductt_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ductt_igw.id
  }
}

# Create Route Table for Private Subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.ductt_vpc.id
}

# Create Subnets
resource "aws_subnet" "public_subnet" {
  count = length(local.public)

  vpc_id            = aws_vpc.ductt_vpc.id
  cidr_block        = local.public[count.index]
  availability_zone = local.zone[count.index % length(local.zone)]

  tags = {
    "Name" = "public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  count = length(local.private)

  vpc_id            = aws_vpc.ductt_vpc.id
  cidr_block        = local.private[count.index]
  availability_zone = local.zone[count.index % length(local.zone)]

  tags = {
    "Name" = "private-subnet"
  }
}

# Create NAT Gateway in each public subnet
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.ductt_igw]
}

# Create Elastic IP for each NAT Gateway
resource "aws_eip" "nat_eip" {
}

# Create Route for Private Subnets to route traffic through NAT Gateway
resource "aws_route" "private_subnet_route" {
  route_table_id = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateway.id
}

# Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public_route_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Associate Private Route Table with Private Subnets
resource "aws_route_table_association" "private_route_association" {
  count          = 2
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}


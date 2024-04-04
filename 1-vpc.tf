#######################################################################################################################
# Virtual Private Cloud (VPC)
#######################################################################################################################
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name}_main"
  }
}

#######################################################################################################################
# Create a public Internet Gateway
#######################################################################################################################
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.name}_igw"
  }
}

#######################################################################################################################
# Public Subnets
#######################################################################################################################
resource "aws_subnet" "my_public_subnet_1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "${var.name}_public_${var.region}"

    # Required by EKS
    # Instructs EKS to create public LB
    "kubernetes.io/role/elb" = "1"

    # owned = subnet for EKS only, Shared = with other AWS resources and/or other EKS cluster
    "kubernetes.io/cluster/${var.cluster_name}" = "owned" 
  }
}

resource "aws_subnet" "my_public_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "${var.name}_public_${var.region}"

    # Required by EKS
    # Instructs EKS to create public LB
    "kubernetes.io/role/elb" = "1"

    # owned = subnet for EKS only, Shared = with other AWS resources and/or other EKS cluster
    "kubernetes.io/cluster/${var.cluster_name}"      = "owned"
  }
}

#######################################################################################################################
# Private Subnets
#######################################################################################################################
resource "aws_subnet" "my_private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.name}_private_${var.region}"

    # Required by EKS
    # Instructs EKS to create private Network LB
    "kubernetes.io/role/internal-elb" = "1"

    # owned = subnet for EKS only, Shared = with other AWS resources and/or other EKS cluster
    "kubernetes.io/cluster/${var.cluster_name}"      = "owned"
  }
}

resource "aws_subnet" "my_private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "${var.name}_private_${var.region}"

    # Required by EKS
    # Instructs EKS to create private Network LB
    "kubernetes.io/role/internal-elb" = "1"

    # owned = subnet for EKS only, Shared = with other AWS resources and/or other EKS cluster
    "kubernetes.io/cluster/${var.cluster_name}"      = "owned"
  }
}

#######################################################################################################################
# Create a fixed Elastic IP for NAT
#######################################################################################################################
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.name}_nat_eip"
  }
}

#######################################################################################################################
# Create NAT in the my_public_subnet_1
#######################################################################################################################
resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.my_public_subnet_1.id
  depends_on    = [aws_internet_gateway.my_igw]

  tags = {
    Name = "${var.name}_nat_gateway"
  }
}

#######################################################################################################################
# Create Public Route Table pointing to the IGW
#######################################################################################################################
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "${var.name}_public_route_table"
  }
}


resource "aws_route_table_association" "public_rta_1" {
  subnet_id      = aws_subnet.my_public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_rta_2" {
  subnet_id      = aws_subnet.my_public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

#######################################################################################################################
# Create Private Route Table pointing to the NAT
#######################################################################################################################
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat_gateway.id
  }

  tags = {
    Name = "${var.name}_private_route_table"
  }
}


resource "aws_route_table_association" "private_rta_1" {
  subnet_id      = aws_subnet.my_private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_rta_2" {
  subnet_id      = aws_subnet.my_private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}
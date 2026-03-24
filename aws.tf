################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

################################################################################
# Subnet
################################################################################

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.aws_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

################################################################################
# Route Table
################################################################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# VGWからのルート伝搬を有効化（Interconnect経由のGCP側ルートを自動反映）
resource "aws_vpn_gateway_route_propagation" "this" {
  vpn_gateway_id = aws_vpn_gateway.this.id
  route_table_id = aws_route_table.public.id
}

################################################################################
# VPN Gateway (VGW) - Direct Connect Gateway接続用
################################################################################

resource "aws_vpn_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-vgw"
  }
}

################################################################################
# Direct Connect Gateway
################################################################################

resource "aws_dx_gateway" "this" {
  name            = "${var.project_name}-dx-gw"
  amazon_side_asn = var.dx_gateway_asn
}

resource "aws_dx_gateway_association" "this" {
  dx_gateway_id         = aws_dx_gateway.this.id
  associated_gateway_id = aws_vpn_gateway.this.id
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for Interconnect multicloud test EC2"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# ICMP from GCP
resource "aws_vpc_security_group_ingress_rule" "icmp_gcp" {
  security_group_id = aws_security_group.ec2.id
  description       = "ICMP from GCP VPC"
  cidr_ipv4         = var.gcp_subnet_cidr
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
}

# HTTP from GCP
resource "aws_vpc_security_group_ingress_rule" "http_gcp" {
  security_group_id = aws_security_group.ec2.id
  description       = "HTTP from GCP VPC"
  cidr_ipv4         = var.gcp_subnet_cidr
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# Egress all（SSMエージェントの通信にも必要）
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

################################################################################
# IAM Role for SSM Session Manager
################################################################################

resource "aws_iam_role" "ec2_ssm" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${var.project_name}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}

################################################################################
# EC2
################################################################################

# Amazon Linux 2023の最新AMI（SSMエージェントがプリインストール済み）
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "this" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.public.id
  private_ip             = var.aws_ec2_private_ip
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name

  # 疎通確認用にnginxをインストール、レスポンスでEC2と識別できるようにする
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    echo "I'M EC2!!!" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOF

  tags = {
    Name = "${var.project_name}-ec2"
  }
}

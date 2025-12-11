# NAT Gateway 생성
resource "aws_eip" "myEIP" {
  domain = "vpc"
  tags = {
    Name = "myNATeip"
  }
}

resource "aws_nat_gateway" "myNAT-gw" {
  allocation_id = aws_eip.myEIP.id
  subnet_id     = aws_subnet.myPubSubnet.id

  tags = {
    Name = "myNAT-GW"
  }

  depends_on = [ aws_internet_gateway.myIGW ]
}

# Subnet 생성
resource "aws_subnet" "myPriSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Main"
  }
}

# 라우팅 테이블 생성
resource "aws_route_table" "myPriRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.myNAT-gw.id
  }
  tags = {
    Name = "myPriRT"
  }
}

resource "aws_route_table_association" "myPriRTassoc" {
  subnet_id      = aws_subnet.myPriSN.id
  route_table_id = aws_route_table.myPriRT.id
}

# 보안 그룹 생성
resource "aws_security_group" "mySG2" {
  name        = "mySG2"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "amySG2_22" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "amySG2_80" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "amySG2_433" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "mySG2_all" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# EC2 생성

resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/mykeypair.pub")
}

resource "aws_instance" "myEC2-2" {
  ami                         = "ami-00e428798e77d38d9"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.mySG2.id]
  subnet_id                   = aws_subnet.myPriSN.id
  key_name                    = "mykeypair"

  user_data_replace_on_change = true
  user_data                   = <<-EOF
        #!/bin/bash
        dnf install -y httpd mod_ssl
        echo "My Web Server 2 Test Page:" > /var/www/html/index.html
        systemctl enable --now httpd
        EOF

  tags = {
    Name = "myEC2-2"
  }
}
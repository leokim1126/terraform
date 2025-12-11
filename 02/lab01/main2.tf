## Security Group 생성
resource "aws_security_group" "mySG" {
  name        = "mySG"
  description = "Allow TLS inbound 80/tcp, 433/tcp traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mySG_80" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "mySG_22" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "mySG_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# EC2 생성

resource "aws_instance" "myEC2" {
  ami                         = "ami-00e428798e77d38d9"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.mySG.id]
  subnet_id                   = aws_subnet.myPubSubnet.id
  user_data_replace_on_change = true
  key_name                    = "mykeypair"
  
  user_data                   = <<-EOF
        #!/bin/bash
        dnf install -y httpd mod_ssl
        echo "My Web Server Test Page" > /var/www/html/index.html
        systemctl enable --now httpd
        EOF

  tags = {
    Name = "myEC2"
  }
}
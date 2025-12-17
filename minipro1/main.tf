/*
1. 인프라 구성
  1-1. VPC 생성
  1-2. IGW 생성 및 연결
  1-3. Public Subnet 생성
  1-4. Routing Table 생성 및 연결
2. EC2 생성
  2-1. Security Group 생성
  2-2. Keypair 생성
  2-3. EC2 생성
    - User_Data (docker CMD)
3. 사용자 연결
*/

# 1. 인프라 구성
# 1-1. VPC 생성
resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "myVPC"
  }
}

# 1-2. IGW 생성 및 연결
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myVPC"
  }
}

# 1-3. Public Subnet 생성
# 공인 IP 할당
resource "aws_subnet" "myPubSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "myPubSN"
  }
}

# 1-4. Routing Table 생성 및 연결
# default route -> myIGW 
# myPubSN에 연결
resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubRTs"
  }
}

resource "aws_route_table_association" "myPubRTassoc" {
  subnet_id      = aws_subnet.myPubSN.id
  route_table_id = aws_route_table.myPubRT.id
}

# 2-1. Security Group 생성
# ingress/egress -> all traffic
resource "aws_security_group" "mySG" {
  name        = "mySG"
  description = "Allow all inbound and outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mySG_in_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


resource "aws_vpc_security_group_egress_rule" "mySG_out_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# 2-2. Keypair 생성
# * ssh-keygen -t rsa -N "" -f ~/.ssh/mykeypair
resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/mykeypair.pub")
  }

# 2-3. EC2 생성
# 새로 생성한 public subnet에 EC2 생성
# security group (mySG) 지정
# key_name(mykeypair) 지정
# ami: ubuntu 24.04 LTS
#   - User_Data (docker CMD)

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "myEC2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id   = aws_subnet.myPubSN.id
  vpc_security_group_ids = [aws_security_group.mySG.id]
  key_name = aws_key_pair.mykeypair.key_name

  user_data_replace_on_change = true
  user_data_base64 = filebase64("user_data.sh")

  provisioner "local-exec" {
    command = templatefile("make_config.sh",{
      hostname = self.public_ip,
      user = "ubuntu",
      identityfile = "~/.ssh/mykeypair"
    } )
    interpreter = [ "bash", "-c" ]
  }
  tags = {
    Name = "myEC2"
  }
}
# 3. 사용자 연결
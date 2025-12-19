resource "aws_security_group" "sg" {
  name   = "ohio-ssh-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  # us-east-2 리전의 Amazon Linux 2023 AMI ID 예시입니다.
  # (실행 시점에 따라 ID가 변할 수 있으니 에러 시 최신 ID 확인 필요)
  ami           = "ami-0942ecd5d85baa812" 
  instance_type = "t2.micro"
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = { Name = "ohio-instance" }
}
# Provider 설정
provider "aws" {
    region = "us-east-2"
}

# VPC 생성
resource "aws_vpc" "main" {
    cidr_block = "190.160.0.0/16"
    instance_tenancy = "default"
    tags = {
        Name = "Main"
        Location = "Seoul"
    }
}

# Subnet 생성
resource "aws_subnet" "subnets" {
    # [중요] 변수 리스트의 길이만큼 반복하도록 count를 설정해야 합니다.
    count = length(var.vsubnet_cidr) 

    vpc_id     = aws_vpc.main.id
    cidr_block = element(var.vsubnet_cidr, count.index)

    tags = {
        # [팁] 이름이 겹치지 않도록 인덱스를 활용해 구분해주면 좋습니다.
        Name = "subnet-${count.index + 1}"
    }
}
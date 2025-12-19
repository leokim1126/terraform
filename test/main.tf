provider "aws" {
  region = "us-east-2" # 리전을 오하이오로 변경
}

# 1) 네트워크 모듈 호출
module "net" {
  source = "./modules/net"
}

# 2) EC2 모듈 호출 (네트워크 모듈의 출력값 전달)
module "ec2" {
  source    = "./modules/ec2"
  vpc_id    = module.net.vpc_id
  subnet_id = module.net.subnet_id
}
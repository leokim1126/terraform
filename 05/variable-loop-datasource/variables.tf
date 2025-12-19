variable "region" {
    default = "us-east-2"
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

variable "vsubnet_cidr" {
    type = list
    default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

/*variable "asz" {
  type = list
  default = ["us-east-2a","us-east-2b","us-east-2c"]
}
*/

data "aws_availability_zones" "azs" {
  
}
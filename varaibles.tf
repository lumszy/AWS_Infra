variable "region" {
  default = "ca-central-1"
  description = "AWS Region"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
  description = "VPC CIDR Block"
}

variable "public_subnet_a_cidr" {
  description = "Public Subnet A CIDR"
}

variable "public_subnet_b_cidr" {
  description = "Public Subnet B CIDR"
}

variable "public_subnet_c_cidr" {
  description = "Public Subnet C CIDR"
}

variable "private_subnet_a_cidr" {
  description = "Private Subnet A CIDR"
}

variable "private_subnet_b_cidr" {
  description = "Private Subnet B CIDR"
}

variable "private_subnet_c_cidr" {
  description = "Private Subnet C CIDR"
}

variable "remote_state_bucket" {
  description = "Bucket name for layer 1 data source"
  default = "testlab-uwa"
}

variable "remote_state_key" {
  description = "Key name for layer 1 remote state"
  default = "layer1/infrastructure.tfstate"
}

variable "ec2_instance_type" {
  description = "EC2 Instance Type to Launch"
  default = "t2.micro"
}

variable "key_pair_name" {
  default   = "pc"
  description = "Keypair to used in connecting to EC2 instances"
}

variable "max_instance_size" {
  description = "Maximum number of instances to launch"
  default = "10"
}

variable "min_instance_size" {
  description = "Minimum number of instances to launch"
  default = "3"
}

variable "tag_production" {
  default = "Production"
}

variable "tag_webapp" {
  default = "Webserver"
}

variable "tag_backend" {
  default = "Backend"
}

variable "amis" {
  type = "map"
  default = {
    "ca-central-1" = "ami-07a182edcd7d04084"
      }
}







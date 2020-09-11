output "vpc_id" {
  value = "${aws_vpc.testlab-vpc.id}"
  }

output "vpc_cidr_block" {
  value = "${aws_vpc.testlab-vpc.cidr_block}"
}

output "public-subnet-a_id" {
  value = "${aws_subnet.public-subnet-a.id}"
}


output "private-subnet-a_id" {
  value = "${aws_subnet.private-subnet-a.id}"
}



resource "aws_instance" "bastion-ec2-instance" {

  ami = "ami-07a182edcd7d04084"
  instance_type = "t2.micro"
  key_name = "${var.key_pair_name}"
  security_groups = [
    "${aws_security_group.ec2_public_SG.id}","${aws_security_group.ec2_private_SG.id}","${aws_security_group.elb_SG.id}", ]
  subnet_id = "${aws_subnet.public-subnet-a.id}"
  associate_public_ip_address = true

  tags = {
    name = "Bastion host"
  }
}

resource "aws_network_interface" "eni1" {
  subnet_id        = "${aws_subnet.public-subnet-a.id}"
  private_ips      = ["10.0.13.154"]
  security_groups = ["${aws_security_group.ec2_public_SG.id}"]

  attachment {
    device_index = 0
    instance = "${aws_instance.bastion-ec2-instance.id}"
  }
}

resource "aws_network_interface" "eni2" {
  subnet_id        = "${aws_subnet.private-subnet-a.id}"
  private_ips      = ["10.0.1.150"]
security_groups = ["${aws_security_group.ec2_private_SG.id}"]

attachment {
  device_index = 1
  instance = "${aws_instance.bastion-ec2-instance.id}"
}


}

resource "aws_eip" "ip-test-env" {
  instance = "${aws_instance.bastion-ec2-instance.id}"
  vpc      = true
}

resource "aws_key_pair" "eks" {
  key_name   = "eks"
  public_key = "${file("eks.pub")}"
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:env"
    values = ["${terraform.workspace}"]
  }

  filter {
    name   = "tag:Name"
    values = ["${terraform.workspace}-us-west-2"]
  }
}

data "aws_subnet_ids" "eks_subnets" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags {
    env  = "${terraform.workspace}"
    Name = "${terraform.workspace}-eks*"
  }
}

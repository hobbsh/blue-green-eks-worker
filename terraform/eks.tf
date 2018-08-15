
locals {
  worker_groups = "${list(
                  map(
                      "name", "k8s-worker-blue",
                      "ami_id", "ami-0f7c5f77",
                      "asg_desired_capacity", "4",
                      "asg_max_size", "4",
                      "asg_min_size", "4",
                      "instance_type","m4.large",
                      "key_name", "${aws_key_pair.eks.key_name}",
                      "root_volume_size", "48"
                      ),
                  map(
                      "name", "k8s-worker-green",
                      "ami_id", "ami-67a0841f",
                      "asg_desired_capacity", "0",
                      "asg_max_size", "0",
                      "asg_min_size", "0",
                      "instance_type","m4.large",
                      "key_name", "${aws_key_pair.eks.key_name}",
                      "root_volume_size", "48"
                      )
  )}"
  tags = "${map("Environment", "${terraform.workspace}")}"
}

module "eks" {
  source                = "terraform-aws-modules/eks/aws"
  cluster_name          = "${terraform.workspace}"
  subnets               = "${data.aws_subnet_ids.eks_subnets.ids}"
  vpc_id                = "${data.aws_vpc.vpc.id}"
  worker_groups         = "${local.worker_groups}"
  tags                  = "${local.tags}"
}

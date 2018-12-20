locals {
  target_group_arns = "${join(",", concat(
    module.some_lb.target_group_arns,
    module.another_lb.target_group_arns
  ))}"

  worker_groups = [
    {
      name = "k8s-worker-blue",
      ami_id = "ami-0434edf581f70b047",
      autoscaling_enabled = false,
      protect_from_scale_in = false,
      asg_desired_capacity = "0",
      asg_max_size = "0",
      asg_min_size = "0",
      target_group_arns = "${local.target_group_arns}",
      root_volume_size = "48"
      instance_type = "m4.large"
      key_name = "${aws_key_pair.eks.key_name}"
    },
    {
      name = "k8s-worker-green",
      ami_id = "ami-0f7c5f77",
      autoscaling_enabled = true,
      protect_from_scale_in = true,
      asg_desired_capacity = "5",
      asg_max_size = "7",
      asg_min_size = "3",
      target_group_arns = "${local.target_group_arns}",
      root_volume_size = "48"
      instance_type = "m4.large"
      key_name = "${aws_key_pair.eks.key_name}"
    }
  ]

  tags = {
    Environment = "${terraform.workspace}"
  }
}

module "eks" {
  source                = "terraform-aws-modules/eks/aws"
  cluster_name          = "${terraform.workspace}"
  subnets               = "${data.aws_subnet_ids.eks_subnets.ids}"
  vpc_id                = "${data.aws_vpc.vpc.id}"
  worker_groups         = "${local.worker_groups}"
  worker_group_count    = "2"
  tags                  = "${local.tags}"
}

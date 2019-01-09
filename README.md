# blue-green-eks-worker
Some documentation and code for managing blue/green EKS workers

# Requirements

* [Packer](https://www.packer.io/docs/install/index.html) (only if you want to build your own AMI)
* [Terraform](https://www.terraform.io/intro/getting-started/install.html)

# Assumptions

* You already have a VPC created (and NAT gateway if applicable)
* You already have [private] subnets for EKS created - see [data.tf](terraform/data.tf) as you may need to modify the filter for your subnets
* You have AWS credentials setup for the correct region and can Terraform on a basic level
* A public key for your instance keypair exists in the `terraform` folder as `eks.pub` (or change the path in [data.tf](terraform/data.tf))
* Your load balancers will attach the autoscaling groups created here
* `cluster-autoscaler` is running in your cluster to provide the autoscaling capabilities.
* You've made any additional changes to the Terrform files as required

## Build your AMI

* Build a CIS hardened EKS AMI (Ubuntu or AL2) [here](https://github.com/hobbsh/hardened-eks-ami)
* Build off of AWS's official EKS AMI (AL2) [here](https://github.com/awslabs/amazon-eks-ami)

## Run terraform to create your cluster and workers

Clone this repo and update any variables, worker parameters, etc. Then you need to go through the standard "new terraform steps"

* `cd terraform` 
* `terraform init`
* `terraform workspace new <YOUR WORKSPACE NAME>` - used as an environment name in the code (i.e. prod, staging, dev) 
* `terraform validate` - make sure any changes are valid
* `terraform plan`
* `terraform apply` - to create your cluster with `blue` workers scaled up.

If you don't want to use `us-west-2`, modify [provider.tf](terraform/provider).

## Blue/green worker updates

Now that you have a cluster and a fully scaled up worker group, time to scale in the `green` workers with a new AMI. Here's an outline of the process:

1. Set `desired_capacity`, `asg_max_size` and `asg_min_size` greater than 0 to scale up the `green` workers with updated AMI
2. Wait for them to join the cluster - takes about 30s to build them and another 30-60s or so for them to be ready.
3. Assuming your Load Balancers are already aware of the autoscaling groups created by the terraform-aws-eks module, make sure the new workers are attached to your LBs before proceeding, or you will be in for a rude awakening when you transition pods in the next step!
4. Drain the old nodes to transition pods slowly over to the new nodes with [drain_nodes.sh](scripts/drain_nodes.sh). If you are confident, you can drain the entire blue node group with this command: `kubectl drain -l eks_worker_group=blue --ignore-daemonsets=true --delete-local-data --force`
5. After verifying all the pods have been moved to the right nodes, scale the old worker autoscaling group to zero by setting the parameters in step 1 to 0 on the `blue` worker group. With the addition of `cluster-autoscaler`, the node group will not be scaled to zero based on how cluster-autoscaler works. So, you will need to set the minSize to 0 only and cluster-autoscaler will reap the cordoned nodes in 10 minutes or so since they will be detected as uneeded.

## TODO

* Simplify the draining/transition process to a single step. Will need CA to support this, as requested [here](https://github.com/kubernetes/autoscaler/issues/1555).
* Write a wrapper around all the terraform, verification, waiting, etc.

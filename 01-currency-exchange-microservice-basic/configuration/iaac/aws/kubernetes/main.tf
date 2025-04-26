# aws --version
# aws eks --region us-east-1 update-kubeconfig --name yaswanth-cluster
# Uses default VPC and Subnet. Create Your Own VPC and Private Subnets for Prod Usage.
# aws-k8s-backendstate-s3
# AKIAYM7POMS3HCNNWFHL


terraform {
  backend "s3" {
    bucket = "mybucket" # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "us-east-1"
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.yaswanth-cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.yaswanth-cluster.cluster_id
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  version                = "~> 2.12"
}

resource "aws_default_vpc" "default" {

}

data "aws_subnets" "subnets" {
  vpc_id = aws_default_vpc.default.id
}

module "yaswanth-cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "yaswanthe-cluster"
  cluster_version = "1.14"
  #subnets = data.aws_subnets.subnets.ids
  subnets         = ["subnet-0412af6e234b9af0d", "subnet-0cf07bbc259849977"] #CHANGE

  vpc_id          = aws_default_vpc.default.id
  #vpc_id         = "vpc-1234556abcdef"

  node_groups = [
    {
      instance_type = "t2.micro"
      max_capacity  = 5
      desired_capacity = 3
      min_capacity  = 355
    }
  ]
}



# We will use ServiceAccount to connect to K8S Cluster in CI/CD mode
# ServiceAccount needs permissions to create deployments 
# and services in default namespace
resource "kubernetes_cluster_role_binding" "example" {
  metadata {
    name = "fabric8-rbac"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }
}

# Needed to set the default region
provider "aws" {
  region  = "us-east-1"
}
provider "aws" {
  region = var.aws_region
#  profile = var.aws_profile

  default_tags {
    tags = {
      Owner = "JMS"
    }
  }
}


data "aws_eks_cluster" "app_cluster" {
  name = module.wandb_infra.cluster_name
}
data "aws_eks_cluster_auth" "app_cluster" {
  name = module.wandb_infra.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.app_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.app_cluster.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.app_cluster.name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.app_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.app_cluster.token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.app_cluster.name]
      command     = "aws"
    }
  }
}

locals{
  other_envs = {
    "GORILLA_DATA_RETENTION_PERIOD" = "1h"
    "GORILLA_ARTIFACT_GC_ENABLED" = true
  }
  env_vars = merge(
    local.other_envs,
    var.other_wandb_env,
  )
}

module "wandb_infra" {
  source  = "wandb/wandb/aws"
  version = "7.9.2"
  
  license = var.wandb_license

  namespace            = var.namespace
  public_access        = true
  external_dns         = true
#  enable_dummy_dns     = true
#  enable_operator_alb  = true
  custom_domain_filter = var.domain_name
  
  deletion_protection = false

  allowed_inbound_cidr      = var.allowed_inbound_cidr
  allowed_inbound_ipv6_cidr = var.allowed_inbound_ipv6_cidr

  eks_cluster_version            = "1.29"
  kubernetes_public_access       = true
  kubernetes_public_access_cidrs = ["0.0.0.0/0"]

  domain_name = var.domain_name
  zone_id     = var.zone_id
  subdomain   = var.subdomain
  size = var.size

  use_internal_queue = true

  other_wandb_env = local.env_vars
}

output "url" {
  value = module.wandb_infra.url
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-1"
}

provider "aws" {
  region = var.aws_region
}

module "vpc_nginx" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "eks-vpc-nginx"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-1a", "ap-southeast-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "vpc_traefik" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "eks-vpc-traefik"
  cidr = "10.1.0.0/16"

  azs             = ["ap-southeast-1a", "ap-southeast-1b"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks_nginx" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name    = "eks-nginx"
  cluster_version = "1.29"

  vpc_id     = module.vpc_nginx.vpc_id
  subnet_ids = module.vpc_nginx.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    eks_node_group = {
      instance_types = ["m7i-flex.large"]
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      labels = {
        "role" = "worker"
      }
    },
    ingress_node_group = {
      instance_types = ["t3.small"]
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      labels = {
        "role" = "ingress"
      }
      taints = [
        {
          key    = "role"
          value  = "ingress"
          effect = "NO_SCHEDULE"
        }
      ]
    },
  }
}

module "eks_traefik" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name    = "eks-traefik"
  cluster_version = "1.29"

  vpc_id     = module.vpc_traefik.vpc_id
  subnet_ids = module.vpc_traefik.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    eks_node_group = {
      instance_types = ["m7i-flex.large"]
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      labels = {
        "role" = "worker"
      }
    },
    ingress_node_group = {
      instance_types = ["t3.small"]
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      labels = {
        "role" = "ingress"
      }
      taints = [
        {
          key    = "role"
          value  = "ingress"
          effect = "NO_SCHEDULE"
        }
      ]
    },
  }
}

resource "aws_security_group" "k6_nginx_sg" {
  name        = "k6-nginx-sg"
  description = "Allow SSH inbound traffic for k6 NGINX instance"
  vpc_id      = module.vpc_nginx.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k6-nginx-sg"
  }
}

resource "aws_security_group" "k6_traefik_sg" {
  name        = "k6-traefik-sg"
  description = "Allow SSH inbound traffic for k6 Traefik instance"
  vpc_id      = module.vpc_traefik.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k6-traefik-sg"
  }
}

resource "aws_instance" "k6_nginx" {
  ami                         = "ami-0933f1385008d33c4"
  instance_type               = "m7i-flex.large"
  subnet_id                   = module.vpc_nginx.public_subnets[0]
  key_name                    = "your-key"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.k6_nginx_sg.id]

  tags = {
    Name = "k6-nginx"
  }
}

resource "aws_instance" "k6_traefik" {
  ami                         = "ami-0933f1385008d33c4"
  instance_type               = "m7i-flex.large"
  subnet_id                   = module.vpc_traefik.public_subnets[0]
  key_name                    = "your-key"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.k6_traefik_sg.id]

  tags = {
    Name = "k6-traefik"
  }
}

output "eks_nginx_endpoint" {
  value = module.eks_nginx.cluster_endpoint
}

output "eks_nginx_name" {
  value = module.eks_nginx.cluster_name
}

output "eks_traefik_endpoint" {
  value = module.eks_traefik.cluster_endpoint
}

output "eks_traefik_name" {
  value = module.eks_traefik.cluster_name
}

output "k6_nginx_public_ip" {
  value = aws_instance.k6_nginx.public_ip
}

output "k6_traefik_public_ip" {
  value = aws_instance.k6_traefik.public_ip
}

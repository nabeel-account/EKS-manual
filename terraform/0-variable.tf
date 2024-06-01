variable "name" {
  description = "Project name"
  default = "main"
  type = string
}

variable "region" {
  description = "AWS region"
  default = "us-east-1"
  type = string
}

variable "cluster_name" {
  description = "Cluster name"
  default = "main"
  type = string
}
variable "repository_url" {
  description = "The url of the ECR repository"
}

variable "ecs_cluster_name" {
  description = "The cluster that we will deploy"
}

variable "ecs_service_name" {
  description = "The ECS service that will be deployed"
}

variable "github_owner" {}
variable "github_repo" {}

variable "tags" {
  type        = "map"
  default     = {}
}
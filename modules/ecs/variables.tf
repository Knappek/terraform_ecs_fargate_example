variable "service_name" {
  description = "Name of the application"
}

variable "cluster_name" {
  description = "Name of the Fargate cluster"
}

variable "vpc_id" {
  description = "The VPC id"
}

variable "availability_zones" {
  type        = "list"
  description = "The azs to use"
}

variable "security_groups_ids" {
  type        = "list"
  description = "The SGs to use"
}

variable "subnets_ids" {
  type        = "list"
  description = "The private subnets to use"
}

variable "public_subnet_ids" {
  type        = "list"
  description = "The private subnets to use"
}

variable "repository_name" {
  description = "The name of the repisitory"
}

variable "tags" {
  type        = "map"
  default     = {}
}
data "aws_availability_zones" "current" {}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  name                 = "fargate-codepipeline-test-vpc"
  cidr                 = "10.0.0.0/16"

  azs                  = ["${data.aws_availability_zones.current.names}"]
  private_subnets      = ["10.0.10.0/24", "10.0.20.0/24"]
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = {
    app = "CodePipeline example with Fargate"
    Owner = "andreas.knapp"
  }
}
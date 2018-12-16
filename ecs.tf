module "ecs" {
  source              = "./modules/ecs"
  service_name        = "codepipeline-fargate-test"
  cluster_name        = "codepipeline-fargate-test"
  vpc_id              = "${module.vpc.vpc_id}"
  availability_zones  = "${data.aws_availability_zones.current.names}"
  repository_name     = "${local.owner}/spring_boot_example"
  subnets_ids         = ["${module.vpc.private_subnets}"]
  public_subnet_ids   = ["${module.vpc.public_subnets}"]
  security_groups_ids = [
    "${module.vpc.default_security_group_id}"
  ]
  tags = {
    app = "CodePipeline example with Fargate"
    Owner = "${local.owner}"
  }
}

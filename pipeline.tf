module "code_pipeline" {
  source                      = "./modules/code_pipeline"
  repository_url              = "${module.ecs.repository_url}"
  ecs_service_name            = "${module.ecs.service_name}"
  ecs_cluster_name            = "${module.ecs.cluster_name}"
  github_owner                = "${var.github_owner}"
  github_repo                 = "${var.github_repo}"
  tags = {
    app = "CodePipeline example with Fargate"
    Owner = "${local.owner}"
  }
}

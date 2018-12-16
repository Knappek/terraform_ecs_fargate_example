# terraform_ecs_fargate_example

This repo
* creates a service on AWS Fargate
* creates an AWS CodePipeline using CodeBuild
* The pipeline gets triggered from changes from a Github Repo
* the pipelines builds a Docker image based on a multi-stage Dockerfile and pushes it to an ECR
* and then deploys it on ECS Fargate

## Usage

1. Define `github_owner` and `github_repo` in `terraform.tfvars` which contains your application and the multi-stage Dockerfile.
2. Create a Github token as describe [here](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)
3. export the Github token: `export GITHUB_TOKEN=<token>` 
4. run `terraform apply -var-file terraform.tfvars`
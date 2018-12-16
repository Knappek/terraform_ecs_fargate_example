/*====
Cloudwatch Log Group
======*/
resource "aws_cloudwatch_log_group" "logs" {
  name = "${var.service_name}-logs"

  tags = "${var.tags}"
}

/*====
ECR repository to store our Docker images
======*/
resource "aws_ecr_repository" "docker" {
  name = "${var.repository_name}"
}

/*====
ECS cluster
======*/
resource "aws_ecs_cluster" "cluster" {
  name = "${var.cluster_name}"
  tags = "${var.tags}"
}

/*====
ECS task definitions
======*/
data "aws_region" "current" {}

data "template_file" "task_definition" {
  template = "${file("${path.module}/tasks/task_definition.json")}"

  vars {
    image           = "${aws_ecr_repository.docker.repository_url}"
    container_name  = "${var.service_name}"
    region          = "${data.aws_region.current.name}"
    log_group       = "${aws_cloudwatch_log_group.logs.name}"
  }
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${var.service_name}"
  container_definitions    = "${data.template_file.task_definition.rendered}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "${aws_iam_role.ecs_execution_role.arn}"
  task_role_arn            = "${aws_iam_role.ecs_execution_role.arn}"
}

/*====
App Load Balancer
======*/
resource "aws_alb_target_group" "alb_target_group" {
  name     = "alb-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }
  tags = "${var.tags}"
}

/* security group for ALB */
resource "aws_security_group" "alb" {
  name        = "${var.service_name}-inbound-sg"
  description = "Allow HTTP from Anywhere into ALB"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.tags}"
}

resource "aws_alb" "alb" {
  name            = "${var.service_name}-alb"
  subnets         = ["${var.public_subnet_ids}"]
  security_groups = ["${var.security_groups_ids}", "${aws_security_group.alb.id}"]

  tags = "${var.tags}"
}

resource "aws_alb_listener" "listener" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"
  depends_on        = ["aws_alb_target_group.alb_target_group"]

  default_action {
    target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
    type             = "forward"
  }
}

/*
* IAM service role
*/
data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  name               = "ecs_role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_service_role.json}"
}

data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    effect = "Allow"
    resources = ["*"]
    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress"
    ]
  }
}

/* ecs service scheduler role */
resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy"
  #policy = "${file("${path.module}/policies/ecs-service-role.json")}"
  policy = "${data.aws_iam_policy_document.ecs_service_policy.json}"
  role   = "${aws_iam_role.ecs_role.id}"
}

/* role that the Amazon ECS container agent and the Docker daemon can assume */
resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = "${file("${path.module}/policies/ecs-task-execution-role.json")}"
}
resource "aws_iam_role_policy" "ecs_execution_role_policy" {
  name   = "ecs_execution_role_policy"
  policy = "${file("${path.module}/policies/ecs-execution-role-policy.json")}"
  role   = "${aws_iam_role.ecs_execution_role.id}"
}

/*====
ECS service
======*/

/* Security Group for ECS */
resource "aws_security_group" "ecs_service" {
  vpc_id      = "${var.vpc_id}"
  name        = "${var.service_name}-ecs-service-sg"
  description = "Allow egress from container"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.tags}"
}

resource "aws_ecs_service" "service" {
  name            = "${var.service_name}"
  task_definition = "${aws_ecs_task_definition.task.family}:${aws_ecs_task_definition.task.revision}"
  desired_count   = 1
  launch_type     = "FARGATE"
  cluster =       "${aws_ecs_cluster.cluster.id}"

  network_configuration {
    security_groups = ["${var.security_groups_ids}", "${aws_security_group.ecs_service.id}"]
    subnets         = ["${var.subnets_ids}"]
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
    container_name   = "${var.service_name}"
    container_port   = "8080"
  }

  depends_on = ["aws_alb_target_group.alb_target_group"]
}
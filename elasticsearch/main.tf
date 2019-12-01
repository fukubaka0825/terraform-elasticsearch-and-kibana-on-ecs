/* configure */
terraform {
  required_version = "0.12.6"
  backend "s3" {
    region = "ap-northeast-1"
    bucket = "search-playground"
    key    = "elasticsearch-kibana/terraform.tfstate"
  }
}

provider "aws" {
  version = "2.23.0"
  region  = "ap-northeast-1"
}

/* ecs */
/* ecs cluster*/
#module:https://github.com/infrablocks/terraform-aws-ecs-cluster
module "hoge_test_es_ecs_cluster" {
  source = "../modules/ecs/ecs_cluster_on_ec2"

  region                = "ap-northeast-1"
  vpc_id                = var.vpc_id
  subnet_ids            = var.subnet_id
  component             = "cluster-hoge"
  deployment_identifier = "test"

  cluster_name = "es"
  //ssh keyの登録が必須なfxxkなmoduleを引いてしまった(実在するkey指定するとCIでplanするときめんどくさいのでdummyを当てる)
  cluster_instance_ssh_public_key_path = "./dummy.pub"
  cluster_instance_types               = ["m4.4xlarge"]

  include_default_ingress_rule = "no"
  include_default_egress_rule  = "no"

  cluster_minimum_size                 = 1
  cluster_maximum_size                 = 1
  cluster_desired_capacity             = 1
  associate_public_ip_addresses = "yes"
  security_groups                      = [module.es_ecs_container_instance_sg.security_group_id]
  cluster_instance_iam_policy_contents = data.aws_iam_policy_document.ec2_for_ssm.json
  cloud_init_template                  = file("./userData.sh")
}

data "aws_iam_policy_document" "ec2_for_ssm" {
  source_json = data.aws_iam_policy.ec2_for_ssm.policy

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "autoscaling:Describe*",
      "sns:*",
      "cloudwatch:*",
      "ecr:*",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "kms:Decrypt",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:Submit*",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloesUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "s3:GetObject",
      "ec2:DescribeTags",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]
  }
  //cloudwatch agentの設定をssmから引っ張ってくるのに必要
  statement {
    effect    = "Allow"
    resources = ["arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"]

    actions = [
      "ssm:GetParameter"
    ]
  }

}

data "aws_iam_policy" "ec2_for_ssm" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

/* ecs_container_instance sg */
module "es_ecs_container_instance_sg" {
  source = "../modules/sg"
  name   = "hoge_test_es_ecs_instance_sg"
  vpc_id = var.vpc_id
  ingress_config = [
    {
      from_port                = 9200
      to_port                  = 9200
      protocol                 = "tcp"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id  = null
    },
    {
      from_port                = 5601
      to_port                  = 5601
      protocol                 = "tcp"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id  = null
    },
  ]
}

/* ecs service*/
module "hoge_es_service" {
  source          = "../modules/ecs/ecs_service_on_ec2"
  service_name    = "hoge-test-es-ecs-service"
  cluster_name    = module.hoge_test_es_ecs_cluster.cluster_name
  cluster_arn     = module.hoge_test_es_ecs_cluster.cluster_arn
  role_arn        = module.hoge_ecs_service_role.iam_role_arn
  task_definition = module.hoge_es_task_definition.task_definition_arn

  desired_count     = 1

  deploy_type                    = "ECS"
  has_ordered_placement_strategy = true
}

/* autoScaling role */
module "hoge_ecs_task_autoscale_role" {
  source     = "../modules/iam_role"
  role_name  = "hoge-es-ecs-task-autoscale"
  identifier = "ecs.application-autoscaling.amazonaws.com"
  policies = [
    {
      name   = "hoge-es-ecs-task-autoscale"
      policy = data.aws_iam_policy_document.ecs_task_autoscale.json
    }
  ]
}

data "aws_iam_policy_document" "ecs_task_autoscale" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm"
    ]

    resources = ["*"]
  }
}


/* ecs service role */
module "hoge_ecs_service_role" {
  source     = "../modules/iam_role"
  role_name  = "hoge-kibana-ecs-service-role"
  identifier = "ecs.amazonaws.com"
  policies = [
    {
      name   = "hoge-es-ecs-service-role"
      policy = data.aws_iam_policy_document.hoge_ecs_service_policy.json
    }
  ]
}

/* ecs service*/
module "hoge_kibana_service" {
  source          = "../modules/ecs/ecs_service_on_ec2"
  service_name    = "hoge-test-kibana-ecs-service"
  cluster_name    = module.hoge_test_es_ecs_cluster.cluster_name
  cluster_arn     = module.hoge_test_es_ecs_cluster.cluster_arn
  role_arn        = module.hoge_kibana_service_role.iam_role_arn
  task_definition = module.hoge_kibana_task_definition.task_definition_arn

  desired_count     = 1

  deploy_type                    = "ECS"
  has_ordered_placement_strategy = true
}

//ecs service role
module "hoge_kibana_service_role" {
  source     = "../modules/iam_role"
  role_name  = "hoge-es-kibana-service-role"
  identifier = "ecs.amazonaws.com"
  policies = [
    {
      name   = "hoge-kibana-ecs-service-role"
      policy = data.aws_iam_policy_document.hoge_ecs_service_policy.json
    }
  ]
}

data "aws_iam_policy_document" "hoge_ecs_service_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface",
      "ec2:DeleteNetworkInterfacePermission",
      "ec2:Describe*",
      "ec2:DetachNetworkInterface",
      "elasticloesbalancing:DeregisterInstancesFromLoesBalancer",
      "elasticloesbalancing:DeregisterTargets",
      "elasticloesbalancing:Describe*",
      "elasticloesbalancing:RegisterInstancesWithLoesBalancer",
      "elasticloesbalancing:RegisterTargets",
      "route53:ChangeResourceRecordSets",
      "route53:CreateHealthCheck",
      "route53:DeleteHealthCheck",
      "route53:Get*",
      "route53:List*",
      "route53:UpdateHealthCheck",
      "servicediscovery:DeregisterInstance",
      "servicediscovery:Get*",
      "servicediscovery:List*",
      "servicediscovery:RegisterInstance",
      "servicediscovery:UpdateInstanceCustomHealthStatus"
    ]
  }
  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:network-interface/*"]
    actions = [
      "ec2:CreateTags"
    ]
  }
  statement {
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:log-group:/aws/ecs/*"]
    actions = [
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy"
    ]
  }
  statement {
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:log-group:/aws/ecs/*:log-stream:*"]
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
  }
}

/* ecs task_difinition for elasticsearch */
module "hoge_es_task_definition" {
  source                 = "../modules/ecs/ecs_task_definition"
  task_difinition_family = "hoge-test-es-ecs"
  container_definitions  = file("./es_task_container_definitions.json")
  execution_role_arn     = module.hoge_ecs_task_execution_role.iam_role_arn
  task_role_arn          = module.hoge_es_task_role.iam_role_arn
  memory                 = 60000
  cpu                    = 512
  has_volume = true
  volume_name      = "esdata"
  volume_path = "/usr/share/elasticsearch/data/"
}

/* ecs task_difinition for kibana */
module "hoge_kibana_task_definition" {
  source                 = "../modules/ecs/ecs_task_definition"
  task_difinition_family = "hoge-test-kibana-ecs"
  container_definitions  = file("./kibana_task_container_definitions.json")
  execution_role_arn     = module.hoge_ecs_task_execution_role.iam_role_arn
  task_role_arn          = module.hoge_es_task_role.iam_role_arn
  memory                 = 1024
  cpu                    = 512
}

/* ecs_task_difinition iam_role  */
module "hoge_ecs_task_execution_role" {
  source     = "../modules/iam_role"
  role_name  = "hoge-ad-ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policies = [
    {
      name   = "hoge-ad-ecs-task-execution"
      policy = data.aws_iam_policy_document.ecs_task_execution.json
    }
  ]
}
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "kms:Decrypt",
      "ecr:*",
      "s3:*",
    ]

    resources = ["*"]
  }
}

/* コンテナ内のやーつ */
module "hoge_es_task_role" {
  source     = "../modules/iam_role"
  role_name  = "ad-task-role"
  identifier = "ecs-tasks.amazonaws.com"
  policies = [
    {
      name   = "ad-task-role"
      policy = data.aws_iam_policy_document.policy_for_ecs_task_role.json
    }
  ]
}

data "aws_iam_policy_document" "policy_for_ecs_task_role" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "s3:*",
      "cloudwatch:*",
      "firehose:*",
      "lambda:*",
      "kms:*"
    ]
  }
}



/* ecr */
module "hoge_test_es_app_ecr" {
  source                  = "../modules/ecr"
  aws_ecr_repository_name = "hoge-test-es"
}

resource "null_resource" "iam_wait" {
  depends_on = [
    "aws_iam_role.cluster_instance_role",
    "aws_iam_policy.cluster_instance_policy",
    "aws_iam_policy_attachment.cluster_instance_policy_attachment",
    "aws_iam_instance_profile.cluster",
    "aws_iam_role.cluster_service_role",
    "aws_iam_policy.cluster_service_policy",
    "aws_iam_policy_attachment.cluster_service_policy_attachment"
  ]

  provisioner "local-exec" {
    command = "sleep 120"
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

data "template_file" "ami_id" {
  template = "${coalesce(lookup(var.cluster_instance_amis, var.region), data.aws_ami.amazon_linux_2.image_id)}"
}


/* for cloudwatch agent */
data "template_file" "cloud_init" {
  template = var.cloud_init_template

  vars = {
    cluster_name       = "${aws_ecs_cluster.cluster.name}"
    ssm_parameter_name = var.ssm_parameter_name
  }
}
resource "aws_ssm_parameter" "cwagent" {
  name  = var.ssm_parameter_name
  type  = "String"
  value = file("${path.module}/templates/amazon-cloudwatch-agent.json")
}

resource "aws_launch_template" "default" {
  name          = "cluster-${var.component}-${var.deployment_identifier}-${var.cluster_name}"
  image_id      = "${data.template_file.ami_id.rendered}"
  instance_type = var.cluster_instance_types[0]
  key_name      = "${aws_key_pair.cluster.key_name}"


  iam_instance_profile {
    name = "${aws_iam_instance_profile.cluster.name}"
  }

  vpc_security_group_ids = concat(list(aws_security_group.cluster.id), var.security_groups)

  user_data = base64encode(data.template_file.cloud_init.rendered)

  block_device_mappings {
    device_name = "/dev/xvda" # root device name of amazon linux2

    ebs {
      volume_size           = "${var.cluster_instance_root_block_device_size}"
      volume_type           = "${var.cluster_instance_root_block_device_type}"
      delete_on_termination = true
    }
  }
  depends_on = [
    "null_resource.iam_wait"
  ]
}

resource "aws_autoscaling_group" "default" {
  name                = "asg-${aws_launch_template.default.name}"
  vpc_zone_identifier = "${split(",", var.subnet_ids)}"
  min_size            = "${var.cluster_minimum_size}"
  max_size            = "${var.cluster_maximum_size}"
  desired_capacity    = "${var.cluster_desired_capacity}"

  lifecycle {
    ignore_changes = ["desired_capacity"]
  }
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = "${aws_launch_template.default.id}"
        version            = "${aws_launch_template.default.latest_version}"
      }

      dynamic override {
        for_each = var.cluster_instance_types
        content {
          instance_type = override.value
        }
      }
    }

    instances_distribution {
      on_demand_percentage_above_base_capacity = var.cluster_asg_on_demand_instance_min
      spot_allocation_strategy                 = "lowest-price"
      spot_instance_pools                      = "2"
    }
  }

  tag {
    key                 = "Name"
    value               = "cluster-worker-${var.component}-${var.deployment_identifier}-${var.cluster_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Component"
    value               = "${var.component}"
    propagate_at_launch = true
  }

  tag {
    key                 = "DeploymentIdentifier"
    value               = "${var.deployment_identifier}"
    propagate_at_launch = true
  }

  tag {
    key                 = "ClusterName"
    value               = "${var.cluster_name}"
    propagate_at_launch = true
  }
}

# Automatically scale capacity up by one
resource "aws_autoscaling_policy" "dev_api_scale_out" {
  name                   = "${var.cluster_name}-Instance-ScaleOut-CPU-High"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.default.name
}

# Automatically scale capacity down by one
resource "aws_autoscaling_policy" "dev_api_scale_in" {
  name                   = "${var.cluster_name}-Instance-ScaleIn-CPU-Low"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.default.name
}


resource "aws_ecs_cluster" "cluster" {
  name = "${var.component}-${var.deployment_identifier}-${var.cluster_name}"

  depends_on = ["null_resource.iam_wait"]

  tags = {
    DeploymentIdentifier = "${var.deployment_identifier}"
  }
}

// EC2のAutoScaleGroupがスケールイン(減る)時、cloudwatch events で取得できるような状態を発行する
// https://github.com/getsocial-rnd/ecs-drain-lambda ここの定義のパクリ.
resource "aws_autoscaling_lifecycle_hook" "cluster" {
  name                   = "${var.cluster_name}_autoscale_abandon_hook"
  autoscaling_group_name = "${aws_autoscaling_group.default.name}"
  default_result         = "ABANDON"
  heartbeat_timeout      = 180
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"

  notification_metadata = <<EOF
{
}
EOF
}
/* sg */
resource "aws_security_group" "default" {
  name   = var.name
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ingress" {
  count                    = var.ingress_config == null ? 0 : length(var.ingress_config)
  type                     = "ingress"
  from_port                = var.ingress_config[count.index]["from_port"]
  to_port                  = var.ingress_config[count.index]["to_port"]
  protocol                 = var.ingress_config[count.index]["protocol"]
  cidr_blocks              = var.ingress_config[count.index]["cidr_blocks"]
  source_security_group_id = var.ingress_config[count.index]["source_security_group_id"]
  security_group_id        = aws_security_group.default.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = var.egress_config["from_port"]
  to_port           = var.egress_config["to_port"]
  protocol          = var.egress_config["protocol"]
  cidr_blocks       = var.egress_config["cidr_blocks"]
  security_group_id = aws_security_group.default.id
}


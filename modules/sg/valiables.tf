/* required */
variable "name" {
}

variable "vpc_id" {
}

/* optional */
variable "ingress_config" {
  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = list(string)
    source_security_group_id = string
  }))
  description = "ingressの設定のobjectのリストを入れる　使う側はcidr_blocksか source_security_group_id　どちらかを設定、どちらかをnullに"
  default     = null
}

variable "egress_config" {
  type = object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  })
  default = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
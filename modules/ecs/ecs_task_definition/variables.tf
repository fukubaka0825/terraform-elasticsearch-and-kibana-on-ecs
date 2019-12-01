/* required */
variable "task_difinition_family" {}
variable "execution_role_arn" {
  description = "Amazon ECS container agent and the Docker daemon can assume"
}
variable "container_definitions" {}
/* optional */
variable "cpu" {
  default = "256"
}
variable "memory" {
  default = "512"
}
variable "network_mode" {
  default = "bridge"
}
variable "requires_compatibilities" {
  default = ["EC2"]
}
variable "task_role_arn" {
  description = "ECS container task to make calls to other AWS services"
  default     = null
}

variable "tags" {
  default = {}
}


variable "has_volume" {
  default = false
}
/* if has_volume is true, required */
variable "volume_name" {
  default = null
}
variable "volume_path" {
  default = null
}
/* required */
variable "role_name" {
}

variable "policies" {
  type        = list(map(string))
  description = "policyの設定のmap(nameとpolicyをkeyに持つ)の配列を入れる"
}

variable "identifier" {
}


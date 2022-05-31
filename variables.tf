variable "cluster_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "task_definition_arn" {
  type = string
}

variable "subnets" {
  type    = list(string)
  default = []
}

variable "security_groups" {
  type    = list(string)
  default = []
}

variable "services" {
  type    = any
  default = null
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "tags" {
  type    = map(string)
  default = {}
}

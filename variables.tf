variable "cluster_id" {
  type = string
}

variable "cluster_name" {
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

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "services" {
  type    = any
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "launch_type" {
  type    = string
  default = null
}

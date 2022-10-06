variable "cluster_name" {
  type    = string
  default = "desafio-terraform-wesley3"
}

variable "kubernetes_version" {
  type    = string
  default = "kindest/node:v1.18.4"
}
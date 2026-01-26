variable "name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "client_name" {
  type = string
}

variable "name" { type = string }
variable "cidr" { type = string }

variable "az_count" {
  type    = number
  default = 2
}

variable "tags" {
  type    = map(string)
  default = {}
}

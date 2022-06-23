variable "ec2_ingress" {
  type = map(object(
    {
      port        = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }
  ))
  default = {
    "80" = {
      "port"        = 80
      "protocol"    = "tcp"
      "cidr_blocks" = ["0.0.0.0/0"]
      "description" = "allow http"
    },
    "443" = {
      "port"        = 443
      "protocol"    = "tcp"
      "cidr_blocks" = ["0.0.0.0/0"]
      "description" = "allow https"
    },
    "22" = {
      "port"        = 22
      "protocol"    = "tcp"
      "cidr_blocks" = ["0.0.0.0/0"]
      "description" = "allow ssh"
    }

  }
}

variable "db_name" {
  description = "database name"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "database password"
  type        = string
  sensitive   = true
}

variable "domain" {
  type        = string
  description = "domain name the webapp will be hosted for"
}

variable "db_user" {
  type        = string
  description = "db username"
}
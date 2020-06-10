variable "vpc_id" {
  description = "Existing VPC to use (specify this, if you don't want to create new VPC)"
  default     = ""
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "10.10.0.0/16"
}

variable "subnet_id_primary" {
    description = "Existing Subnet id primary to use"
    default = ""
}

variable "subnet_id_secondary" {
    description = "Existing Subnet id secondary"
    default = ""
}

variable "subnet_id_third" {
    description = "Existing Subnet id third"
    default = ""
}

variable "subnet_cidr_primary" {
    description = "The CIDR block for the 1st subnet"
    default = "10.10.101.0/24"
}

variable "subnet_cidr_secondary" {
    description = "The CIDR block for the 2nd subnet"
    default = "10.10.102.0/24"
}

variable "subnet_cidr_third" {
    description = "The CIDR block for the 3rd subnet"
    default = "10.10.103.0/24"
}

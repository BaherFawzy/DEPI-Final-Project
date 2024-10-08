variable "Environment" {
  description = "The environment for the resources"
  type        = string
  default     = "DEPI"
}

variable "Owner" {
  description = "The owner of the resources"
  type        = string
  default     = "Mahmoud Sharara"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "instance_type" {
  description = "The name for the instance type"
  type        = string
}

variable "ami" {
  description = "AMI ID for the bastion host"
  type        = string
}

variable "docker_username" {
  description = "Docker Hub username for pushing images"
  type        = string
}

variable "docker_password" {
  description = "Docker Hub password for pushing images"
  type        = string
  sensitive   = true  # This ensures the password is not displayed in the logs
}
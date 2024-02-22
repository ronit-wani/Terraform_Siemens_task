variable "region" {
  description = "The AWS region in which the resources will be created."
  type        = string
  default     = "eu-west-1"
}

variable "availability_zone" {
  description = "The availability zone where the resources will reside."
  type        = string
  default     = "eu-west-1a"
}

variable "availability_zone2" {
  description = "The availability zone where the resources will reside."
  type        = string
  default     = "eu-west-1b"
}

variable "ami" {
  description = "The ID of the Amazon Machine Image (AMI) used to create the EC2 instance."
  type        = string
  default     = "ami-0261755***b8c4a84"
}
variable "instance_type" {
  description = "The type of EC2 instance used to create the instance."
  type        = string
  default     = "t2.micro"
}
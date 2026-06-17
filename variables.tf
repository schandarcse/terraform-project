# variables.tf
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment_name" {
  description = "Environment name for tagging and identification"
  type        = string
}

variable "sg_name" {
  description = "Environment name for Security group"
  type        = string
}

variable "OS_name" {
  description = "OS name for template"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for the Subnet in Availability Zone A"
  type        = string
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for the Subnet in Availability Zone B"
  type        = string
}

variable "private_subnet_c_cidr" {
  description = "CIDR block for the Subnet in Availability Zone C"
  type        = string
}

variable "subnet_az_p" {
  description = "Availability Zone for Public Subnet P"
  type        = string
}

variable "subnet_az_q" {
  description = "Availability Zone for Public Subnet Q"
  type        = string
}

variable "public_subnet_p_cidr" {
  description = "CIDR block for the Subnet P in the availability for value of subnet_az_p"
  type        = string
}

variable "private_subnet_q_cidr" {
  description = "CIDR block for the Subnet Q in the availability for value of subnet_az_q"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID to use for EC2 instances"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (adjust as needed)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 KeyPair for SSH access"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
}

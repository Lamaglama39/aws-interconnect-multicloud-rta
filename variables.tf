################################################################################
# General
################################################################################

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "interconnect-multicloud"
}

################################################################################
# AWS
################################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_subnet_cidr" {
  description = "CIDR block for AWS public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "aws_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "aws_ec2_private_ip" {
  description = "Fixed private IP address for EC2 instance"
  type        = string
  default     = "10.0.1.100"
}

variable "dx_gateway_asn" {
  description = "ASN for Direct Connect Gateway"
  type        = number
  default     = 64512
}

################################################################################
# GCP
################################################################################

variable "gcp_project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "gcp_region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-east4"
}

variable "gcp_subnet_cidr" {
  description = "CIDR block for GCP subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "gcp_machine_type" {
  description = "GCE machine type"
  type        = string
  default     = "e2-micro"
}

variable "gcp_gce_private_ip" {
  description = "Fixed private IP address for GCE instance"
  type        = string
  default     = "10.1.1.100"
}

variable "cloud_router_asn" {
  description = "ASN for Google Cloud Router"
  type        = number
  default     = 65200
}

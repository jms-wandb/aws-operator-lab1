variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "zone_id" {
  type        = string
  description = "Id of Route53 zone"
}

variable "size" {
  default     = "small"
  description = "Deployment size"
  nullable    = true
  type        = string
}

variable "subdomain" {
  type        = string
  default     = null
  description = "Subdomain for accessing the Weights & Biases UI."
}

variable "wandb_license" {
  type = string
}

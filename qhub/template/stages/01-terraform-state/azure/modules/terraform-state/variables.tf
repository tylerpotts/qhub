variable "resource_group_name" {
  description = "Prefix of name to append resource"
  type        = string
}

variable "name" {
  description = "Prefix of name to append resource"
  type        = string
}

variable "location" {
  description = "Location for terraform state"
  type        = string
}

variable "storage_account_postfix" {
  description = "random characters appended to storage account name to facilitate global uniqueness"
  type        = string
}

variable "tags" {
  description = "A mapping of tags to be assigned to the resources"
  type        = map(any)
  default     = {}
}

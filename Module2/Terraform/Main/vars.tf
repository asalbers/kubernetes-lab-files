variable "ACR" {
  type        = string
  description = "This is the acr name"
}

variable "AKS_CLUSTER" {
  type        = string
  description = "This is the aks name"
}

variable "DIAGNOSTIC_SETTING_NAME" {
  type        = string
  description = "This is the ds name"
}

variable "LOG_ANALYTICS_WORKSPACE_NAME" {
  type        = string
  description = "This is the law name"
}

variable "AKS_RESOURCE_GROUP" {
  type        = string
  description = "This is the rg name"
}

variable "STORAGE_ACCOUNT_NAME" {
  type        = string
  description = "This is the sa name"
}

variable "network_plugin_mode" {
  type        = string
  default     = "overlay"
  description = "(Optional) Specifies the network plugin mode used for building the Kubernetes network. Possible value is `overlay`. Changing this forces a new resource to be created."
}
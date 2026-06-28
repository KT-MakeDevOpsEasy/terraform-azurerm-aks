variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where AKS will be created"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "AKS SKU tier: Free or Standard"
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "SKU tier must be Free or Standard."
  }
}

# --- Networking ---

variable "node_subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

variable "network_policy" {
  description = "Network policy provider: azure or calico"
  type        = string
  default     = "calico"

  validation {
    condition     = contains(["azure", "calico"], var.network_policy)
    error_message = "Network policy must be azure or calico."
  }
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "172.16.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP (must be within service_cidr)"
  type        = string
  default     = "172.16.0.10"
}

variable "private_cluster_enabled" {
  description = "Enable private cluster (API server only accessible within VNET)"
  type        = bool
  default     = false
}

variable "authorized_ip_ranges" {
  description = "CIDR ranges authorized to access the API server (ignored if private cluster)"
  type        = list(string)
  default     = []
}

# --- Node Pools ---

variable "system_node_pool" {
  description = "Configuration for the default (system) node pool"
  type = object({
    vm_size              = optional(string, "Standard_D2s_v3")
    node_count           = optional(number, 1)
    min_count            = optional(number, 1)
    max_count            = optional(number, 3)
    auto_scaling_enabled = optional(bool, true)
    os_disk_size_gb      = optional(number, 50)
    zones                = optional(list(string), ["1", "2", "3"])
  })
  default = {}
}

variable "user_node_pools" {
  description = "Map of additional user node pools"
  type = map(object({
    vm_size              = optional(string, "Standard_D4s_v3")
    node_count           = optional(number, 1)
    min_count            = optional(number, 1)
    max_count            = optional(number, 5)
    auto_scaling_enabled = optional(bool, true)
    os_disk_size_gb      = optional(number, 100)
    zones                = optional(list(string), ["1", "2", "3"])
    node_labels          = optional(map(string), {})
    node_taints          = optional(list(string), [])
  }))
  default = {}
}

# --- Identity & RBAC ---

variable "workload_identity_enabled" {
  description = "Enable workload identity (OIDC issuer + federated credentials)"
  type        = bool
  default     = true
}

# --- Observability ---

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Container Insights"
  type        = string
}

# --- Tags ---

variable "tags" {
  description = "Tags to apply to all resources (ManagedBy=terraform is always added)"
  type        = map(string)
  default     = {}
}

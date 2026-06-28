locals {
  required_tags = {
    ManagedBy = "terraform"
  }

  merged_tags = merge(var.tags, local.required_tags)
}

resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${var.cluster_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.merged_tags
}

resource "azurerm_role_assignment" "aks_network" {
  scope                = var.node_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier
  tags                = local.merged_tags

  private_cluster_enabled = var.private_cluster_enabled

  dynamic "api_server_access_profile" {
    for_each = length(var.authorized_ip_ranges) > 0 && !var.private_cluster_enabled ? [1] : []
    content {
      authorized_ip_ranges = var.authorized_ip_ranges
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  default_node_pool {
    name                         = "system"
    temporary_name_for_rotation  = "systemtmp"
    vm_size                      = var.system_node_pool.vm_size
    node_count                   = var.system_node_pool.auto_scaling_enabled ? null : var.system_node_pool.node_count
    min_count                    = var.system_node_pool.auto_scaling_enabled ? var.system_node_pool.min_count : null
    max_count                    = var.system_node_pool.auto_scaling_enabled ? var.system_node_pool.max_count : null
    auto_scaling_enabled         = var.system_node_pool.auto_scaling_enabled
    vnet_subnet_id               = var.node_subnet_id
    os_disk_size_gb              = var.system_node_pool.os_disk_size_gb
    zones                        = var.system_node_pool.zones
    only_critical_addons_enabled = var.system_node_pool.only_critical_addons_enabled


    node_labels = {
      "nodepool-type" = "system"
    }
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = var.network_policy
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
  }

  oidc_issuer_enabled       = var.workload_identity_enabled
  workload_identity_enabled = var.workload_identity_enabled

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  auto_scaler_profile {
    balance_similar_node_groups      = true
    max_graceful_termination_sec     = "600"
    scale_down_delay_after_add       = "10m"
    scale_down_unneeded              = "10m"
    scale_down_utilization_threshold = "0.5"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version,
    ]
  }

  depends_on = [azurerm_role_assignment.aks_network]
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.user_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = each.value.vm_size
  node_count            = each.value.auto_scaling_enabled ? null : each.value.node_count
  min_count             = each.value.auto_scaling_enabled ? each.value.min_count : null
  max_count             = each.value.auto_scaling_enabled ? each.value.max_count : null
  auto_scaling_enabled  = each.value.auto_scaling_enabled
  vnet_subnet_id        = var.node_subnet_id
  os_disk_size_gb       = each.value.os_disk_size_gb
  zones                 = each.value.zones
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  tags                  = var.tags

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}

# terraform-azurerm-aks

Generic, reusable Terraform module for provisioning a production-grade Azure Kubernetes Service (AKS) cluster.

## Usage

```hcl
module "aks" {
  source = "git::https://github.com/<org>/terraform-azurerm-aks.git?ref=v1.0.0"

  cluster_name        = "aks-myapp-dev-eus"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  dns_prefix          = "myapp-dev"

  node_subnet_id             = azurerm_subnet.nodes.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  system_node_pool = {
    vm_size             = "Standard_D2s_v3"
    min_count           = 1
    max_count           = 3
    enable_auto_scaling = true
  }

  user_node_pools = {
    workload = {
      vm_size             = "Standard_D4s_v3"
      min_count           = 1
      max_count           = 5
      enable_auto_scaling = true
      node_labels         = { "workload-type" = "general" }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
```

## Versioning

This module follows [Semantic Versioning](https://semver.org/). Pin to a specific version using `?ref=v1.0.0`.

<!-- BEGIN_TF_DOCS -->

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_name | Name of the AKS cluster | `string` | n/a | yes |
| resource\_group\_name | Resource group for AKS | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| dns\_prefix | DNS prefix for the cluster | `string` | n/a | yes |
| node\_subnet\_id | Subnet ID for AKS nodes | `string` | n/a | yes |
| log\_analytics\_workspace\_id | Log Analytics workspace ID | `string` | n/a | yes |
| kubernetes\_version | Kubernetes version | `string` | `null` | no |
| sku\_tier | AKS SKU tier (Free/Standard) | `string` | `"Free"` | no |
| network\_policy | Network policy (azure/calico) | `string` | `"calico"` | no |
| service\_cidr | CIDR for K8s services | `string` | `"172.16.0.0/16"` | no |
| dns\_service\_ip | DNS service IP | `string` | `"172.16.0.10"` | no |
| private\_cluster\_enabled | Enable private cluster | `bool` | `false` | no |
| authorized\_ip\_ranges | API server authorized CIDRs | `list(string)` | `[]` | no |
| system\_node\_pool | System node pool config | `object` | See variables.tf | no |
| user\_node\_pools | User node pool configs | `map(object)` | `{}` | no |
| workload\_identity\_enabled | Enable workload identity | `bool` | `true` | no |
| tags | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_id | AKS cluster ID |
| cluster\_name | AKS cluster name |
| cluster\_fqdn | AKS cluster FQDN |
| kube\_config\_raw | Raw kubeconfig (sensitive) |
| kube\_admin\_config\_raw | Raw admin kubeconfig (sensitive) |
| kubelet\_identity\_object\_id | Kubelet managed identity object ID |
| cluster\_identity\_principal\_id | Cluster identity principal ID |
| oidc\_issuer\_url | OIDC issuer URL |
| node\_resource\_group | Node resource group name |

<!-- END_TF_DOCS -->

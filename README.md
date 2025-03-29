```hcl
resource "azurerm_eventhub_namespace" "eventhubs" {
  for_each            = { for eh in var.eventhubs : eh.name => eh }
  location            = each.value.location
  name                = each.value.name
  resource_group_name = each.value.rg_name
  tags                = each.value.tags
  sku                 = title(each.value.sku)


  dynamic "network_rulesets" {
    for_each = each.value.network_rulesets != null ? [each.value.network_rulesets] : []
    content {
      default_action                = try(network_rulesets.value.default_action, null)
      public_network_access_enabled = try(network_rulesets.value.public_network_access_enabled, null)
      trusted_services_enabled      = try(network_rulesets.value.trusted_services_enabled, null)

      dynamic "virtual_network_rule" {
        for_each = network_rulesets.value.virtual_network_rule != null ? [network_rulesets.value.virtual_network_rule] : []
        content {
          subnet_id                                       = virtual_network_rule.value.subnet_id
          ignore_missing_virtual_network_service_endpoint = try(virtual_network_rule.value.ignore_missing_virtual_network_service_endpoint, null)
        }
      }

      dynamic "ip_rule" {
        for_each = network_rulesets.value.ip_rule != null ? [network_rulesets.value.ip_rule] : []
        content {
          ip_mask = ip_rule.value.ip_mask
          action  = try(ip_rule.value.action, null)
        }
      }
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned" ? [each.value.identity_type] : []
    content {
      type = each.value.identity_type
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned, UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = try(each.value.identity_ids, [])
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = length(try(each.value.identity_ids, [])) > 0 ? each.value.identity_ids : []
    }
  }
}
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_eventhub_namespace.eventhubs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eventhubs"></a> [eventhubs](#input\_eventhubs) | List of Eventhubs to create | <pre>list(object({<br/>    name                          = string<br/>    location                      = optional(string, "uksouth")<br/>    rg_name                       = string<br/>    tags                          = optional(map(string))<br/>    identity_type                 = optional(string)<br/>    identity_ids                  = optional(list(string))<br/>    sku                           = optional(string)<br/>    capacity                      = optional(number)<br/>    auto_inflate_enabled          = optional(bool)<br/>    dedicated_cluster_id          = optional(string)<br/>    maximum_throughput_units      = optional(number)<br/>    local_authentication_enabled  = optional(bool)<br/>    public_network_access_enabled = optional(bool)<br/>    minimum_tls_version           = optional(string)<br/>    network_rulesets = optional(object({<br/>      default_action                = optional(string)<br/>      public_network_access_enabled = optional(bool)<br/>      trusted_services_enabled      = optional(bool)<br/>      virtual_network_rule = optional(list(object({<br/>        subnet_id                                       = string<br/>        ignore_missing_virtual_network_service_endpoint = optional(bool)<br/>      })))<br/>      ip_rule = optional(list(object({<br/>        ip_mask = string<br/>        action  = optional(string)<br/>      })))<br/>    }))<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eventhub_identities"></a> [eventhub\_identities](#output\_eventhub\_identities) | The identities of the Event Hubs |
| <a name="output_eventhub_ids"></a> [eventhub\_ids](#output\_eventhub\_ids) | The IDs of the Dev Centers |
| <a name="output_eventhub_names"></a> [eventhub\_names](#output\_eventhub\_names) | The default name of the Dev Centers |

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

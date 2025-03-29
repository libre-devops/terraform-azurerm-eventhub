########################################
# azurerm_eventhub_namespace
########################################

resource "azurerm_eventhub_namespace" "eventhubs" {
  # Create a namespace for each entry in var.eventhubs
  for_each                      = { for eh in var.eventhubs : eh.namespace_name => eh }
  location                      = each.value.location
  name                          = each.value.namespace_name
  resource_group_name           = each.value.rg_name
  tags                          = each.value.tags
  sku                           = title(each.value.sku)
  capacity                      = each.value.capacity
  auto_inflate_enabled          = each.value.auto_inflate_enabled
  dedicated_cluster_id          = each.value.dedicated_cluster_id
  maximum_throughput_units      = each.value.maximum_throughput_units
  local_authentication_enabled  = each.value.local_authentication_enabled
  public_network_access_enabled = each.value.public_network_access_enabled

  dynamic "network_rulesets" {
    for_each = each.value.network_rulesets != null ? [each.value.network_rulesets] : []
    content {
      default_action                 = try(network_rulesets.value.default_action, null)
      public_network_access_enabled  = try(network_rulesets.value.public_network_access_enabled, null)
      trusted_service_access_enabled = try(network_rulesets.value.trusted_service_access_enabled, null)

      dynamic "virtual_network_rule" {
        for_each = network_rulesets.value.virtual_network_rule != null ? network_rulesets.value.virtual_network_rule : []
        content {
          subnet_id                                       = virtual_network_rule.value.subnet_id
          ignore_missing_virtual_network_service_endpoint = try(virtual_network_rule.value.ignore_missing_virtual_network_service_endpoint, null)
        }
      }

      dynamic "ip_rule" {
        for_each = network_rulesets.value.ip_rule != null ? network_rulesets.value.ip_rule : []
        content {
          ip_mask = ip_rule.value.ip_mask
          action  = try(ip_rule.value.action, null)
        }
      }
    }
  }

  # Identity blocks
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

########################################
# azurerm_eventhub
########################################

resource "azurerm_eventhub" "eventhubs" {
  # Create an Event Hub only if `create_eventhub` is true
  for_each = {
    for eh in var.eventhubs :
    eh.namespace_name => eh
    if eh.create_eventhub == true
  }

  # Basic config
  name              = try(each.value.eventhub_name, each.key) # fallback to namespace name if not provided
  namespace_id      = azurerm_eventhub_namespace.eventhubs[each.key].id
  partition_count   = try(each.value.partition_count, 2)   # default to 2
  message_retention = try(each.value.message_retention, 1) # default to 1 day

  # If `capture_description` is present, build a capture_description block
  dynamic "capture_description" {
    for_each = each.value.capture_description != null ? [each.value.capture_description] : []
    content {
      enabled             = try(capture_description.value.enabled, false)
      encoding            = try(capture_description.value.encoding, null)
      interval_in_seconds = try(capture_description.value.interval_in_seconds, null)
      size_limit_in_bytes = try(capture_description.value.size_limit_in_bytes, null)
      skip_empty_archives = try(capture_description.value.skip_empty_archives, false)

      # Nested destination block within capture_description
      dynamic "destination" {
        for_each = capture_description.value.destination != null ? [capture_description.value.destination] : []
        content {
          name                = destination.value.name
          storage_account_id  = destination.value.storage_account_id
          blob_container_name = destination.value.blob_container_name
          archive_name_format = destination.value.archive_name_format
        }
      }
    }
  }
}

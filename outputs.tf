output "eventhub_identities" {
  description = "The identities of the Event Hubs"
  value = {
    for key, value in azurerm_eventhub_namespace.eventhubs : key =>
    length(value.identity) > 0 ? {
      type         = try(value.identity[0].type, null)
      principal_id = try(value.identity[0].principal_id, null)
      tenant_id    = try(value.identity[0].tenant_id, null)
      } : {
      type         = null
      principal_id = null
      tenant_id    = null
    }
  }
}

output "eventhub_ids" {
  description = "The IDs of the Dev Centers"
  value       = { for ev in azurerm_eventhub_namespace.eventhubs : ev.name => ev.id }
}

output "eventhub_namespace_names" {
  description = "The default name of the Dev Centers"
  value       = { for ev in azurerm_eventhub_namespace.eventhubs : ev.name => ev.name }
}

output "eventhub_root_manage_shared_access_keys" {
  description = "RootManageSharedAccessKey values for each Event Hub Namespace"
  value = {
    for ev in azurerm_eventhub_namespace.eventhubs : ev.name => {
      default_primary_connection_string         = ev.default_primary_connection_string
      default_primary_connection_string_alias   = ev.default_primary_connection_string_alias
      default_primary_key                       = ev.default_primary_key
      default_secondary_connection_string       = ev.default_secondary_connection_string
      default_secondary_connection_string_alias = ev.default_secondary_connection_string_alias
      default_secondary_key                     = ev.default_secondary_key
    }
  }
}

output "eventhubs" {
  description = "Details of the created Event Hubs (id, partition_ids, name, etc.)"
  # This output only exists for Event Hubs actually created (where create_eventhub = true).
  value = {
    for name, eh in azurerm_eventhub.eventhubs : name => {
      id            = eh.id
      partition_ids = eh.partition_ids
      name          = eh.name
    }
  }
}

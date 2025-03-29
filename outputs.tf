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

output "eventhub_names" {
  description = "The default name of the Dev Centers"
  value       = { for ev in azurerm_eventhub_namespace.eventhubs : ev.name => ev.name }
}

variable "eventhubs" {
  description = "List of Eventhubs to create"
  type = list(object({
    name                          = string
    location                      = optional(string, "uksouth")
    rg_name                       = string
    tags                          = optional(map(string))
    identity_type                 = optional(string)
    identity_ids                  = optional(list(string))
    sku                           = optional(string)
    capacity                      = optional(number)
    auto_inflate_enabled          = optional(bool)
    dedicated_cluster_id          = optional(string)
    maximum_throughput_units      = optional(number)
    local_authentication_enabled  = optional(bool)
    public_network_access_enabled = optional(bool)
    minimum_tls_version           = optional(string)
    network_rulesets = optional(object({
      default_action                = optional(string)
      public_network_access_enabled = optional(bool)
      trusted_services_enabled      = optional(bool)
      virtual_network_rule = optional(list(object({
        subnet_id                                       = string
        ignore_missing_virtual_network_service_endpoint = optional(bool)
      })))
      ip_rule = optional(list(object({
        ip_mask = string
        action  = optional(string)
      })))
    }))
  }))
}

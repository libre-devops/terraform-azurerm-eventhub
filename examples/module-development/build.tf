locals {
  rg_name                 = "rg-${var.short}-${var.loc}-${var.env}-01"
  vnet_name               = "vnet-${var.short}-${var.loc}-${var.env}-01"
  storage_account_name    = "sa${var.short}${var.loc}${var.env}01"
  storage_container_name  = "events"
  eventhub_subnet_name    = "Eventhubsubnet"
  storage_subnet_name     = "Storagesubnet"
  eventhub_namespace_name = "ehns-${var.short}-${var.loc}-${var.env}-01"
  eventhub_name           = "eh-${var.short}-${var.loc}-${var.env}-01"
}

module "rg" {
  source = "libre-devops/rg/azurerm"

  rg_name  = local.rg_name
  location = local.location
  tags     = local.tags
}

module "shared_vars" {
  source = "libre-devops/shared-vars/azurerm"
}

locals {
  lookup_cidr = {
    for landing_zone, envs in module.shared_vars.cidrs : landing_zone => {
      for env, cidr in envs : env => cidr
    }
  }
}

module "subnet_calculator" {
  source = "libre-devops/subnet-calculator/null"

  base_cidr = local.lookup_cidr["lbd"][var.env][0]
  subnets = {
    (local.eventhub_subnet_name) = {
      mask_size = 26
      netnum    = 0
    }
    (local.storage_subnet_name) = {
      mask_size = 26
      netnum    = 1
    }
  }
}

module "network" {
  source = "libre-devops/network/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  vnet_name          = local.vnet_name
  vnet_location      = module.rg.rg_location
  vnet_address_space = [module.subnet_calculator.base_cidr]

  subnets = {
    for i, name in module.subnet_calculator.subnet_names :
    name => {
      address_prefixes  = toset([module.subnet_calculator.subnet_ranges[i]])
      service_endpoints = name == local.eventhub_subnet_name ? ["Microsoft.EventHub"] : name == local.storage_subnet_name ? ["Microsoft.Storage"] : []

      # Only assign delegation to subnet3
      delegation = []
    }
  }
}



module "sa" {
  source = "registry.terraform.io/libre-devops/storage-account/azurerm"
  storage_accounts = [
    {
      name     = local.storage_account_name
      rg_name  = module.rg.rg_name
      location = module.rg.rg_location
      tags     = module.rg.rg_tags

      identity_type = "SystemAssigned"

      shared_access_keys_enabled                      = false
      create_diagnostic_settings                      = false
      diagnostic_settings_enable_all_logs_and_metrics = false
    },
  ]
}

resource "azurerm_storage_account_network_rules" "rules" {
  default_action     = "Deny"
  storage_account_id = module.sa.storage_account_ids[local.storage_account_name]
  ip_rules           = concat([chomp(data.http.client_ip.response_body)])
  virtual_network_subnet_ids = [
    module.network.subnets_ids[local.storage_subnet_name],
  ]
}

resource "azurerm_storage_container" "events" {
  storage_account_id    = module.sa.storage_account_ids[local.storage_account_name]
  name                  = local.storage_container_name
  container_access_type = "private"
}

module "eventhubs" {
  source = "../../"

  eventhubs = [
    {
      # Namespace-level settings
      namespace_name                = local.eventhub_namespace_name
      rg_name                       = module.rg.rg_name
      location                      = module.rg.rg_location
      tags                          = module.rg.rg_tags
      identity_type                 = "SystemAssigned"
      identity_ids                  = []
      sku                           = "standard"
      capacity                      = 2
      auto_inflate_enabled          = true
      dedicated_cluster_id          = null
      maximum_throughput_units      = 20
      local_authentication_enabled  = true
      public_network_access_enabled = true
      minimum_tls_version           = "1.2"

      # Network rule sets (example with vNet rule and IP rule)
      network_rulesets = {
        default_action                = "Deny"
        public_network_access_enabled = true
        trusted_services_enabled      = true
        virtual_network_rule = [
          {
            subnet_id = module.network.subnets_ids[local.eventhub_subnet_name]
            # If you want to allow the module to handle missing service endpoints:
            ignore_missing_virtual_network_service_endpoint = false
          }
        ]
        ip_rule = [
          {
            ip_mask = chomp(data.http.client_ip.response_body)
            action  = "Allow"
          }
        ]
      }

      # Event Hub-level settings
      create_eventhub   = true
      eventhub_name     = local.eventhub_name
      partition_count   = 2
      message_retention = "1"

      # Optional capture description
      capture_description = {
        enabled             = true
        encoding            = "Avro"
        interval_in_seconds = 120
        size_limit_in_bytes = 10485760
        skip_empty_archives = false

        destination = {
          storage_account_id  = module.sa.storage_account_ids[local.storage_account_name]
          blob_container_name = azurerm_storage_container.events.name
          archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
        }
      }
    },
  ]
}

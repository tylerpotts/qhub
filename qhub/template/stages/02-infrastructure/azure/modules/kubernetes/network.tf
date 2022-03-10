locals {
    count_index = var.enable_existing_vnet ? 0 : 1
}


# Create VNET for qhub node pools usage
resource "azurerm_virtual_network" "qhub_vnet" {
  count = local.count_index

  name                = var.vnet_name
  location            = var.location
  # need to use node_resource_group_name, as LB is in the same resource group
  resource_group_name = var.node_resource_group_name
  address_space       = ["10.0.0.0/8"]

  tags = var.tags
}

resource "azurerm_subnet" "qhub_subnet" {
  count = local.count_index

  name                 = var.subnet_name
  resource_group_name  = var.node_resource_group_name
  virtual_network_name = azurerm_virtual_network.qhub_vnet[0].name
  address_prefixes     = ["10.240.0.0/16"]
}

# Import existing VNET and subnet  if enabled
data "azurerm_subnet" "qhub_subnet" {
  count = var.enable_existing_vnet ? 1 : 0

  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_security_group_name
}

locals {
   subnet_id   = var.enable_existing_vnet ? data.azurerm_subnet.qhub_subnet[0].id : azurerm_subnet.qhub_subnet[0].id
}

# Create VNET for qhub node pools usage
resource "azurerm_virtual_network" "qhub-vnet" {
  count = var.enable_existing_vnet ? 0 : 1

  name                = var.vnet_name
  location            = var.region
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/8"]

  subnet {
    name             = var.subnet_name
    address_prefixes = ["10.240.0.0/16"]
  }

  tags = var.tags
}

# Import existing VNET and subnet  if enabled
data "azurerm_virtual_network" "qhub-vnet" {
  count = var.enable_existing_vnet ? 1 : 0

  name                = var.vnet_name
  resource_group_name = var.vnet_security_group_name
}

data "azurerm_subnet" "qhub-subnet" {
  count = var.enable_existing_vnet ? 1 : 0

  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = data.azurerm_virtual_network.example.resource_group_name
}

locals {
    subnet_id = var.enable_existing_vnet ? data.azurerm_subnet.qhub-subnet.id : azurerm_subnet.qhub-subnet.id
}

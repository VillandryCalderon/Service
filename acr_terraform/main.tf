terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.40.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_virtual_network" "vnet_eastus2" {
  name                = "vnet-eastus2"
  address_space       = ["10.0.0.0/16"]
  location            = var.eastus2_location
  resource_group_name = var.rg_location_eastus2
}

resource "azurerm_virtual_network" "vnet_central" {
  name                = "vnet-centralus"
  address_space       = ["10.0.0.0/16"]
  location            = "Central US"
  resource_group_name = var.rg_location_eastus2
}

resource "azurerm_subnet" "subnet_service_east2" {
  name                 = "subnet_appgw_eastus2"
  resource_group_name  = var.rg_location_eastus2
  virtual_network_name = azurerm_virtual_network.vnet_eastus2.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet_service_centralus" {
  name                 = "subnet_service_centralus"
  resource_group_name  = var.rg_location_eastus2
  virtual_network_name = azurerm_virtual_network.vnet_central.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_container_registry" "acr01" {
  name                          = "acrtestbaccredomatic"
  resource_group_name           = var.rg_location_eastus2
  location                      = var.eastus2_location
  admin_enabled                 = true
  sku                           = "Premium"
  public_network_access_enabled = true
  georeplications {
    location                = "Central US"
    zone_redundancy_enabled = true
  }
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = var.eastus2_location
  resource_group_name = var.rg_location_eastus2

  ip_configuration {
    name                          = "internalip"
    subnet_id                     = azurerm_subnet.subnet_service_east2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.exampleeast.id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = var.rg_location_eastus2
  location            = var.eastus2_location
  size                = "Standard_F2"
  admin_username      = "credomatic"
  disable_password_authentication = false
  admin_password = "Credomatic2023."
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "exampleniccentral" {
  name                = "examplecentral-nic"
  location            = "Central US"
  resource_group_name = var.rg_location_eastus2

  ip_configuration {
    name                          = "internalipcentral"
    subnet_id                     = azurerm_subnet.subnet_service_centralus.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.examplecentral.id
  }
}

resource "azurerm_linux_virtual_machine" "examplecentral" {
  name                = "examplecentral-machine"
  resource_group_name = var.rg_location_eastus2
  location            = "Central US"
  size                = "Standard_F2"
  admin_username      = "credomatic"
  disable_password_authentication = false
  admin_password = "Credomatic2023."
  network_interface_ids = [
    azurerm_network_interface.exampleniccentral.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "exampleeast" {
  name                = "publicipeast2"
  resource_group_name = var.rg_location_eastus2
  location            = var.eastus2_location
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "examplecentral" {
  name                = "publicipcentral"
  resource_group_name = var.rg_location_eastus2
  location            = "Central US"
  allocation_method   = "Static"
}



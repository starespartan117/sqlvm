provider "azurerm" {
  features {}
}

# Crear un grupo de recursos
resource "azurerm_resource_group" "rg" {
  name     = "rg-mxce-dev-sql-01"
  location = "Mexico Central"
}

# Crear una red virtual
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-mxce-dev-sql-01"
  address_space       = ["10.0.0.0/21"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Crear una subred
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-mxce-dev-sql-01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Crear una IP pública
resource "azurerm_public_ip" "public_ip" {
  name                = "pip-mxce-dev-sql-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Crear una interfaz de red
resource "azurerm_network_interface" "nic" {
  name                = "nic-mxce-dev-sql-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Crear una máquina virtual
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "sqlvm-mxce-dev-sql-01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_DS2_v2"
  admin_username      = "sqladmin"
  admin_password      = "Marcusstar183!" # Usa un método más seguro para manejar contraseñas

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2019-WS2019"
    sku       = "Enterprise"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage.primary_blob_endpoint
  }
}

# Crear cuenta de almacenamiento para diagnósticos
resource "azurerm_storage_account" "storage" {
  name                     = "stgmxcedevsql01"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
}
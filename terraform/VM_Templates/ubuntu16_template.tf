# Configure the Azure Provider
provider "azurerm" { }

# Create a resource group
resource "azurerm_resource_group" "dev" {
  name     = "development"
  location = "East US"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "dev" {
  name                = "dev-network"
  address_space       = ["192.168.0.0/16"]
  location            = "${azurerm_resource_group.dev.location}"
  resource_group_name = "${azurerm_resource_group.dev.name}"
}

resource "azurerm_subnet" "dev" {
  name                 = "devsub"
  resource_group_name  = "${azurerm_resource_group.dev.name}"
  virtual_network_name = "${azurerm_virtual_network.dev.name}"
  address_prefix       = "192.168.1.0/24"
}

resource "azurerm_public_ip" "dev" {
  name                         = "dev-pip"
  location                     = "${azurerm_resource_group.dev.location}"
  resource_group_name          = "${azurerm_resource_group.dev.name}"
  public_ip_address_allocation = "Static"
  idle_timeout_in_minutes      = 4

  tags {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "dev" {
  name                = "dev-nic"
  location            = "${azurerm_resource_group.dev.location}"
  resource_group_name = "${azurerm_resource_group.dev.name}"

  ip_configuration {
    name                          = "devconfiguration1"
    subnet_id                     = "${azurerm_subnet.dev.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "192.168.1.52"
    public_ip_address_id          = "${azurerm_public_ip.dev.id}"
  }
}

resource "azurerm_virtual_machine" "dev" {
  name                  = "dev-vm"
  location              = "${azurerm_resource_group.dev.location}"
  resource_group_name   = "${azurerm_resource_group.dev.name}"
  network_interface_ids = ["${azurerm_network_interface.dev.id}"]
  vm_size = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "webdev1"
    admin_username = "azureuser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "dev"
  }

  #hcl ssh_keys { 
   #   key_data = "${file("/home/ryanmiller/.ssh/authorized_keys/azure_default.pub")}" 
   #   path = "/home/azureuser/.ssh/authorized_keys" 
   # }

}

data "azurerm_public_ip" "dev" {
  name                = "${azurerm_public_ip.dev.name}"
  resource_group_name = "${azurerm_virtual_machine.dev.resource_group_name}"
}

output "public_ip_address" {
  value = "${data.azurerm_public_ip.dev.ip_address}"
}
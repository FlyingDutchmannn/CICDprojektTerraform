variable "namevm" {
  type = string
  default = "cicd-proj-tomvd"
}

variable "location" {
  type = string
  default = "West Europe"
}

resource "azurerm_resource_group" "rgTom" {
  name     = "tom-van-duijn-rg"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.namevm}vm-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rgTom.location
  resource_group_name = azurerm_resource_group.rgTom.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rgTom.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "vm1" {
  name                = "vm1-public-ip"
  location            = azurerm_resource_group.rgTom.location
  resource_group_name = azurerm_resource_group.rgTom.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "vm1" {
  name                = "${var.namevm}vm-intf-b1"
  location            = azurerm_resource_group.rgTom.location
  resource_group_name = azurerm_resource_group.rgTom.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.vm1.id
  }
}

resource "azurerm_virtual_machine" "vm1" {
  name                  = "${var.namevm}-terra-vmb1"
  location              = azurerm_resource_group.rgTom.location
  resource_group_name   = azurerm_resource_group.rgTom.name
  network_interface_ids = [azurerm_network_interface.vm1.id]
  vm_size               = "Standard_B1s"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

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
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

##########################################################################################
resource "azurerm_public_ip" "vm2" {
  name                = "vm2-public-ip"
  location            = azurerm_resource_group.rgTom.location
  resource_group_name = azurerm_resource_group.rgTom.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "vm2" {
  name                = "${var.namevm}vm-intf-b2"
  location            = azurerm_resource_group.rgTom.location
  resource_group_name = azurerm_resource_group.rgTom.name

  ip_configuration {
    name                          = "testconfiguration2"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.vm2.id
  }
}

resource "azurerm_virtual_machine" "vm2" {
  name                  = "${var.namevm}-terr-vmb2"
  location              = azurerm_resource_group.rgTom.location
  resource_group_name   = azurerm_resource_group.rgTom.name
  network_interface_ids = [azurerm_network_interface.vm2.id]
  vm_size               = "Standard_B2s"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}
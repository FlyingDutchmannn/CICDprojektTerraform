locals {
  Ssh_Username = "azureuser"
  Ssh_Password = "1234techstarter!"
}

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



resource "azurerm_network_security_group" "nsg" {
  name                = "cicdproject-nsg"
  location            = azurerm_resource_group.rgTom.location
  resource_group_name = azurerm_resource_group.rgTom.name
  depends_on = [
    azurerm_resource_group.rgTom
  ]
}

resource "azurerm_network_security_rule" "sshd" {
  name                        = "SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rgTom.name
  network_security_group_name = azurerm_network_security_group.nsg.name

  depends_on = [
    azurerm_network_security_group.nsg
  ]
}

resource "azurerm_network_security_rule" "web" {
  name                        = "web"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rgTom.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  depends_on = [
    azurerm_network_security_group.nsg
  ]
}

resource "azurerm_network_security_rule" "allout" {
  name                        = "allout"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rgTom.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  depends_on = [
    azurerm_network_security_group.nsg
  ]
}

resource "azurerm_network_interface_security_group_association" "vm1" {
  network_interface_id      = azurerm_network_interface.vm1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on = [
    azurerm_network_interface.vm1,
    azurerm_network_security_group.nsg
  ]
}

resource "azurerm_network_interface_security_group_association" "vm2" {
  network_interface_id      = azurerm_network_interface.vm2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on = [
    azurerm_network_interface.vm2,
    azurerm_network_security_group.nsg
  ]
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
    computer_name         = "jenkins"
    admin_username        = local.Ssh_Username
    admin_password        = local.Ssh_Password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "vm1jenkins"
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
  name                  = "${var.namevm}-terra-vmb2"
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
    computer_name         = "webservervm2"
    admin_username        = local.Ssh_Username
    admin_password        = local.Ssh_Password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "webservervm2"
  }
}
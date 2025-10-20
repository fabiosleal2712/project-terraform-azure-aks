# Identidade Gerenciada para AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.project_name}-${var.environment}-aks-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# Role Assignment para ACR
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_user_assigned_identity.aks.principal_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}

# Role Assignment para Network Contributor
resource "azurerm_role_assignment" "aks_network" {
  principal_id                     = azurerm_user_assigned_identity.aks.principal_id
  role_definition_name             = "Network Contributor"
  scope                            = azurerm_virtual_network.main.id
  skip_service_principal_aad_check = true
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-${var.environment}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.project_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # Node Pool Padrão
  default_node_pool {
    name                = "default"
    node_count          = var.aks_enable_auto_scaling ? null : var.aks_node_count
    vm_size             = var.aks_node_vm_size
    os_disk_size_gb     = var.aks_os_disk_size_gb
    vnet_subnet_id      = azurerm_subnet.aks.id
    max_pods            = var.aks_max_pods
    enable_auto_scaling = var.aks_enable_auto_scaling
    min_count           = var.aks_enable_auto_scaling ? var.aks_min_count : null
    max_count           = var.aks_enable_auto_scaling ? var.aks_max_count : null
    type                = "VirtualMachineScaleSets"

    upgrade_settings {
      max_surge = "33%"
    }

    tags = merge(
      var.tags,
      {
        Environment = var.environment
      }
    )
  }

  # Identidade
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Network Profile
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    dns_service_ip    = "10.0.0.10"
    service_cidr      = "10.0.0.0/24"
    load_balancer_sku = "standard"

    load_balancer_profile {
      outbound_ip_address_ids = [azurerm_public_ip.aks.id]
    }
  }

  # Azure AD Integration
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = []
  }

  # Monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  # Add-ons
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  # Maintenance Window
  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "-03:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Saturday"
    start_time  = "02:00"
    utc_offset  = "-03:00"
  }

  # Configurações de Segurança
  local_account_disabled            = false
  role_based_access_control_enabled = true

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Name        = "${var.project_name}-${var.environment}-aks"
    }
  )

  depends_on = [
    azurerm_role_assignment.aks_network,
    azurerm_role_assignment.aks_acr
  ]
}

# Node Pool Adicional para Workloads Específicos (opcional)
resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  count                 = var.environment == "prod" ? 1 : 0
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D4s_v3"
  node_count            = 2
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = 5
  max_pods              = 30
  os_disk_size_gb       = 128
  vnet_subnet_id        = azurerm_subnet.aks.id

  node_labels = {
    "workload-type" = "application"
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      NodePool    = "workload"
    }
  )
}

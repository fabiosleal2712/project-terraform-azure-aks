# Resource Group
output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Localização do Resource Group"
  value       = azurerm_resource_group.main.location
}

# AKS Cluster
output "aks_cluster_name" {
  description = "Nome do cluster AKS"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  description = "ID do cluster AKS"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_cluster_fqdn" {
  description = "FQDN do cluster AKS"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "aks_cluster_endpoint" {
  description = "Endpoint do cluster AKS"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "aks_kube_config" {
  description = "Kubeconfig do cluster AKS"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "aks_node_resource_group" {
  description = "Resource group dos nodes do AKS"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

# Azure Container Registry
output "acr_name" {
  description = "Nome do Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Login server do ACR"
  value       = azurerm_container_registry.main.login_server
}

output "acr_id" {
  description = "ID do ACR"
  value       = azurerm_container_registry.main.id
}

# Network
output "vnet_id" {
  description = "ID da Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Nome da Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  description = "ID da subnet do AKS"
  value       = azurerm_subnet.aks.id
}

output "public_ip_address" {
  description = "Endereço IP público do Load Balancer"
  value       = azurerm_public_ip.aks.ip_address
}

# Monitoring
output "log_analytics_workspace_id" {
  description = "ID do Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Nome do Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key do Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string do Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

# Identity
output "aks_identity_principal_id" {
  description = "Principal ID da identidade gerenciada do AKS"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "aks_identity_client_id" {
  description = "Client ID da identidade gerenciada do AKS"
  value       = azurerm_user_assigned_identity.aks.client_id
}

# Comandos úteis
output "connect_to_aks" {
  description = "Comando para conectar ao cluster AKS"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "acr_login_command" {
  description = "Comando para login no ACR"
  value       = "az acr login --name ${azurerm_container_registry.main.name}"
}
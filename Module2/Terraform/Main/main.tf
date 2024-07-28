# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.106.1, < 4.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "arg" {
  name     = var.AKS_RESOURCE_GROUP
  location = "East US"
}

resource "azurerm_storage_account" "storage" {
  name                      = var.STORAGE_ACCOUNT_NAME
  location                  = "East US"
  resource_group_name       = var.AKS_RESOURCE_GROUP
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  access_tier               = "Hot"
  enable_https_traffic_only = true
  depends_on = [
    azurerm_resource_group.arg
  ]
}


resource "azurerm_container_registry" "acr" {
  name                = var.ACR
  location            = "East US"
  resource_group_name = var.AKS_RESOURCE_GROUP
  sku                 = "Standard"
  admin_enabled       = false
  depends_on = [
    azurerm_resource_group.arg
  ]
}

resource "azurerm_kubernetes_cluster" "aks" {

  name                 = var.AKS_CLUSTER
  location             = "East US"
  resource_group_name  = var.AKS_RESOURCE_GROUP
  dns_prefix           = var.AKS_CLUSTER
  azure_policy_enabled = true

  default_node_pool {
    name                = "systempool"
    node_count          = 1
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
    vm_size             = "Standard_D2as_v5"
    zones               = ["1"]
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id
  }

  network_profile {
    network_plugin     = "azure"
    network_plugin_mode = var.network_plugin_mode
  }
  auto_scaler_profile {
    scale_down_unneeded         = "1m"
    scale_down_delay_after_add  = "1m"
    scale_down_unready          = "1m"
    skip_nodes_with_system_pods = true
  }

  depends_on = [
    azurerm_resource_group.arg
  ]
}

resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

resource "azurerm_kubernetes_cluster_node_pool" "linuxnp" {
  name                  = "linuxagent1"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  os_type               = "Linux"
  node_count            = 1
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = 3
  mode                  = "User"
  vm_size               = "Standard_D2as_v5"
  zones                 = ["1"]
}

resource "azurerm_kubernetes_cluster_node_pool" "winnp" {
  name                  = "win1"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  os_type               = "Windows"
  node_count            = 1
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = 3
  mode                  = "User"
  vm_size               = "Standard_D2as_v5"
  zones                 = ["1"]
}


resource "azurerm_monitor_diagnostic_setting" "diagnostic_logs" {
  name               = var.DIAGNOSTIC_SETTING_NAME
  target_resource_id = azurerm_kubernetes_cluster.aks.id
  storage_account_id = azurerm_storage_account.storage.id

  dynamic "log" {
    for_each = ["kube-apiserver", "kube-controller-manager", "cluster-autoscaler", "kube-scheduler", "kube-audit", "kube-audit-admin", "guard"]
    content {
      category = log.value
      enabled  = true
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

  }
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = var.LOG_ANALYTICS_WORKSPACE_NAME
  location            = "East US"
  resource_group_name = var.AKS_RESOURCE_GROUP
  sku                 = "PerGB2018"
  retention_in_days   = "90"
  
  depends_on = [
    azurerm_resource_group.arg
  ]
}

resource "azurerm_log_analytics_solution" "log_analytics" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.log_analytics.location
  resource_group_name   = azurerm_log_analytics_workspace.log_analytics.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.log_analytics.id
  workspace_name        = azurerm_log_analytics_workspace.log_analytics.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
  
  depends_on = [
    azurerm_resource_group.arg
  ]
}


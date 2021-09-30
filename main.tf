locals {
  region               = "EastUS2"
  vault_address        = "https://vault.teokyllc.internal:8200"
  argocd_address       = "argo.teokyllc.internal"
  container_registry   = "ataylor.jfrog.io"
  cert_manager_version = "v1.5.3"
  istio_version        = "1.11.2"
}

module "network-spoke" {
    source                 = "github.com/teokyllc/terraform-azure-network-spoke"
    environment_tag        = "DEV"
    spoke_label            = "Engineering"
    hub_vnet_name          = "EastUS2-MGMT-VNET"
    hub_vnet_rg            = "EastUS2-Network-Hub-RG"
    enable_remote_gateways = true
    region                 = local.region
    vnet_cidr              = "10.1.0.0/16"
    enable_public_subnet   = true
    public_subnet_name     = "public"
    public_subnet          = "10.1.0.0/24"
    app_subnet_name        = "app"
    app_subnet             = "10.1.1.0/24"
    data_subnet_name       = "data"
    data_subnet            = "10.1.2.0/24"
}
      
module "aks" {
  depends_on                   = [module.network-spoke]
  source                       = "github.com/teokyllc/terraform-azure-kubernetes-service"
  aks_subnet_name              = module.network-spoke.public_subnet_name
  aks_vnet_name                = module.network-spoke.virtual_network_name
  aks_vnet_rg                  = module.network-spoke.network_rg_name
  cluster_name                 = "test"
  dns_prefix                   = "ataylor-test"
  region                       = local.region
  resource_group               = "${local.region}-${module.network-spoke.spoke_label}-K8S-RG"
  node_admin_username          = "allan"
  node_admin_ssh_pub_key       = var.ssh_pub_key
  aks_network_plugin           = "kubenet"
  aks_service_cidr             = "10.254.0.0/24"
  aks_docker_bridge_cidr       = "10.254.1.2/32"
  aks_dns_service_ip           = "10.254.0.254"
  aks_pod_cidr                 = "10.255.0.0/16"
  cluster_node_count           = "1"
  cluster_node_vm_disk_size    = "100"
  cluster_node_vm_size         = "Standard_B2ms"
  aks_service_principal_id     = var.aks_service_principal_id
  aks_service_principal_secret = var.aks_service_principal_secret
}
    
module "cert-manager" {
  depends_on             = [module.aks]
  source                 = "github.com/teokyllc/terraform-kubernetes-cert-manager"
  aks_cluster_name       = module.aks.aks_cluster_name
  aks_cluster_rg         = module.aks.aks_rg_name
  aks_kubeconfig         = module.aks.aks_kubeconfig
  replicas               = "1"
  cert_manager_namespace = "cert-manager"
  cert_manager_version   = local.cert_manager_version
  image_path             = "ataylor.jfrog.io/quay-remote/jetstack/cert-manager-controller"
  image_tag              = local.cert_manager_version
  webhook_image_path     = "ataylor.jfrog.io/quay-remote/jetstack/cert-manager-webhook"
  webhook_image_tag      = local.cert_manager_version
  cainjector_image_path  = "ataylor.jfrog.io/quay-remote/jetstack/cert-manager-cainjector"
  cainjector_image_tag   = local.cert_manager_version
  service_account_name   = "cert-manager-service-account"
  registry_server        = local.container_registry
  registry_username      = var.registry_username
  registry_password      = var.registry_password
  vault_issuer_path      = var.vault_issuer_path
  vault_tls_cert_ca      = var.vault_tls_cert_ca
  vault_role             = var.vault_role
}

module "argocd" {
  depends_on                   = [module.cert-manager]
  source                       = "github.com/teokyllc/terraform-kubernetes-argocd"
  aks_kubeconfig               = module.aks.aks_kubeconfig
  region                       = local.region
  argo_fqdn                    = local.argocd_address
  sso_login_url                = var.sso_login_url
  sso_certificate              = var.sso_certificate
  github_app_private_key       = var.github_app_private_key
  aks_cluster_name             = module.aks.aks_cluster_name
  aks_cluster_rg               = module.aks.aks_rg_name
  argo_git_app_id              = var.argo_git_app_id
  argo_git_app_installation_id = var.argo_git_app_installation_id
  argo_aad_admin_group_id      = var.argo_aad_admin_group_id
  argo_aad_read_only_group_id  = var.argo_aad_read_only_group_id
}

module "istio" {
  depends_on                   = [module.aks]
  source                       = "github.com/teokyllc/terraform-kubernetes-istio"
  aks_kubeconfig               = module.aks.aks_kubeconfig
  istio_version                = local.istio_version
}

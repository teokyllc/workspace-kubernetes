locals {
  region             = "EastUS2"
  vault_address      = "https://vault.teokyllc.internal:8200"
  container_registry = "ataylor.jfrog.io"
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
  cluster_node_vm_size         = "Standard_B2s"
  aks_service_principal_id     = var.aks_service_principal_id
  aks_service_principal_secret = var.aks_service_principal_secret
}
    
# module "cert-manager" {
#   depends_on             = [module.aks]
#   source                 = "app.terraform.io/ANET/cert-manager/kubernetes"
#   version                = "1.0.38"
#   aks_cluster_name       = module.aks.aks_cluster_name
#   aks_cluster_rg         = module.aks.aks_rg_name
#   aks_kubeconfig         = module.aks.aks_kubeconfig
#   replicas               = "1"
#   cert_manager_namespace = "cert-manager"
#   cert_manager_version   = "v1.5.3"
#   image_path             = "ataylor.jfrog.io/quay-remote/jetstack/cert-manager-controller"
#   image_tag              = "v1.5.3"
#   webhook_image_path     = "ataylor.jfrog.io/quay-remote/jetstack/cert-manager-webhook"
#   webhook_image_tag      = "v1.5.3"
#   cainjector_image_path  = "ataylor.jfrog.io/quay-remote/jetstack/cert-manager-cainjector"
#   cainjector_image_tag   = "v1.5.3"
#   service_account_name   = "cert-manager-service-account"
#   registry_server        = local.container_registry
#   registry_username      = var.registry_username
#   registry_password      = var.registry_password
#   vault_server           = local.vault_address
#   vault_issuer_path      = "pki_int/sign/teokyllc-internal"
#   vault_tls_cert_ca      = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUhRekNDQlN1Z0F3SUJBZ0lEWXJ0Uk1BMEdDU3FHU0liM0RRRUJEUVVBTUlHeE1SMHdHd1lEVlFRRERCUmoKWVM1MFpXOXJlV3hzWXk1cGJuUmxjbTVoYkRFTE1Ba0dBMVVFQmhNQ1ZWTXhFVEFQQmdOVkJBZ01DRXRsYm5SMQpZMnQ1TVJJd0VBWURWUVFIREFsQ1lYSmtjM1J2ZDI0eEt6QXBCZ05WQkFvTUlsUmhlV3h2Y2lCRmJuUmxjbkJ5CmFYTmxJRzltSUV0bGJuUjFZMnQ1TENCTVRFTXhFVEFQQmdOVkJBc01DSE5sWTNWeWFYUjVNUnd3R2dZSktvWkkKaHZjTkFRa0JGZzF1YjI1bFFHNXZibVV1WTI5dE1CNFhEVEl4TURZeU9ERXlNVGd3TkZvWERUSTJNRFl5TnpFeQpNVGd3TkZvd2diRXhIVEFiQmdOVkJBTU1GR05oTG5SbGIydDViR3hqTG1sdWRHVnlibUZzTVFzd0NRWURWUVFHCkV3SlZVekVSTUE4R0ExVUVDQXdJUzJWdWRIVmphM2t4RWpBUUJnTlZCQWNNQ1VKaGNtUnpkRzkzYmpFck1Da0cKQTFVRUNnd2lWR0Y1Ykc5eUlFVnVkR1Z5Y0hKcGMyVWdiMllnUzJWdWRIVmphM2tzSUV4TVF6RVJNQThHQTFVRQpDd3dJYzJWamRYSnBkSGt4SERBYUJna3Foa2lHOXcwQkNRRVdEVzV2Ym1WQWJtOXVaUzVqYjIwd2dnSWlNQTBHCkNTcUdTSWIzRFFFQkFRVUFBNElDRHdBd2dnSUtBb0lDQVFEQVQyYXExOVJOR0d6WE1xMmo3Z3d1VDJwKzcra3UKa0ZicHVnaFdZMUEwM1dIYUU3dXZFemtJR2xGYlptSDJ4aTFkRUF0L3ZSMitaZGczYU9PcnlmQ0UvUUxKZGFnLwpTM0QvRFkwMW12NEt2SjlpdkhZbE1jeU1vQjdhdXBjZms3UGFVbFVlQmlQS0t2L25KM0EvSDR4d1dLMXlLTUczClZBeUROd0RRYVhmQmZTVVFmajZmU0VsQUJJMXRiT1k5UXFFU2RUdU1ma1Q1cU5SZUg3OG5hZVZVQ3dBckhuczEKT0RZMzkwdG12cE5PcThCTnd0Tk5jellHV1pqcHQvYXJKTnVocG1QdmVCSGVkVFZMUTBGMXJoY1drei9JTkZyWAprN0tXUWpPQjVUb2Fsd1J1ZmI1czN5YS9BRE1rNmN4TTZrYUZzSEVkRXQvWlVtL29zMjhFcjczZkdPSW9lRGdvCkhxRGVXU1FZTCtFaGppZmJqdUw1aTJEY1d3aGpRMWlCNEFmNmhUTVBGalhyTVBLSURpbWZWODZxY2RFNnJsaHQKWmljRnAzTUJnbXRiaEtMamRIY2l0NCsybjdVcndpNmFza0xySWp4T3pOOSt1Ym1vK0FMNmRNbElKeXpyMVJHQgplZWdPR3FjL2FBM3E1L3I1eWpaczlxMjNEREEyQWk5WTRkUmJVaVVRcUd2YmZQMkZtMU52Y2tzbHVkbnZMR0d1Cko4cTVEa3BjeTB5aVVzRkkvdktwa3hVbE1TSldzMEdFTkY5V2FEbERod3FZN1dSeS95ZEdNTFdtK0xRYTZUSUQKckxiRUZScFl3Z2lvNXg1b05PNU1iZUJaaVdnNzMzL3FGSExtY3NkZ3FiK2N4ejk5WWxiMmpnSlZGMk1ydVJwMAo1ZVkrdDRIcFA5UGNHd0lEQVFBQm80SUJZRENDQVZ3d0h3WURWUjBSQkJnd0ZvSVVZMkV1ZEdWdmEzbHNiR011CmFXNTBaWEp1WVd3d0hRWURWUjBPQkJZRUZEQ1orcFZ0bVN1Y054UExmTEM4dGgwN0sxUFVNQThHQTFVZEV3RUIKL3dRRk1BTUJBZjh3Z2VNR0ExVWRJd0VCL3dTQjJEQ0IxWUFVTUpuNmxXMlpLNXczRTh0OHNMeTJIVHNyVTlTaApnYmVrZ2JRd2diRXhIVEFiQmdOVkJBTU1GR05oTG5SbGIydDViR3hqTG1sdWRHVnlibUZzTVFzd0NRWURWUVFHCkV3SlZVekVSTUE4R0ExVUVDQXdJUzJWdWRIVmphM2t4RWpBUUJnTlZCQWNNQ1VKaGNtUnpkRzkzYmpFck1Da0cKQTFVRUNnd2lWR0Y1Ykc5eUlFVnVkR1Z5Y0hKcGMyVWdiMllnUzJWdWRIVmphM2tzSUV4TVF6RVJNQThHQTFVRQpDd3dJYzJWamRYSnBkSGt4SERBYUJna3Foa2lHOXcwQkNRRVdEVzV2Ym1WQWJtOXVaUzVqYjIyQ0EySzdVVEFUCkJnTlZIU1VFRERBS0JnZ3JCZ0VGQlFjREFUQU9CZ05WSFE4QkFmOEVCQU1DQVFZd0RRWUpLb1pJaHZjTkFRRU4KQlFBRGdnSUJBR3lreWVWQ3hBcURGcXZ4bXpYcDhBYmtqbE43eWpKVmtqUjZDSlV2Y0NEd3BuMUxhakpGSlpBQwpEbWlCWUpmTExtQ0FWdnFnb01vYnd6a1JpQWk3cXAxV2hFamJOZlJlUVBpS2hZYjRzVXFPazFQbzRhR2UwandWCkVZR0xHeHZGK0Ntakd0RVMyVk1QM3RQOExFYXN6aGtlNjFncEFEdEdvMVBKZU5kcUhjVW1Pc29Qd2Znb0c4OTYKNVFPMmM3RkV5YUNlNzBvdHZ5VWhEcHVvR2dHamV4NElFTklTNFc0UzJjT0haTTFEUFpCelA0cUNWa2JjM245aQo1WHhGRU4ySWd2NzRzSmVzclV3UU14QU5zdzVUV05Mdjlja2p3anlWdU5qUDlZckROdXBraVR6R0pTTGF3RURxCjZhYlpSbkpOOStqaC9MWjNES2JFU2c4cGFUY09CVFBBamxySW1TbmkvSFRTZ0Jna2JBNmpXT3JYdTc0ZU5CUHgKYW1EMm14RGtRaFFNcEhHa3hNZGVxVzhLQnBqc29BWXpua1RReHFJV3FZUjkvU2JPNXJMN3VybURGdll4OTFudgpndHNPV1ZiZWl4RDRnbHgrMTRJbkx4Q2NKLzNQV0kvajJnN0JUTDlqVk9uWFFJOTZLTlNQUWV2eFpHZ3pnR0ZBCmxMeENPR0RRS2tjdGlIeFlHQzJXY0p6amFNaUNublI3RmZyMnptWDlLY3hCNWtieVJUdUp1UU9ibm5sRHpucloKWDhmdTZWa2xiWk0waDBkVVlUZDEzRk82OW5oWWNPLzdwUHVOMDZNamNjekVCdUlDNFZTK1Zaek5aNFBDWmlUQQpndVJ0bXBTa1dQR3NPb205Ly93YkY5RFlYQlprWWJ1bmd2WHV3U0paNzVmaUtmNHErUGlHCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
#   vault_role             = "pki_int"
#   vault_token            = var.vault_token
# }

# module "argocd" {
#   depends_on                   = [module.cert-manager]
#   source                       = "app.terraform.io/ANET/argocd/kubernetes"
#   version                      = "1.0.26"
#   aks_kubeconfig               = module.aks.aks_kubeconfig
#   region                       = local.region
#   argo_fqdn                    = "argo.teokyllc.internal"
#   vault_token                  = var.vault_token
#   sso_login_url                = "https://login.microsoftonline.com/5ad90dc5-b02a-4f06-8f90-14d6bccf9282/saml2"
#   sso_certificate              = var.sso_certificate
#   #github_app_private_key       = var.github_app_private_key
#   aks_cluster_name             = module.aks.aks_cluster_name
#   aks_cluster_rg               = module.aks.aks_rg_name
#   argo_git_app_id              = "116304"
#   argo_git_app_installation_id = "17064473"
#   argo_aad_admin_group_id      = "271497d3-a118-449a-a877-acb02e4fda52"
#   argo_aad_read_only_group_id  = "fabfdbaf-7b2e-4d8a-ab5f-e4bcc65f3e7f"
# }

####
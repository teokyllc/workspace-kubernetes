variable "subscription_id" {
    type = string
    description = "The Azure subscription id."
}

variable "aad_tenant_id" {
    type = string
    description = "The Azure AD tenant id."
}

variable "client_id" {
    type = string
    description = "The Azure service principal client id."
}

variable "client_secret" {
    type = string
    description = "The Azure service principal client secret."
}

variable "aks_service_principal_id" {
    type = string
    description = "The Azure service principal client id used by the AKS service."
}

variable "aks_service_principal_secret" {
    type = string
    description = "The Azure service principal client secret used by the AKS service."
}

variable "ssh_pub_key" {
    type = string
    description = "The SSH public key to access AKS nodes."
}

variable "registry_server" {
    type = string
    description = "The private container register URL."
}

variable "registry_username" {
    type = string
    description = "The private container register username."
}

variable "registry_password" {
    type = string
    description = "The private container register password."
}

variable "vault_issuer_path" {
    type = string
    description = "The private container register password."
}

variable "vault_tls_cert_ca" {
    type = string
    description = "The private container register password."
}

variable "vault_role" {
    type = string
    description = "The private container register password."
}

# variable "sso_certificate" {
#     type = string
#     description = "The Azure AD SAML certificate for the app."
# }

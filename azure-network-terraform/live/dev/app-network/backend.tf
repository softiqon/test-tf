# Partial backend config: terraform init -backend-config=backend.hcl
terraform {
  backend "azurerm" {
    use_azuread_auth = true
  }
}

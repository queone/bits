---
type: howto
---
## Terraform to Vault From Azure

Terraform on an Azure virtual machine can log in to [HashiCorp Vault](https://developer.hashicorp.com/vault) with the VM's [managed identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview). No Vault token or client secret then sits on the machine. Vault's [Azure auth method](https://developer.hashicorp.com/vault/docs/auth/azure) trusts a token that [Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/fundamentals/what-is-entra) issued to that identity, and the Terraform provider fetches the token by itself. The last step does the same from a GitHub Actions job, which has no VM.

### 1. Enable the Azure auth method in Vault

```bash
vault auth enable azure
vault write auth/azure/config \
  tenant_id="<TENANT_ID>" \
  resource="https://management.azure.com/" \
  client_id="<CLIENT_ID>" \
  client_secret="<CLIENT_SECRET>"
```

The client here is an app registration Vault uses to look up the VM in Azure. Give it the Reader role on the subscription. `resource` must equal the `aud` claim of the tokens Vault will receive.

### 2. Create a role bound to the VM's subscription and resource group

```bash
vault write auth/azure/role/terraform-vm \
  bound_subscription_ids="<SUBSCRIPTION_ID>" \
  bound_resource_groups="<RESOURCE_GROUP>" \
  token_policies="terraform" \
  token_ttl="1h"
```

### 3. Give the VM a system-assigned managed identity

```bash
az vm identity assign --resource-group <RESOURCE_GROUP> --name <VM_NAME>
```

### 4. Point the Terraform provider at the role

```hcl
provider "vault" {
  address = "https://vault.mydomain.com:8200"
  auth_login_azure {
    role                = "terraform-vm"
    subscription_id     = "<SUBSCRIPTION_ID>"
    resource_group_name = "<RESOURCE_GROUP>"
    vm_name             = "<VM_NAME>"
  }
}
```

With no `jwt` set, the [provider](https://registry.terraform.io/providers/hashicorp/vault/latest/docs) asks the VM's managed identity for a token and sends it to `auth/azure/login`. To see that token by hand, ask the [Instance Metadata Service](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-to-use-vm-token) directly:

```bash
curl -s -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F" | jq -r .access_token
```

### 5. Same login from a GitHub Actions job

A job has no VM. Instead, [oidctok](https://github.com/queone/gkit/tree/main/cmd/oidctok) trades the job's GitHub token for an Entra token issued to an app registration. The setup is in [GitHub Actions to Azure with OIDC](../git/oidc-azure.md). That token is for Azure Resource Manager too, so a role bound to the app's service principal accepts it:

```bash
vault write auth/azure/role/terraform-github \
  bound_service_principal_ids="<SP_OBJECT_ID>" \
  token_policies="terraform" \
  token_ttl="1h"
```

`<SP_OBJECT_ID>` is the object ID of the enterprise application, not the client ID. The job needs `permissions: id-token: write`. It logs in with the token and hands the Vault token to the provider through `VAULT_TOKEN`:

```yaml
- run: go install github.com/queone/gkit/cmd/oidctok@latest
- run: oidctok
  env:
    CLIENT_ID: ${{ vars.CLIENT_ID }}
    TENANT_ID: ${{ vars.TENANT_ID }}
- run: |
    VAULT_TOKEN=$(curl -s -X POST "$VAULT_ADDR/v1/auth/azure/login" \
      -d "{\"role\":\"terraform-github\",\"jwt\":\"$AZ_TOKEN\"}" | jq -r .auth.client_token)
    echo "::add-mask::$VAULT_TOKEN"
    echo "VAULT_TOKEN=$VAULT_TOKEN" >> "$GITHUB_ENV"
  env:
    VAULT_ADDR: https://vault.mydomain.com:8200
- run: terraform apply
```

If Vault rejects the login with an audience error, decode the token. Set `resource` in step 1 to its `aud` value. The other route for a job, Vault's JWT method with GitHub as the issuer, is in [GitHub Actions to Vault with OIDC](../git/oidc-vault.md).

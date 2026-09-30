---
type: reference
---
## Github Workflow OIDC Access to Vault
To connect to HashiCorp Vault from GitHub Actions using **OIDC (OpenID Connect)**, you can leverage the `hashicorp/vault-action` to simplify the process. OIDC allows your workflow to authenticate to Vault without managing long-lived credentials, making it secure and ideal for CI/CD pipelines.


### Prerequisites
1. **Vault Configuration for OIDC Authentication**:
   - Ensure your Vault instance is configured to use OIDC with GitHub as the trusted identity provider (IDP).

   Example Vault policy and role configuration:
   ```hcl
   # Create an OIDC role for GitHub Actions
   vault write auth/jwt/role/github-actions \
       bound_issuer=https://token.actions.githubusercontent.com \
       user_claim=repository \
       bound_claims_format=glob \
       bound_claims={"repository":"<your_org_or_repo>/*"} \
       token_policies=github-actions-policy \
       ttl=1h

   # Define the policy to grant access
   vault policy write github-actions-policy - <<EOF
   path "some/path/github/sub/folder/*" {
     capabilities = ["read"]
   }
   EOF
   ```

2. **Vault OIDC URL**:
   - Use the OIDC discovery URL from GitHub: `https://token.actions.githubusercontent.com`.

3. **Enable the JWT Auth Method in Vault**:
   - Enable the `jwt` auth method in Vault:
     ```bash
     vault auth enable jwt
     ```


### GitHub Actions Workflow with OIDC*
Below is an example GitHub Actions workflow to authenticate to Vault using OIDC:

```yaml
name: Retrieve Secret from Vault with OIDC

on:
  workflow_dispatch:

jobs:
  oidc-to-vault:
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # Required for OIDC
      contents: read   # Default read permissions
    steps:

      - name: Retrieve Vault Objects
        uses: hashicorp/vault-action@3
        with:
          url: https://vault.example.com
          method: jwt
          path: jwt_mypath
          role: my-github-actions
          secrets: |
            some/data/path/github/sub/folder/target-object Field_Within_Object | MYSECRET1 ;

      - name: Use the secret
        run: |
          printf "MYSECRET1 hint = ${MYSECRET1:0:4}"
```

### Key Details
1. **OIDC Token Permissions**:
   - In the `permissions` block, set:
     ```yaml
     permissions:
       id-token: write
     ```
     This allows GitHub Actions to request an OIDC token to authenticate with Vault.

2. **`hashicorp/vault-action` Configuration**:
   - The `method: oidc` input specifies OIDC authentication.
   - `role: my-github-actions` maps to the Vault role created earlier (`auth/jwt/role/github-actions`).
   - Secrets mapping works the same way as in other Vault authentication methods.

3. **OIDC Authentication**:
   - The action fetches an OIDC token from GitHub's identity provider (`https://token.actions.githubusercontent.com`) and uses it to authenticate with Vault.

### Vault Setup Recap
To recap, ensure the following is configured in Vault:
1. Enable the JWT/OIDC auth method:
   ```bash
   vault auth enable jwt
   ```

2. Write the GitHub OIDC role:
   ```bash
   vault write auth/jwt/role/my-github-actions\
       bound_issuer=https://token.actions.githubusercontent.com \
       user_claim=repository \
       bound_claims_format=glob \
       bound_claims={"repository":"<your_org_or_repo>/*"} \
       token_policies=github-actions-policy \
       ttl=1h
   ```

3. Define the necessary Vault policy:
   ```hcl
   path "some/path/github/sub/folder/*" {
     capabilities = ["read"]
   }
   ```

### Benefits of Using OIDC
1. **No Long-Lived Tokens**:
   - OIDC uses short-lived JWTs for secure, ephemeral authentication.

2. **Granular Access**:
   - You can scope the Vault role to specific repositories, branches, or workflows using `bound_claims`.

3. **Seamless GitHub Integration**:
   - Works directly with GitHub’s identity provider, simplifying the setup.


**Reference**
- [Terraform to Vault From Azure](../terraform/vault-from-azure.md): the same login through Vault's Azure auth method, from a VM or from a job via oidctok
- [Configuring OpenID Connect in HashiCorp Vault](https://docs.github.com/en/enterprise-cloud@latest/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-hashicorp-vault)

  

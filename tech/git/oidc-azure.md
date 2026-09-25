---
type: reference
---
## Github Workflow OIDC Access to Azure

OIDC allows workflows to authenticate and interact with Azure using short-lived tokens. This removes the need for long-lived personal access tokens (PATs) or a service principal with a secret. It is a more secure and manageable way to reach cloud resources directly from GitHub Actions.

### How It Works
1. **Configuration**: You configure your Azure AD App Registration to trust an external identity provider by setting up a federation with that IdP. This involves specifying details about the IdP, such as the issuer URL, and possibly uploading metadata documents for SAML-based federations.

2. **Authentication Flow**: A user or service attempts to access an application protected by Azure AD and is redirected to sign in. Instead of presenting Azure AD credentials, the user or service presents credentials from the federated IdP. The federated IdP authenticates the user or service and issues a token. This token is presented to Azure AD, which validates it based on the trust configuration. Upon successful validation, Azure AD issues its own token to the user or service, granting access to the application.

### Setting Up
1. Enable OIDC in Azure
    - You still need an App Registration and Service Principal
    - Assign it the required Azure RBAC and Entra roles, at the required scope, to be able to do what you want it to do
    - But instead of configuring a **secret**, you configure a "federated" credential
    - [Configure a federated identity credential on an app](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#github-actions)
    - click "Certificates & secrets" -> "Federated credentials", and "Add credential" and select "Github Actions deploying Azure resources"
    - Enter the Github Organization
    - The Github Repository name
    - The Entity type = "Branch"
    - And Based on selection = "main", or whatever that may be

2. Set below variables as secrets in your GitHub repository:
    - AZURE_AD_APPLICATION_CLIENT_ID: The client ID of the Azure AD application
    - AZURE_TENANT_ID: Your Azure tenant ID
    - AZURE_SUBSCRIPTION_ID: Your Azure subscription ID (may not be needed)

3. Setup a workflow that authenticates to Azure using OIDC, does something useful
    - Can be used with [Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc)
    - Requires azurerm provider version 3.7.0 or higher
    - Azure CLI is set up with the token automatically, of course
    - Terraform picks up the token automatically also
    - Anything running within the Github Action job can use Azure CLI to get respective API tokens, as shown below
    - Example OIDC Github Action job using Azure CLI:

    ```yaml 
      permissions:
        id-token: write  # This is required for requesting the JWT
        contents: read   # This is required for actions/checkout

      jobs:
        task_leveraging_oidc_login:
          runs-on: ubuntu-latest
          steps:

            - name: checkout_github_action_code
              uses: actions/checkout@v4
              with:
                ref: main

            # Option 1: Using azure-cli
            - name: azure_oidc_login
              uses: azure/login@v1
              with:
                client-id: ${{secrets.CLIENT_ID}}
                tenant-id: ${{secrets.TENANT_ID}}
                allow-no-subscriptions: true  

            - name: capture_azure_tokens
              run: |
                # https://learn.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-get-access-token
                # [--resource-type {aad-graph, arm, batch, data-lake, media, ms-graph, oss-rdbms}]
                export MG_TOKEN="$(az account get-access-token --resource-type ms-graph --query accessToken -o tsv)"
                export AZ_TOKEN="$(az account get-access-token --resource-type arm --query accessToken -o tsv)"
                echo "MG_TOKEN=$MG_TOKEN" >> $GITHUB_ENV  # To use in another step 
                echo "AZ_TOKEN=$AZ_TOKEN" >> $GITHUB_ENV
                curl -sH "Content-Type: application/json" -H "Authorization: Bearer ${AZ_TOKEN}" -X GET "https://management.azure.com/subscriptions?api-version=2022-12-01" | jq

            # Option 2: Using the oidctok binary (RECOMMENDED)
            - name: install_oidctok
              run: go install github.com/queone/gkit/cmd/oidctok@latest

            # Appends AZ_TOKEN and MG_TOKEN to GITHUB_ENV, so every later step sees them
            - name: get_azure_tokens
              run: oidctok
              env:
                CLIENT_ID: ${{secrets.CLIENT_ID}}
                TENANT_ID: ${{secrets.TENANT_ID}}

            # Option 3: Using the Python script
            # See https://github.com/queone/gkit/blob/main/scripts/get_oidc_tokens.py

            - name: some_other_step
              run: |
                curl -sH "Content-Type: application/json" -H "Authorization: Bearer ${{env.MG_TOKEN}}" -X GET "https://graph.microsoft.com/v1.0/users" | jq
    ```

### Overview

A Github workflow action can be setup to You can - Using Azure as a sample cloud provider
- At high level
  - Create a role on AWS, add trust policy specifying which github Organization + Repo are allowed to access this AWS role
  - Create an identity provider for github actions
  - Use the setup-aws action, specify the role and it will take care of the rest
- At lowel level:
  - Github spins up an Action with your pipeline code
  - Every action job comes with a token as an environment variable for authenticated calls to github
  - You send a post request to github, asking for a “web identity token“
  - You send this token to AWS, exchanging it for (you guest it) a pair of keys and session token
  - You use this set of keys to authenticate with AWS services as normal
- Notes:
  - The key point is that the JWT token is signed by github and its content can be verified by AWS using github’s public key
  - The token also contains scopes such as organization, repo, branch, that AWS can either grant or deny access to

### OIDC Flow Diagram

```bash
GitHub             GitHub Workflow Action             Microsoft
│                           │                             │
│   1. Give me JWT token    │                             │
│ ◄──────────────────────── │                             │
│                           │                             │
│   2. Returns JWT token    │                             │
│ ────────────────────────► │                             │
│                           │                             │
│                           │                             │
│                           │  3. Give me Azure ARM       │
│                           │     and MS Graph tokens     │
│                           │ ──────────────────────────► │
│                           │                             │
│                           │  4. Returns each token      │
│                           │ ◄────────────────────────── │
                            │                             
                            │                             
MS Graph                    │                         Azure ARM
│                           │                             │
│   5. Update MS Graph X    │                             │
│      object using token   │                             │
│ ◄──────────────────────── │                             │
│                           │                             │
│   6. Update done          │                             │
│ ────────────────────────► │                             │
│                           │                             │
│                           │  7. Update Azure ARM X      │
│                           │     object using token      │
│                           │ ──────────────────────────► │
│                           │                             │
│                           │  8. Update done             │
│                           │ ◄────────────────────────── │
```

### References
- [oidctok README](https://github.com/queone/gkit/blob/main/cmd/oidctok/README.md)
- [Python option: get_oidc_tokens.py](https://github.com/queone/gkit/blob/main/scripts/get_oidc_tokens.py)
- [What is Github Action for Azure](https://learn.microsoft.com/en-us/azure/developer/github/github-actions) 
- [Configuring OpenID Connect in Azure](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure)
- [Azure login action](https://github.com/marketplace/actions/azure-login)
- [Configuring OpenID Connect in cloud providers](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-cloud-providers)
- [OpenID Connect on the Microsoft identity platform](https://learn.microsoft.com/en-us/entra/identity-platform/v2-protocols-oidc)
- [Create ASCII Diagrams](https://asciiflow.com/#/)


### Using OIDC for Authentication with Azure

This document explains how **OpenID Connect (OIDC)** authentication works between a program (like a GitHub workflow) and Azure. It also covers what it takes for any program to be trusted by Azure.

---

### 1. How GitHub Workflows Use OIDC to Authenticate with Azure

When a GitHub workflow authenticates with Azure, it follows these steps:

1. **Acquire an OIDC Token from GitHub**:
   - GitHub Actions generates an OIDC token for the workflow run. This token contains claims about the workflow (e.g., repository, branch, job name) and is signed by GitHub's private key.

2. **Present the OIDC Token to Azure**:
   - The workflow uses the OIDC token to request an **Azure access token** from Microsoft Identity Platform (formerly Azure AD).

3. **Azure Validates the OIDC Token**:
   - Azure verifies the OIDC token's signature using GitHub's public key (which it trusts).
   - Azure checks the token's claims against the **federated identity configuration** set up in Azure AD. This configuration defines which GitHub repositories, branches, or workflows are allowed to assume specific Azure roles.

4. **Azure Issues an Access Token**:
   - If the OIDC token is valid and the claims match the configuration, Azure issues an access token to the workflow. This access token allows the workflow to perform actions in Azure based on the assigned permissions.


### 2. Can Any Program Do the Same?

Yes, **any program** can use OIDC to authenticate with Azure, provided it meets the following requirements:

#### a. The Program Must Be Able to Generate an OIDC Token
   - The program must act as an **OIDC identity provider** or integrate with one. For example:
     - GitHub Actions generates OIDC tokens for workflows.
     - Other CI/CD tools (e.g., GitLab, Jenkins) or custom programs can also generate OIDC tokens if they implement the OIDC standard.
   - The OIDC token must include the necessary claims (e.g., issuer, subject, audience) that Azure can validate.

#### b. Azure Must Trust the OIDC Token Issuer
   - Azure AD must be configured to trust the OIDC token issuer (e.g., GitHub, GitLab, or your custom issuer).
   - This involves:
     1. **Registering the Issuer's Public Key**:
        - Azure needs the public key of the OIDC token issuer to verify the token's signature.
     2. **Configuring a Federated Identity**:
        - In Azure AD, you create a **federated identity credential**. It maps the OIDC token's claims, such as issuer and subject, to an Azure AD application or service principal.

#### c. The Program Must Have the Correct Configuration in Azure AD
   - The program's OIDC token must include claims that match the federated identity configuration in Azure AD.
   - For example:
     - The `issuer` claim must match the trusted issuer (e.g., `https://token.actions.githubusercontent.com` for GitHub).
     - The `subject` claim must match the expected value (e.g., `repo:<org/repo>:ref:refs/heads/main` for a specific GitHub repository and branch).

---

### 3. What Makes Azure Trust the GitHub OIDC Token?

Azure trusts the GitHub OIDC token because:

1. **GitHub's Public Key is Trusted**:
   - Azure has GitHub's public key and uses it to verify the token's signature.

2. **Federated Identity Configuration**:
   - Azure AD is configured to trust tokens from GitHub's OIDC issuer (`https://token.actions.githubusercontent.com`).
   - The federated identity configuration specifies which GitHub repositories, branches, or workflows are allowed to assume specific roles in Azure.

3. **Token Claims Match the Configuration**:
   - The OIDC token's claims (e.g., `issuer`, `subject`, `audience`) match the conditions defined in the federated identity configuration.

---

### 4. What Does It Take for Any Program to Be Trusted by Azure?

For any program to be trusted by Azure, you need to:

1. **Set Up the Program as an OIDC Identity Provider**:
   - The program must generate OIDC tokens that comply with the OIDC standard.
   - The tokens must include the necessary claims (e.g., `issuer`, `subject`, `audience`).

2. **Register the Program's Public Key in Azure AD**:
   - Azure AD needs the public key of the program's OIDC token issuer to verify the token's signature.

3. **Configure Federated Identity in Azure AD**:
   - Create a federated identity credential in Azure AD that maps the program's OIDC token claims to an Azure AD application or service principal.
   - Define the conditions under which the program is allowed to assume roles (e.g., specific `issuer`, `subject`, `audience` values).

4. **Ensure the Program's OIDC Token Meets Azure's Requirements**:
   - The token must include the correct claims and be signed with the program's private key.

---

### 5. Example: Custom Program Using OIDC with Azure

If you want to write a custom program that uses OIDC to authenticate with Azure, here’s what you’d do:

1. **Generate an OIDC Token**:
   - Use an OIDC library (e.g., for Go, Python, or Node.js) to generate a signed OIDC token.
   - Include the required claims (`issuer`, `subject`, `audience`, etc.).

2. **Register Your Program in Azure AD**:
   - Create an Azure AD application or service principal.
   - Add a federated identity credential that maps your program's OIDC token claims to the Azure AD application.

3. **Configure Azure to Trust Your Program**:
   - Provide Azure AD with your program's public key for token verification.
   - Define the conditions under which your program is allowed to authenticate (e.g., specific `issuer` and `subject` values).

4. **Use the OIDC Token to Authenticate with Azure**:
   - Present the OIDC token to Microsoft Identity Platform to request an Azure access token.
   - Use the access token to interact with Azure resources.

### Requirements

- **Any program** can use OIDC to authenticate with Azure, provided it generates valid OIDC tokens and Azure is configured to trust the token issuer.
- Azure trusts GitHub's OIDC tokens because:
  - GitHub's public key is trusted.
  - The federated identity configuration in Azure AD matches the token's claims.
- To make Azure trust your custom program, you need to:
  - Set up your program as an OIDC identity provider.
  - Register your program's public key in Azure AD.
  - Configure federated identity credentials in Azure AD.


### Roles in the OIDC Flow

In the OIDC authentication flow between GitHub and Azure, **GitHub** acts as the **Identity Provider (IdP)**. **Azure** acts as the **Relying Party (RP)**, also called the **Service Provider (SP)**.

- **GitHub's Role**:
  - Issues OIDC tokens for workflow runs, containing claims about the workflow (e.g., repository, branch, job name).
  - Signs the OIDC token using its private key to ensure authenticity.
  - Exposes a discovery endpoint (e.g., `https://token.actions.githubusercontent.com/.well-known/openid-configuration`) for Azure to retrieve public keys and configuration details.
  - Is trusted by Azure to issue valid OIDC tokens for federated identity scenarios.

- **Azure's Role**:
  - Validates the OIDC token's signature using GitHub's public key and checks its claims (e.g., `issuer`, `subject`, `audience`) against the configured federated identity credentials.
  - Issues an **access token** to the GitHub workflow if the OIDC token is valid, enabling interaction with Azure resources.
  - Enforces **Role-Based Access Control (RBAC)** by mapping the OIDC token's claims to specific roles or permissions in Azure AD (e.g., contributor, reader).

#### Why This Works
- **Trust**: Azure trusts GitHub to issue valid OIDC tokens because GitHub's public keys are registered in Azure AD.
- **Security**: The OIDC token is signed and contains claims that Azure validates, ensuring only authorized workflows can access Azure resources.
- **Automation**: This flow enables secure, automated authentication for CI/CD pipelines without the need for long-lived secrets.

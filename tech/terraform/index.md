---
type: reference
---
## Terraform
Bits on [Hashicorp Terraform](https://developer.hashicorp.com/terraform).

It is an open-source tool for provisioning and managing cloud infrastructure as code ([IaC](https://en.wikipedia.org/wiki/Infrastructure_as_code)). It codifies infrastructure in configuration files that describe the desired state for your topology. Terraform enables the management of any infrastructure - such as public clouds, private clouds, and SaaS services by using [Terraform providers](https://developer.hashicorp.com/terraform/language/providers). Each provider adds a set of resource types and/or data sources that Terraform can manage.

Side note


### Module Definitions
1. A Terraform module is a container for multiple resources that are used together, allowing for reuse, simplification, and management of Terraform configurations.
2. One thing to remember about a terraform module is that it should be for a _composite of resources_, not a single resource.


### Moving Resources in Terraform State
1. First you have to update your infrastructure files, but before running `terraform apply`, do the following:
2. Below command will print of list ot lines to check for moving desired resources:
```bash
temp1=$(mktemp) && temp_from=$(mktemp) && temp_to=$(mktemp) && \
terraform plan | grep "will be" > "$temp1" && \
grep destroyed "$temp1" | awk '{print $3}' | sed "s/.*/'&'/" > "$temp_from" && \
grep created "$temp1" | awk '{print $3}' | sed "s/.*/'&'/" > "$temp_to" && \
paste -d' ' "$temp_from" "$temp_to" | sed "s;^;terraform state mv -dry-run ;" && \
rm "$temp1" "$temp_from" "$temp_to"
```
3. **Carefully** inspect and run each `terraform state mv -dry-run From To` line that is printed above to make 100% sure it's what you want.
4. Remove the `-dry-run` in each line and re-run to move the resource.
5. After doing all the moves, you can do a `terraform plan` and a `terraform apply` to confirm everything is good.

#### Moving Terraform-managed Azure resources from one Resource Group to another (OLD)
See <https://stackoverflow.com/questions/69283041/terraform-move-entire-resource-group-to-new-azure-subscription>

*First*, you'll need to confirm the resource can actually be moved via the portal, by actually attempting to do the move.

If you were able to move it, now you can proceed by getting a list of all respective IDs from the TF state: 

```bash
terraform state pull | grep "<RG-NAME>"
<LIST of IDs>
```

You'll also need to list their addresses with `terraform state list`

Next, carefully remove each of the respective resources using their addresses, for example: 

```bash
terraform state rm azurerm_dns_zone.mydomain
terraform state rm azurerm_dns_a_record.mydomain-apex
terraform state rm azurerm_dns_cname_record.mydomain-www
```

Now import the new ones, using the IDs from the LIST of IDs command above and changing the resource group nane, for example: 

```bash
terraform import azurerm_dns_zone.mydomain "/subscriptions/<UUID>/resourceGroups/<NEW-RG-NAME>/providers/Microsoft.Network/dnsZones/mydomain.com"
terraform import azurerm_dns_a_record.mydomain-apex "/subscriptions/<UUID>/resourceGroups/<NEW-RG-NAME>/providers/Microsoft.Network/dnsZones/mydomain.com/A/@"
terraform import azurerm_dns_cname_record.mydomain-www "/subscriptions/<UUID>/resourceGroups/<NEW-RG-NAME>/providers/Microsoft.Network/dnsZones/mydomain.com/CNAME/www"
```


### Terraform Workflow
Below ASCII diagram depicts the typical Terraform workflow: 
 
```text
                         Update code
                        ┌───────────────┐
                        ▼               │
     ┌────────┐     ┌────────┐     ┌────┴────┐     ┌──────────┐
     │        │     │        │     │         │     │          │
     │  init  ├────►│  plan  │     │  apply  ├────►│ destroy  │
     │        │     │        │     │         │     │          │
     └────────┘     └───┬────┘     └─────────┘     └──────────┘
                        │               ▲
                        └───────────────┘
                         Deploy infra
```

### Manage Azure With Terraform
- These particular instructions assume you will be managing your Azure tenant from an Apple Mac host, using BASH as a shell terminal
- Of course you can do the same on a Windows host running GitBASH, or a Linux host using regular BASH, making the necessary adjustments
- Install Terraform and Azure CLI on *macOs*: 

  ```bash
  brew tap hashicorp/tap
  brew install hashicorp/tap/terraform
  brew install azure-cli
  ```

- Create a new, private source code repository in your SCM system and call it "mytf"
- This repo will hold `main.tf` and all other Infrastructure-as-Code Terraform configuration files
- Use <https://github.com/github/gitignore/blob/main/Terraform.gitignore> to avoid checking in the wrong files
- Create a new Service Principal (SP) in your Azure tenant and let's call it `azuretf-sp00` 
- Create a new Azure AD group called `az-terraform-management` and make above SP a member of it 
- You will need to grant above AZ group all required RBAC permissions to allow Terraform to deploy and managed the specific services you wish to manage
- Managing access with an AZ group instead of doing assignments directly to a single SP is a good industry practice.
- Capture and set below 4 parameters accordingly: 

```bash
export ARM_SUBSCRIPTION_ID="<azure_subscription_id>"
export ARM_TENANT_ID="<azure_subscription_tenant_id>"
export ARM_CLIENT_ID="<service_principal_appid>"
export ARM_CLIENT_SECRET="<service_principal_password>"
```
- WARNING! Exposing an SP secret as a BASH variable is poor security, and should only be done for testing. For a production system you would do this in a more secure fashion, typically using a secrets manager such as HashiCorp Vault, Azure Key Vault, or even Github repository secrets.
 
- Manually via the Azure portal create an Azure Storage Account (SA) to have Terraform store its "state" there. Or you can do so from the shell terminal, using Azure CLI tool :

```bash
    az group create --name mytfstates --location eastus
    az storage account create --resource-group mytfstates --name mytf --sku Standard_LRS --encryption-services blob
```
- NOTE: Another way to store TF state is to use Terraform Cloud (https://cloud.hashicorp.com/products/terraform), which is a paid service 
- Next, create a container within this storage account and set up its access key password: 

```bash
    az storage container create --name mytfstate --account-name mytf
    az storage account keys list --resource-group mytfstates --account-name mytf --query '[0].value' -o tsv
    export ARM_ACCESS_KEY="use_above_storage_account_container_access_key"
```

- WARNING! Again, exposing secrets via BASH variables is poor security, and should only be done for testing. For production systems make sure you do this more securely.
- Checkout/clone mytf repo mentioned above and create `main.tf` with these recommended initial values: 

```hcl
# main.tf

terraform {
  required_version = ">= 1.3.2"
  
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  backend "azurerm" {
    resource_group_name  = "mytfstates"
    storage_account_name = "mytf"
    container_name       = "mytfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {
  }
}
```

- Create a test Resource Group as an example of how to use TF to create Azure resources
- Create file `rg-myaz01.tf`: 
```hcl
    resource "azurerm_resource_group" "my-test-rg" {
        name     = "my-test-rg01"
        location = "eastus"
    }
```
- Run `terraform plan` to see what TF will do
- Run `terraform apply` to do it (that is, deploy above new test resource group)
- Note that TF scans all `*.tf` files in this working repo when you do scan/apply
- Keep in mind that TF may not be able to create the intended resources if SP `azuretf-sp00` doesn't have the right Azure privileges
- You will need to grant those privileges carefully, using AZ group `az-terraform-management` and at the proper scope within your tenant
- You can use `terraform import` to import existing resources into the TF state
- Bear in mind that that `import` does *NOT* create a configuration file. In fact, in order to import an existing resource, you *MUST* first create a minimalist config file for that resource, that TF needs to reference the importing function
- After import, run `terraform state list` to locate the imported resource names
- Next, do `terraform state show <imported-resource-type.name>` to show full details
- You can then recreate the minimalist config file, based on above fuller details, removing IDs, etc
- As an example, to import an existing RBAC role *definition*, edit `my-rbac-role.tf`: 

```hcl
# my-rbac-role.tf

# Minimalist file for existing "my-rbac-role" to be imported

data "azurerm_management_group" "primary" {
  # To reference an existing management group where the role is defined
  name = "<UUID>"
}

resource "azurerm_role_definition" "my-rbac-role" {
  name  = "my-rbac-role"
  scope = data.azurerm_management_group.primary.id
}
```  

- Next, run the following: 
`terraform import azurerm_role_definition.my-rbac-role-def "/providers/Microsoft.Authorization/roleDefinitions/<UUID>|/providers/Microsoft.Management/managementGroups/<UUID>"`

- Similarly, for an existing role *assignment* you would create a similar minimalist file then do:
`terraform import azurerm_role_assignment.my-rbac-role-assign "/providers/Microsoft.Management/managementGroups/<UUID>/providers/Microsoft.Authorization/roleAssignments/<UUID>"`

- References:
  - This article is a helpful intro into this <https://blog.devgenius.io/beginners-guide-to-using-terraform-for-azure-90861bc8b9cf>
  - To create more resources see the more detailed tutorial at <https://developer.hashicorp.com/terraform/tutorials/azure-get-started>

### Manage Terraform with Github Actions
In general, the typical options when using Terraform are the following: 
    1. Deploy locally via Terraform CLI
    2. Deploy using Terraform Cloud/Enterprise
    3. Deploy using Azure DevOps
    4. Deploy using GitHub Actions

Option one is really just to test Terraform. The others are a little more serious when managing a cloud environment.

Here we will focus on _Option #4_, which will entail:
    - Source control           : GitHub private repository
    - Workflow automation      : GitHub Actions and HashiCorp’s GitHub Action (setup-terraform)
    - Infrastructure as code   : Terraform
    - Terraform remote backend : Azure Storage Account container
    - Target cloud environment : Microsoft Azure

One can certainly use a different SCM, or a differnt cloud, so above depend on your choices

Intead of creating service principal _TF-AzureRM-Policy_ as mentioned in above article, let's just use the same SP and AZ group mentioned in previous section (`azuretf-sp00` and `az-terraform-management`) 

Assign AZ group `az-terraform-management` the role "Resource Policy Contributor"
  - This role may not be needed for this example.

Integrate TF state into Github Action workflow:
  - <https://stackoverflow.com/questions/64397938/how-to-integrate-terraform-state-into-github-action-workflow>
  - Create folder `.github` with subfolder `workflows` in the git repo
  - Upgrade Github account to Team Org, to be able to protect repository branches from direct MERGEs (repository Settings -> Branches)

(Needs clean up)


### Extent of Terraform Privileges
It's wise to limit and isolate the scope and roles of the security context under which Terraform operates. This reduces the potential blast-radius if the Terraform credentials may happen to be compromised.


### Single vs Multi-states
At some point you'll need to decide whether you will only have a single state file (local or remote). A single state file works fine for very small setups, but can quickly become cumbersome for larger infrastructure. Particularly if there are many different teams submitting changes to an environment and the state gets locked while each change is being applied. That is when having multiple states or workspaces will come in handy. It gives an organization more flexibility by allowing changes to be independently deployed without locking their separate workflows.

### Mono vs Multi-repo
When working with Terraform there will come a point where you will need to decide whether to use a mono-repo versus a multi-repo _IaC_ structure for your source code repository. The common analogy is the monolithic project type as opposed to the micro-services project design. There's no right or wrong in this. The answer will depend on different factors, such as how tightly-coupled your project and the development and operation teams are.

The typical mono-repo repository structure looks like the following: 

```text
terraform-azure-core/
├── main.tf
├── variables.tf
├── outputs.tf
├── README.md
├── modules/
│   ├── terraform-azure-dir-group/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── terraform-azure-dns-zone/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── terraform-azure-vm/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── examples/
│   ├── example1/
│   │   ├── main.tf
│   │   ├── terraform.auto.tfvars
│   │   └── outputs.tf
│   └── example2/
│       ├── main.tf
│       ├── terraform.auto.tfvars
│       └── outputs.tf
└── tests/
    ├── test_main.tf
    └── test_terraform.auto.tfvars
```
The alternative is a multi-repo structure where each of the submodules under above `modules` subdirectory would instead reside in their own repository.

1. For a **mono** repo setup the `main.tf` file would look like something like this: 

```hcl
# main.tf
# terraform-managed-infra
# This is the calling module, defining a specific Azure infrastructure to be managed with module 'azure=core'

module "azure-core" {

  # Another option  
  # version = "1.0.0" # This is needed only when hitting a TFE/Cloud registry
  # source = "spacelift.io/YOUR-ORG/module-name/azure"
    # Normal pattern is '<REGISTRY_URL/<org>/<module_name>/<provider>', but if it's
    # a submodule then it's '<REGISTRY_URL/<org>/<module_name>/<provider>//modules/<sub-mod-name>'

  # Working option  
  source = "github.com/myorg/terraform-azure-core?ref=1.0.0"
    # The "?ref-1.0.0" specifies the repo tag or branch

  # Another option  
  # source = "github.com/myorg/terraform-azure-core//some-subdir?ref=1.0.0"
    # Note the '//' if module is in some subdirectory

  # Another option  
  # source = "./modules/vm"
    # For local CLI testing

  dir_groups = var.dir_groups  # Defined in the terraform.auto.tfvars
  dns_zonnes = var.dns_zones
  resource_n = var.var_n       # And so on
}
```
This infrastructure module would then call the single terraform-azure-core module to manage the Azure infrastructure.

2. For a **multi** repo setup the `main.tf` file would look like something like this: 

```hcl
# main.tf
# terraform-managed-infra
# This is the calling module defining a specific Azure infrastructure to be managed,
# which leverages all the different terraform-azure-X submodules.

module "azure_dir_groups" {
  # This module would manage all directory groups in the infra as defined in
  # variable 'dir_groups' in terraform.auto.tfvars
  source = "github.com/myorg/terraform-azure-dir-group?ref=1.0.0"
  # Above module sits in a separate repo in Github

  dir_groups = var.dir_groups
}

module "azure_dns_zones" {
  # This module would manage all DNS zones in the infra as defined in variable
  # 'dns_zones' in terraform.auto.tfvars
  source = "github.com/myorg/terraform-azure-dns-zones"  # Defaults to main branch
  # Above module sits in a separate repo in Github

  dns_zonnes = var.dns_zones
}

# Other modules can be defined below to manage other resources with their respective separate module
```

### See also
* [The Problem with Infrastructure-as-Code](problem-with-iac.md)
* [The Problem with Terraform State](problem-with-state.md)
* [Terraform to Vault From Azure](vault-from-azure.md)


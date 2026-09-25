---
type: take
---
## The Problem with Infrastructure-as-Code

[Infrastructure-as-code](https://en.wikipedia.org/wiki/Infrastructure_as_code) tools exist to make up for something clouds and operating systems lack. They have no built-in, versioned record of their own configuration that can be reconciled and rolled back. Terraform's state file is that crutch.

The industry has been moving my way. [Kubernetes](https://en.wikipedia.org/wiki/Kubernetes) keeps desired state inside the platform and works toward it. Azure Resource Manager records deployments and previews them with [what-if](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-what-if). [GitOps](https://en.wikipedia.org/wiki/GitOps) pushes the reconciliation loop into the platform itself.

Where I once overstated it was the remedy. I wanted one universal infrastructure protocol built into every OS and cloud, the way [TCP/IP](https://en.wikipedia.org/wiki/Internet_protocol_suite) ended the era of vendor network protocols. The comparison is strained. TCP/IP standardized a thin layer, while resource models are wide and vendor-specific on purpose. The universal attempts so far have found limited uptake: [OASIS TOSCA](https://en.wikipedia.org/wiki/OASIS_TOSCA), DMTF's [CIMI](https://en.wikipedia.org/wiki/Cloud_Infrastructure_Management_Interface), and today [Crossplane](https://www.crossplane.io/) and the [Open Application Model](https://oam.dev/).

Versioning is also not enough on its own. A deleted disk or a DNS record that has already spread does not come back with a revert. And even a platform with perfect history leaves you wanting declarative definitions in git for review, reuse, and environments.

So the defensible claim is narrower. The state file is a symptom. Platforms are absorbing reconciliation. What remains open is a common declarative model across vendors, a live problem nobody has solved.

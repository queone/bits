---
type: reference
---
## OIDC and SAML

[OpenID Connect](https://en.wikipedia.org/wiki/OpenID_Connect) (OIDC) and [Security Assertion Markup Language](https://en.wikipedia.org/wiki/Security_Assertion_Markup_Language) (SAML) are the two protocols behind single sign-on. Both hand a user from one login to many applications, and both name the same three parts. The differences are age, data format, and vocabulary.

### The three parts

- The user, or a program acting as one, wants into an application.
- The identity provider (IdP) checks who the user is.
- The application trusts the IdP's answer and lets the user in.

### Login flow when the user starts at the IdP

1. The user logs in to the IdP.
2. The user picks an application from the IdP's list.
3. The IdP sends the user's identity data to the user's browser.
4. The browser passes that data to the application.
5. The application checks that the user may use it, then lets the user in.

### Login flow when the user starts at the application

1. The user opens the application and tries to log in.
2. The application redirects the browser to the IdP.
3. The IdP logs the user in, or sees that the user is already logged in.
4. The IdP confirms the user has access to the application that sent the request.
5. The IdP sends the user's identity data to the browser, which passes it to the application.
6. The application checks that the user may use it, then lets the user in.

### Same thing, different names

| SAML | OIDC | What it is |
|------|------|------------|
| Identity Provider (IdP) | OpenID Provider (OP) | The system that authenticates the user |
| Service Provider (SP) | Relying Party (RP) | The application the user wants |
| Assertion | ID token with claims | The signed identity data sent to the application |

### Where they differ

- SAML 2.0 became a standard in 2005. OIDC was published in 2014.
- SAML carries the assertion as signed XML. OIDC carries the claims as a signed JSON Web Token ([JWT](https://en.wikipedia.org/wiki/JSON_Web_Token)).
- SAML is its own protocol. OIDC is an identity layer on top of [OAuth 2.0](https://en.wikipedia.org/wiki/OAuth), which by itself only grants a program access to an API.
- OIDC uses plain HTTPS calls and JSON, so it fits mobile apps and REST APIs with less code than XML signing needs.
- Both can start at the IdP or at the application.

### See also

- [GitHub Actions to Azure with OIDC](../git/oidc-azure.md): a workflow trades GitHub's token for Azure tokens, with no secret stored.
- [GitHub Actions to Vault with OIDC](../git/oidc-vault.md): the same trade against HashiCorp Vault.
- [Terraform to Vault From Azure](../terraform/vault-from-azure.md): a VM's managed identity logs in to Vault.

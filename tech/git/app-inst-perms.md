---
type: reference
---
## GitHub App Installation Permissions
This document outlines the three sets of permissions a GitHub App can request upon installation. It lists the available permissions in each category, with brief descriptions.

### 1. Repository Permissions
Permissions that apply to repositories the app is installed on.

| #  | Name                         | Description                                                                 | Default |
|----|------------------------------|-----------------------------------------------------------------------------|---------|
| 1  | Actions                      | Workflows, workflow runs and artifacts.                                     | No access |
| 2  | Administration               | Repository creation, deletion, settings, teams, and collaborators.          | No access |
| 3  | Attestations                 | Create and retrieve attestations for a repository.                          | No access |
| 4  | Checks                       | Checks on code.                                                             | No access |
| 5  | Code scanning alerts         | View and manage code scanning alerts.                                       | No access |
| 6  | Codespaces                   | Create, edit, delete and list Codespaces.                                   | No access |
| 7  | Codespaces lifecycle admin  | Manage the lifecycle of Codespaces, including starting and stopping.        | No access |
| 8  | Codespaces metadata         | Access Codespaces metadata including the devcontainers and machine type.    | No access |
| 9  | Codespaces secrets          | Restrict Codespaces user secrets modifications to specific repositories.    | No access |
| 10 | Commit statuses             | Commit statuses.                                                            | No access |
| 11 | Contents                    | Repository contents, commits, branches, downloads, releases, and merges.    | No access |
| 12 | Custom properties           | View and set values for a repository's custom properties.                   | No access |
| 13 | Dependabot alerts           | Retrieve Dependabot alerts.                                                 | No access |
| 14 | Dependabot secrets          | Manage Dependabot repository secrets.                                       | No access |
| 15 | Deployments                 | Deployments and deployment statuses.                                        | No access |
| 16 | Discussions                 | Discussions and related comments and labels.                                | No access |
| 17 | Environments                | Manage repository environments.                                             | No access |
| 18 | Issues                      | Issues and related comments, assignees, labels, and milestones.             | No access |
| 19 | Merge queues                | Manage a repository's merge queues.                                         | No access |
| 20 | Metadata                    | Search repositories, list collaborators, and access repository metadata.    | Read-only (**Mandatory**)|
| 21 | Packages                    | Packages published to the GitHub Package Platform.                          | No access |
| 22 | Pages                       | Retrieve Pages statuses, configuration, and builds.                         | No access |
| 23 | Projects                    | Manage classic projects within a repository.                                | No access |
| 24 | Pull requests               | Pull requests and related comments, assignees, labels, milestones, merges.  | No access |
| 25 | Repository security advisories | View and manage repository security advisories.                         | No access |
| 26 | Secret scanning alerts      | View and manage secret scanning alerts.                                     | No access |
| 27 | Secrets                     | Manage Actions repository secrets.                                          | No access |
| 28 | Single file                 | Manage just a single file.                                                  | No access |
| 29 | Variables                   | Manage Actions repository variables.                                        | No access |
| 30 | Webhooks                    | Manage the post-receive hooks for a repository.                             | No access |
| 31 | Workflows                   | Update GitHub Action workflow files.                                        | No access |

### 2. Organization Permissions
Permissions that apply across an organization when the app is installed on it.

| #  | Name                          | Description                                                                | Default |
|----|-------------------------------|----------------------------------------------------------------------------|---------|
| 1  | API Insights                  | View statistics on how the API is being used for an organization.         | No access |
| 2  | Administration                | Manage access to an organization.                                         | No access |
| 3  | Blocking users                | View and manage users blocked by the organization.                        | No access |
| 4  | Campaigns                     | Manage campaigns.                                                         | No access |
| 5  | Custom organization roles     | Create, edit, delete and list custom organization roles.                  | No access |
| 6  | Custom properties             | View custom properties, write repository values, administer definitions.  | No access |
| 7  | Custom repository roles       | Create, edit, delete and list custom repository roles.                    | No access |
| 8  | Events                        | View events triggered by an activity in an organization.                  | No access |
| 9  | GitHub Copilot Business       | Manage Copilot Business seats and settings.                               | No access |
| 10 | Issue Fields                  | Manage issue fields for an organization.                                  | No access |
| 11 | Issue Types                   | Manage issue types for an organization.                                   | No access |
| 12 | Knowledge bases               | View and manage knowledge bases for an organization.                      | No access |
| 13 | Members                       | Organization members and teams.                                           | No access |
| 14 | Models                        | Manage model access for an organization.                                  | No access |
| 15 | Network configurations        | Manage hosted compute network configurations for an organization.         | No access |
| 16 | Organization announcement banners | View and modify announcement banners for an organization.           | No access |
| 17 | Organization codespaces       | Manage Codespaces for an organization.                                    | No access |
| 18 | Organization codespaces secrets | Manage Codespaces Secrets for an organization.                        | No access |
| 19 | Organization codespaces settings | Manage Codespaces settings for an organization.                      | No access |
| 20 | Organization dependabot secrets | Manage Dependabot organization secrets.                               | No access |
| 21 | Organization private registries | Manage private registries for an organization.                        | No access |
| 22 | Personal access token requests | Manage personal access token requests from organization members.      | No access |
| 23 | Personal access tokens        | View and revoke personal access tokens granted to an organization.       | No access |
| 24 | Plan                          | View an organization's plan.                                              | No access |
| 25 | Projects                      | Manage projects for an organization.                                      | No access |
| 26 | Secrets                       | Manage Actions organization secrets.                                      | No access |
| 27 | Self-hosted runners           | Manage Actions self-hosted runners available to an organization.          | No access |
| 28 | Team discussions              | Manage team discussions and related comments.                             | No access |
| 29 | Variables                     | Manage Actions organization variables.                                    | No access |
| 30 | Webhooks                      | Manage the post-receive hooks for an organization.                        | No access |

### 3. Account (User-to-Server) Permissions
Permissions used when an app acts on behalf of a user (via OAuth).

| #  | Name                    | Description                                                                 | Default |
|----|-------------------------|-----------------------------------------------------------------------------|---------|
| 1  | Block another user      | View and manage users blocked by the user.                                 | No access |
| 2  | Codespaces user secrets | Manage Codespaces user secrets.                                            | No access |
| 3  | Copilot Chat            | Access GitHub ID, Copilot Chat session messages, and timestamps.           | No access |
| 4  | Copilot Editor Context  | Access bits of editor context (e.g., open files) via Copilot Chat.         | No access |
| 5  | Email addresses         | Manage a user's email addresses.                                           | No access |
| 6  | Events                  | View events triggered by a user's activity.                                | No access |
| 7  | Followers               | View a user's followers.                                                   | No access |
| 8  | GPG keys                | View and manage a user's GPG keys.                                         | No access |
| 9  | Gists                   | Create and modify a user's gists and comments.                             | No access |
| 10 | Git SSH keys            | View and manage Git SSH keys.                                              | No access |
| 11 | Interaction limits      | Manage interaction limits on repositories.                                 | No access |
| 12 | Knowledge bases         | View knowledge bases for a user.                                           | No access |
| 13 | Models                  | Allows access to GitHub Models.                                            | No access |
| 14 | Plan                    | View a user's plan.                                                        | No access |
| 15 | Profile                 | Manage a user's profile settings.                                          | No access |
| 16 | SSH signing keys        | View and manage a user's SSH signing keys.                                 | No access |
| 17 | Starring                | List and manage repositories a user is starring.                           | No access |
| 18 | Watching                | List and change repositories a user is subscribed to.                      | No access |

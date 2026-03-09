# Landing Zone Pipelines (AWS CodePipeline + CodeBuild)

Terraform module that provisions a **multi-account Landing Zone deployment pipeline** in a *Shared Services* account:
- AWS CodePipeline (source → validate → plan → manual approval → apply)
- AWS CodeBuild projects (validate/plan/apply)
- CodeStar Connections (GitLab Self-Managed by default, with option to use GitHub/Bitbucket)
- Artefacts S3 bucket + KMS key (and permissions)
- IAM roles for CodePipeline + CodeBuild (and cross-account `sts:AssumeRole` to your deploy/execution roles)

> Designed to be used as a standalone module repo and called from your Landing Zone `shared-services` stack.

---
---

## Notes

### Pipelines enable/disable
Each pipeline supports `enabled = true/false`. Disabled pipelines are not created.

### CodeConnections providers
- `GitLabSelfManaged` and `GitHubEnterpriseServer` require a **host**.
- Cloud providers (`GitHub`, `GitLab`, `Bitbucket`) do not require a host.

### Repository & branch
The module expects `gitlab_full_repository_id` and `vcs_branch` (legacy naming) for the Source stage.
You can keep using those even if you change providers later; rename/generalize later if you want.

---

## What’s intentionally NOT in this repo
- No Terraform backend configuration (`backend.tf`)
- No local Terraform state artifacts (`.terraform/`, `*.tfstate`)
This is a reusable module repo; state belongs in the wrapper stack.

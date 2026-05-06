# Azure Terraform (UAT-focused)

This repository contains Terraform modules and an environment composition targeted at a UAT deployment. Legacy demo files have been archived under `examples/demo/` to avoid accidental runs at repository root.

Repository layout

- `env/uat` — UAT environment root (use this for plan/apply)
- `modules/` — reusable Terraform modules
- `examples/demo` — archived demo configuration (do not run in CI)
- `scripts/` — helper scripts (backend bootstrap, apply wrapper, validation)

Prerequisites

- Terraform (>= 1.5.0)
- Azure CLI (for interactive auth) or Service Principal credentials for CI
- SSH key pair for VM access

Quickstart — UAT (local development)

1. Authenticate with Azure (interactive or use a Service Principal/ARM_* env vars in CI):

```bash
az login
# or for CI use a Service Principal and export ARM_CLIENT_ID / ARM_CLIENT_SECRET / ARM_TENANT_ID / ARM_SUBSCRIPTION_ID
```

2. Initialize (local test without remote backend):

```bash
terraform -chdir=env/uat init -backend=false
```

3. Validate the configuration:

```bash
terraform -chdir=env/uat validate
```

4. Create a plan (artifactize in CI):

```bash
terraform -chdir=env/uat plan -out uat.tfplan
```

5. Apply (in CI use the artifact + manual approval gate):

```bash
terraform -chdir=env/uat apply "uat.tfplan"
```

Backend & bootstrap

Use `scripts/bootstrap-backend.ps1` to create the storage account and blob container used for remote state. Set the pipeline variable `BACKEND_SA` before running CI.

Notes

- Do not run `terraform init`/`plan`/`apply` at the repository root. Use the `-chdir=env/uat` option or `cd env/uat`.
- The archived demo files are available under `examples/demo` if you need the simple VM example.
- `env/uat/.terraform.lock.hcl` exists; no lockfile regeneration is required unless you request it.


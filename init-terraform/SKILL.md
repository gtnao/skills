---
name: init-terraform
description: Bootstrap terraform under terraform/ in the current repository. Creates a bucket-creation script for the S3 state backend, minimal terraform config (backend/versions/provider), and a .gitignore, then shows the user the commands to create the bucket and run terraform init (it does not run them). The state bucket name is derived from the directory layout as tfstate.<repo>.<org>, where <repo> is the current directory basename and <org> is its parent directory basename (matching the GitHub org/repo layout).
disable-model-invocation: true
allowed-tools: Write Bash(terraform --version) Bash(basename *) Bash(dirname *) Bash(pwd) Bash(chmod *) Bash(ls *) Bash(ls) WebFetch(domain:registry.terraform.io)
---

# Bootstrap terraform in a repository

Set up terraform under `terraform/` in the current working directory, with S3 as the state backend.

## Preconditions

1. Run `ls -A terraform 2>/dev/null` — if it returns anything, stop and ask the user before proceeding.
2. Resolve names from the directory layout (works before the repo is pushed, so don't use `gh`):
   - `<repo>`: `basename "$(pwd)"`
   - `<org>`: `basename "$(dirname "$(pwd)")"`
   - `<bucket>`: `tfstate.<repo>.<org>`

   If `<bucket>` violates the S3 bucket naming rules (3–63 chars; lowercase letters, digits, `-`, `.` only; must start and end with a letter or digit; no consecutive dots; not IP-formatted), derive a compliant name — lowercase it, replace `_` with `-`, and shorten if over 63 chars — then propose it to the user with AskUserQuestion (proposed name as the recommended option) and proceed with their choice. Bucket names are hard to change later (state migration), so never silently use a transformed name.
3. Resolve versions:
   - `<tf-version>`: run `terraform --version` and take the installed version's `major.minor.0` (e.g. `v1.15.0` → `1.15.0`).
   - `<aws-provider-version>`: fetch `https://registry.terraform.io/v1/providers/hashicorp/aws` and take the latest version's `major.minor` (e.g. `6.54.0` → `6.54`).

The region is fixed to `ap-northeast-1`.

## Files

Write these files verbatim, substituting the `<...>` placeholders. Do not add anything beyond what is shown — minimal is intentional.

### `terraform/scripts/create-tfstate-bucket.sh`

After writing, `chmod +x` it. The script is idempotent.

```bash
#!/bin/bash
# Creates the S3 bucket that this repo's terraform uses as its state backend.
# Run once manually before `terraform init`.
#
# What it creates:
#   - S3 bucket: <bucket>
#       (versioning + AES256 + public access blocked)
#
# Prerequisites:
#   - AWS CLI configured
#
# Usage:
#   AWS_PROFILE=<profile> ./terraform/scripts/create-tfstate-bucket.sh

set -euo pipefail

if [ -z "${AWS_PROFILE:-}" ]; then
	echo "Error: AWS_PROFILE env var must be set" >&2
	exit 1
fi

REGION="ap-northeast-1"
BUCKET="<bucket>"

echo "========================================="
echo "Bucket: ${BUCKET}"
echo "Region: ${REGION}"
echo "========================================="

if aws s3api head-bucket --bucket "${BUCKET}" --profile "${AWS_PROFILE}" 2>/dev/null; then
	echo "Bucket already exists."
else
	echo "Creating bucket..."
	aws s3api create-bucket \
		--bucket "${BUCKET}" \
		--region "${REGION}" \
		--create-bucket-configuration "LocationConstraint=${REGION}" \
		--profile "${AWS_PROFILE}"
fi

echo "Enabling versioning..."
aws s3api put-bucket-versioning \
	--bucket "${BUCKET}" \
	--versioning-configuration Status=Enabled \
	--profile "${AWS_PROFILE}"

echo "Configuring encryption..."
aws s3api put-bucket-encryption \
	--bucket "${BUCKET}" \
	--server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" },
            "BucketKeyEnabled": true
        }]
    }' \
	--profile "${AWS_PROFILE}"

echo "Blocking public access..."
aws s3api put-public-access-block \
	--bucket "${BUCKET}" \
	--public-access-block-configuration \
	"BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
	--profile "${AWS_PROFILE}"

echo ""
echo "========================================="
echo "Done: ${BUCKET}"
echo "========================================="
```

### `terraform/aws/versions.tf`

`required_version` uses `>=` (not `~>`) so future CLI upgrades are not blocked; the provider uses `~>` to pin the major version.

```hcl
terraform {
  required_version = ">= <tf-version>"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> <aws-provider-version>"
    }
  }
}
```

### `terraform/aws/backend.tf`

`use_lockfile = true` enables S3-native locking (no DynamoDB table needed, requires terraform >= 1.10).

```hcl
terraform {
  backend "s3" {
    # Bucket is bootstrapped manually by terraform/scripts/create-tfstate-bucket.sh.
    bucket       = "<bucket>"
    key          = "aws/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

### `terraform/aws/provider.tf`

```hcl
provider "aws" {
  region = "ap-northeast-1"
}
```

### `terraform/.gitignore`

State lives in S3; the `*.tfstate` entries are insurance for local copies (`terraform state pull`, backend migration backups). `.terraform.lock.hcl` is intentionally NOT ignored — commit it.

```
.terraform/
*.tfstate
*.tfstate.*
```

## Finish

Do NOT create the bucket or run `terraform init` yourself. After writing the files, show the user these next steps and end:

```bash
# 1. Create the state bucket (idempotent; skip if it already exists)
AWS_PROFILE=<profile> ./terraform/scripts/create-tfstate-bucket.sh

# 2. Initialize terraform
cd terraform/aws && terraform init
```

Also remind them to commit the `.terraform.lock.hcl` that init generates.

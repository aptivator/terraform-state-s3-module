# `terraform-state-s3-module`

## Table of Contents

* [Introduction](#introduction)
* [Usage](#usage)
  * [Prerequisites](#prerequisites)
  * [Deploying Terraform State Storage Resources](#deploying-terraform-state-storage-resources)
  * [Working with an Infrastructure Stack](#working-with-an-infrastructure-stack)
    * [Saving State of an Infrastructure Stack](#saving-state-of-an-infrastructure-stack)
    * [Destroying Infrastructure Stack File](#destroying-infrastructure-stack-file)
* [Removing Terraform State Artifacts](#removing-terraform-state-artifacts)

## Introduction

Proper use of Hashicorp's `terraform` infrastructure tool requires some
centralized place to store information about resources that are being
provisioned.  When working within Amazon Web Services (AWS), a common pattern is
to utilize Simple Cloud Storage (S3) to keep track of services deployed combined
with Dynamo Database to synchronize access to the infrastructure state.  This
terraform module contains current best practices declarations to deploy S3 and
DynamoDB artifacts to keep track of architecture stacks.

## Usage

### Prerequisites

Implementation of multiple accounts AWS scheme is recommended.  Under the
arrangement, deployment of terraform state resources should be in a shared
services account.  The latter would typically host continuous integration and
deployment pipelines, code and image repositories, and any other entities
applicable organization-wide.

Only one set of an S3 bucket and a DynamoDB table is necessary per organization
or an organizational unit.  Storing information about various resource states in
one spot promotes consistency and is the preferred approach.  Perhaps there are
some edge cases calling for multiple S3-DynamoDB pairs to track deployments.
Under these circumstances the module could still be used as described below.

### Deploying Terraform State Storage Resources

The module requires three inputs: names of an S3 bucket and DynamoDB table and
an AWS provider configuration for the account that will store the infrastructure
information.  Consult terraform documentation to specify appropriate provider
settings.

```tf
/* terraform-state-s3.tf */

provider "aws" {
  alias                   = "state"
  region                  = "us-east-1"
  profile                 = "shared"
  shared_credentials_file = "~/.aws/credentials
}
```

`terraform-state-s3-module` can be fetched directly from github and the aws 
provider configuration can be passed directly to it.

```tf
module "terraform-state" {
  source                      = "git@github.com:anderson-optimization/terraform-state-s3-module.git"
  terraform_state_bucket_name = "my-organization-or-some-unique-name-terraform-state"
  terraform_state_table_name  = "terraform-state"
  
  providers = {
    aws = aws.state
  }
}
```

Running `terraform init` will download the `terraform-state-s3` and aws provider
modules.  Invoking `terraform apply` should provision the S3 bucket and DynamoDB
table.

**NOTE:** The module is currently in a private repository and github access
credentials for `anderson-optimization` account are necessary.

### Working with an Infrastructure Stack

#### Saving State of an Infrastructure Stack

Whenever some stack is provisioned or updated, the configuration for the
infrastructure must include information for the state S3 bucket and DynamoDB
table.  Terraform provides `s3` `backend` block to declare state location as
illustrated below.

```tf
terraform {
  backend "s3" {
    bucket                  = "{bucket that stores terraform states}"
    key                     = "{name of the  infrastructure state file}"
    dynamodb_table          = "{DynamoDB table}"
    encrypt                 = true    
    region                  = "{region where the state infrastructure was provisioned}"
    shared_credentials_file = "{path to aws credentials file}"
    profile                 = "{aws credentials profile to use for Shared Services account}"
  }
}
```

For the `key`, the recommended approach is to specify the account where the
service is deployed, followed by the service name, and then followed by the name
of the state file.  For example, if `programmatic-api` service is deployed in a
development account, then the `key` would be
`dev/programmatic-api/programmatic-api.tfstate`.

The recommended approach is to specify backend information in a separate file
(e.g., `backend.hcl`) that would not be committed to source control.  The file
would contain the same data state information as shown below.

```
bucket                  = "{bucket that stores terraform states}"
key                     = "{name of the  infrastructure state file}"
dynamodb_table          = "{DynamoDB table}"
encrypt                 = true
region                  = "{region where the state infrastructure was provisioned}"
shared_credentials_file = "{path to aws credentials file}"
profile                 = "{aws credentials profile to use for Shared Services account}"
```

The terraform infrastructure file should contain blank `backend` declaration.

```tf
terraform {
  backend "s3" {}
}
```

To initialize the state backend, the following command should be run.

```
terraform init -backend-config=backend.hcl
```

#### Destroying Infrastructure Stack File

Whenever `terraform destroy` operation is completed, the state file will be
essentially empty, but it will not be removed.  If the infrastructure will not
be spun up again and the file is unnecessary, then it would have to be deleted
manually.

## Removing Terraform State Artifacts

Whenever terraform state S3 bucket and DynamoDB table need to be destroyed, the
recommended approach is to do so manually.  It is more onerous to unprovision
the two artifacts via terraform itself, then to just delete them via AWS
console.

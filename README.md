## `terraform-state-s3-module`

### Introduction

Proper use of Hashicorp's `terraform` infrastructure tool requires some
centralized place to store information about resources that are being
provisioned.  When working within Amazon Web Services (AWS), a common pattern is
to utilize Simple Cloud Storage (S3) to keep track of services deployed combined
with Dynamo Database to synchronize access to the infrastructure state.  This
terraform module contains current best practices declarations to deploy S3 and
DynamoDB artifacts to keep track of architecture stacks.

### Usage

#### Prerequisites

Implementation of multiple accounts AWS scheme is recommended.  Under the
arrangement, deployment of terraform state resources should be in a shared
services account.  The latter would typically host continous integration and
deployment pipelines, code and image repositories, and any other entities
applicable organization-wide.

Only one set of an S3 bucket and a DynamoDB table is necessary per organization
or an organizational unit.  Storing information about various resource states in
one spot promotes consistency and is the preferred approach.  Perhaps there are
some edge cases calling for multiple S3-DynamoDB pairs to track deployments.
Under these circumstances the module could still be used as described below.

#### Deploying Terraform State Storage Resources

The module requires three inputs: names of an S3 bucket and DynamoDB table and
an AWS provider configuration for an account that will store infrastructure
information.  


```tf
provider "aws" {
  region                  = "us-east-1"
  profile                 = "shared"
  shared_credentials_file = "~/.aws/credentials
  version                 = "~> 3.6"
}
```

#### Storing State of an Infrastructure Stack

### Destroying Terraform State Artifacts

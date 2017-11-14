---
date: "2017-11-14T08:21:14Z"
title: "Deploying Cloud Foundry with Concourse Pt2"
draft: true
---

This is the second blog post in a series of three:

1. [What originally led us to use Concourse][pt1]
1. [Some interesting things we've done using Concourse][pt2]
1. [Problems that we encountered using Concourse][pt3]

[pt1]: XXX
[pt2]: XXX
[pt3]: XXX

## Some interesting things we've done using Concourse

Deploying with pipelines in this way has enabled us to do some interesting
things..

### IAM roles and profiles

After accidentally leaking our AWS access keys more than once we decided to
follow their recommended best practice of using [IAM roles and
profiles][iam-adr] to authenticate.

Fortunately most of the underlying AWS libraries already support this
automatically if they are running on an EC2 instance and aren't given any
pre-generated keys. For example, with Terraform running from Concourse, we
just had to apply a profile to the Concourse VM and remove the key
configuration.

[iam-adr]: https://government-paas-team-manual.readthedocs.io/en/latest/architecture_decision_records/ADR003-AWS-credentials/

We had to fork two of the standard resources that come with Concourse:

- [s3-resource]()
- [semver-resource]()

Those resources normally require you to pass pre-generated access and secret
keys into your pipeline configuration. We [raised pull requests][iam-pr] to
allow role support but they weren't accepted by upstream, so we've
maintained our forks since.

[iam-pr]: https://github.com/concourse/s3-resource/pull/22

### Commit signature verification

- verify code review without manual gate
- already had CD

### Automated testing

- parallel
- smoke, acceptance, availability

### Promotion of tags

- tag-release script
- git-resource

### Password and certificate generation

- certstrap
- password library

### Overnight auto-delete

- within environment, can be left to run
- HA failure testing

### Self updating

- ensure jobs match code

### Run job

- normally pass commit ref through
- detach repo to run from latest commit

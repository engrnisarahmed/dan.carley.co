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
only had to apply a profile to the Concourse VM and remove the keys we were
previously passing as environment variables.

[iam-adr]: https://government-paas-team-manual.readthedocs.io/en/latest/architecture_decision_records/ADR003-AWS-credentials/

We had to fork two of the standard resources that come with Concourse:

- [s3-resource](https://github.com/concourse/s3-resource)
- [semver-resource](https://github.com/concourse/semver-resource)

These resources normally require you to pass pre-generated access and secret
keys into your pipeline configuration. We [raised pull requests][iam-pr] to
allow profile support but they weren't accepted by upstream, so we've
maintained our forks since.

[iam-pr]: https://github.com/concourse/s3-resource/pull/22

### Automated testing

- parallel
- smoke, acceptance, availability

### Commit signature verification

Some teams at work automatically deploy to an integration environment when
pull requests are merged. Deployments to production are then batched up by a
human who initiates a deployment to a staging environment first, and then to
production. This is partly guided by security policy.

We started both phases of our project with continuous deployment. Merged
changes are automatically deployed to a staging environment and the tests
run, then if they're successful it's automatically repeated in production.

There was initially some discomfort in the team about this. What if the
tests weren't good enough? What if we let a bad change go to production?
Though I'm pleased to say that we've never had an incident that would have
been avoided by manually reviewing and triggering a deployment. We've
benefited from smaller and less risky deployments, features getting to users
faster, and everyone in the team (including those without production access)
having an understanding of when their changes will be deployed.

We were quite reluctant to give this up when our service went live. So we
looked at the types of threats that the security policy was trying to guard
against; unreviewed code being deployed to production, particularly by a
malicious actor that has stolen a team member's laptop. Our process already
had a code review step so we decided to build upon this by verifying the
identity of the reviewer.

We made a utility [`github_merge_sign`][] to GPG sign merge commits on pull
requests. `gpg-agent` normally has a much shorter cache period than
`ssh-agent`, so it's less likely that a stolen laptop could be used to
maliciously sign a merge commit.

[`github_merge_sign`]: https://github.com/alphagov/paas-github_merge_sign

We modified the Concourse `s3-resource` to check these signatures against a
predefined list of GPG IDs.

To verify the signatures we modified the Concourse `git-resource` to check
against a predefined list of GPG IDs. If the signature doesn't match then
the fetch fails and no deployment is triggered. Our changes were [merged
upstream][git-gpg].

[git-gpg]: https://github.com/concourse/git-resource/pull/76

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

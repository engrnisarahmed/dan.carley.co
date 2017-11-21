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

### Commit signature verification

Some teams at work automatically deploy to an integration environment when
pull requests are merged. Deployments to production are then batched up by a
human who initiates a deployment to a staging environment first, and then to
production. This is partly guided by security policies.

We started both phases of our project with continuous deployment. Merged
changes are automatically deployed to a staging environment and the tests
run, and if they're successful then it's automatically repeated in
production.

There was initially some discomfort in our team about this. What if the
tests weren't good enough? What if we let a bad change go to production?
Though I'm pleased to say that we've never had an incident that would have
been avoided by manually reviewing and triggering a deployment. We have
benefited from smaller and less risky deployments, features getting to users
faster, and everyone in the team (including those without production access)
having an understanding of when their work will go to production.

We grew very reluctant to give this up when our service went live. So we
looked at the types of threats that the policies were trying to guard
against; unreviewed code being deployed to production, particularly by a
malicious actor that has stolen a team member's laptop. Our process already
had a code review step so we decided to build upon this by verifying the
identity of the reviewer.

We made a utility called [`github_merge_sign`][] to GPG sign merge commits on pull
requests. `gpg-agent` normally has a much shorter cache period than
`ssh-agent`, so it's less likely that a stolen laptop could be used to
maliciously sign a merge commit. We modified the Concourse
[`git-resource`][] to check these signatures against a predefined list of
GPG IDs. If the signature isn't permitted then the fetch fails and no
deployment is triggered. Our changes were [merged upstream][gpg-pr], so you
can use them too.

[`github_merge_sign`]: https://github.com/alphagov/paas-github_merge_sign
[`git-resource`]: https://github.com/concourse/git-resource
[gpg-pr]: https://github.com/concourse/git-resource/pull/76

### Automated testing

Having a pipeline has allowed us to incorporate better testing into our
deployments. We have several suites of tests that run after a deployment to
verify that it works correctly. These all run in parallel with each other:

- [performance tests][]
  to check the response times of an application through the routing tier for
  an application
- [smoke tests][]
  to get fast feedback about whether basic functionality works
- [upstream acceptance tests][]
  to get more detailed feedback about whether standard Cloud Foundry
  features are working as expected for that version
- [custom acceptance tests][]
  to check any customisations we've made to the platform, such as adding
  HSTS headers or service broker integrations

[smoke tests]: https://github.com/cloudfoundry/cf-smoke-tests
[upstream acceptance tests]: https://github.com/cloudfoundry/cf-acceptance-tests
[custom acceptance tests]: https://github.com/alphagov/paas-cf/tree/prod-0.1.82/platform-tests/src/platform/acceptance
[performance tests]: https://github.com/alphagov/paas-cf/tree/prod-0.1.82/platform-tests/src/platform/performance

The smoke tests also run continuously outside of deployments and alert us on
failures. Unfortunately we can't run the upstream availability tests in
production because they taint the global state of the environment and could
leave it not functioning correctly.

In addition to those we have some tests that run during a deployment, in
parallel to operations like Terraform and BOSH. Uptime is really important
for us and our users so we want to know that all of our deployments are
zero-downtime. The following are started at the beginning of the pipeline
and stopped near the end:

- [application availability tests][]
  which use the [vegeta][] load testing library to send a constant rate of
  requests to an application deployed on the platform and report on any
  failed requests
- [API availability tests][]
  which use the [go-cfclient][] library to perform relatively fast API
  operations that mimic normal CLI usage - it lists applications, gets their
  detailed stats, but doesn't deploy new apps because it would take too long
  and we might miss short periods of downtime

[API availability tests]: https://github.com/alphagov/paas-cf/tree/prod-0.1.82/platform-tests/src/platform/availability/api
[go-cfclient]: https://github.com/cloudfoundry-community/go-cfclient
[application availability tests]: https://github.com/alphagov/paas-cf/tree/prod-0.1.82/platform-tests/src/platform/availability/app
[vegeta]: https://github.com/tsenart/vegeta

With the exception of the continuous smoke tests, any test failure will
prevent a deployment from proceeding to the next environment.

### Promotion of tags

To automatically promote a change to the next environment we have a script
the runs at the end of the pipeline to create a git tag containing the name
of the environment that it's passed in and a version.

For our first environment, which picks up changes from the `master` branch,
the version is incremented on each deployment. We have Concourse jobs that
allow us to bump the individual parts of the semantic version but in
practice we haven't needed to use them very often.

All subsequent environments have the `tag-filter` option configured in the
[`git-resource`][] to pick up the latest tag from the preceding environment.
The tagging script creates a new tag when the deployment has finished,
keeping the same version number but rewriting the environment name.

[`git-resource`]: https://github.com/concourse/git-resource

This script turned out to be a really good lesson in why even seemingly
simple shell scripts should have tests. We found a couple of bugs after we
first started using it and there was a some reluctance to make or review
changes without easily knowing whether it was going to make it better or
worse. So we wrote some integration tests that operate against a local git
repository and describe the behaviours that we expect.

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

### Removing CI environment

?

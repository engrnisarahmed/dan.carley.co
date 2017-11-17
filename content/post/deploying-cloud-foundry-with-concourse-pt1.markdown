---
date: "2017-11-14T08:21:14Z"
title: "Deploying Cloud Foundry with Concourse Pt1"
draft: true
---

We've been using [Concourse][] to deploy [Cloud Foundry][] at work for just
over a year now. I'm going to describe our experience in a series of three
blog posts:

1. [What originally led us to use Concourse][pt1]
1. [Some interesting things we've done using Concourse][pt2]
1. [Problems that we encountered using Concourse][pt3]

[Concourse]: https://concourse.ci/
[Cloud Foundry]: https://www.cloudfoundry.org/
[pt1]: XXX
[pt2]: XXX
[pt3]: XXX

## Deploying Cloud Foundry

Here are the high-level steps involved in deploying a Cloud Foundry
environment:

1. create some basic [IaaS][] resources (e.g. VPC and ELBs) with [Terraform][]
1. render [BOSH][] manifests to include environment specific data (e.g. passwords) with [spruce][]
1. deploy BOSH director with [bosh-init][]
1. deploy Cloud Foundry with BOSH

[IaaS]: https://en.wikipedia.org/wiki/Infrastructure_as_a_service
[Terraform]: https://www.terraform.io/
[BOSH]: https://bosh.io/
[spruce]: https://github.com/geofffranks/spruce
[bosh-init]: https://github.com/cloudfoundry/bosh-init

## Previously in our alpha

We didn't use Concourse during the [alpha phase][] of our project. To create
your own development environment of Cloud Foundry you would run a `Makefile`
target, which ran the first step described above on your laptop and then ran
the remaining steps via a bastion host with a variety of shell scripts.

We optimised early for every developer to create their own environment that
would look like production. Later on we re-used the same tooling to create
non-development environments, such as CI and production, by running the
`Makefile` target from [Jenkins][] each time there was a new commit to our
code repository.

You can see an archive of our old codebase at [gds-attic/paas-alpha-cf-terraform][].

This setup was sufficient during our alpha. It was relatively low effort to
get working and allowed us to focus on testing whether Cloud Foundry was the
right technology for us to use. But it did have some drawbacks..

[alpha phase]: https://www.gov.uk/service-manual/agile-delivery/how-the-alpha-phase-works
[Jenkins]: https://jenkins.io/
[gds-attic/paas-alpha-cf-terraform]: https://github.com/gds-attic/paas-alpha-cf-terraform

### Debugging

It was very hard to reason about the entire deployment process. The
`Makefile` and shell scripts started off simple but quickly grew in
complexity. To understand the process, even at a high-level, you'd have to
read through most of the call-chain and codebase. You'd often find yourself
doing that to figure out how far a deployment had progressed or why it had
failed midway.

It wasn't possible to resume the deployment from the place that it had
failed. So you'd need to make your change, run everything from the beginning
again, and hope that you'd got it right. Which was very frustrating and time
consuming.

There was also a disparate Jenkins layer to maintain and debug, which we
rarely exercised in development environments. Although Jenkins has seen
significant improvements in the past year, it still remains difficult to
configure declaratively and easy to mutate the configuration through the web
interface.

### Connectivity

One reason a deployment could fail was if there were any connectivity
problems between your laptop and the remote environment. Aside from
unreliable internet connections, the most common causes were letting your
laptop sleep while you were away or changing networks (e.g. connecting or
reconnecting to a VPN).

This is because everything was initiated from, and the output sent back to,
your local laptop. Sometimes you'd get lucky and remote process would
continue, so you'd only lose the output. But more frequently the deployment
would halt and you'd have to run it again from the beginning.

### Runtime dependencies

Managing runtime dependencies was cumbersome. Especially for anything that
ran locally on your laptop, such as Terraform and Ruby scripting. Our team
have a mixture of Mac and Linux laptops, which made it difficult to
prescribe or reliably maintain the automated installation of dependencies,
so everyone needed to remember to upgrade in-step. The same process was
repeated again for our Jenkins machine which managed non-development
environments.

For our bastion host we had scripts that would install a handful of packages
and binaries, in a way that hoped to be idempotent and upgradeable, but
wasn't always. It would have been appropriate use of Configuration
Management like Puppet or Chef except that BOSH satisfied our need for CM
everywhere else and it didn't warrant introducing another dependency for
this one host.

### Managing state

The deployment of an environment creates some stateful data that needs to be
retained for subsequent deployments. This includes passwords used for
components within the environment, Terraform's state so that it knows what
IaaS resources have been created, and bosh-init's state so that it knows
where the BOSH director is.

All of this needs to be stored somewhere. Some of it exists on the place you
initiate the deployment (your laptop or Jenkins) and some exists on the
bastion host, neither of which are reliable. So we had to develop other ways
of backing it up.

## Now in our beta

We began the [beta phase][] of our project by throwing out all of the code
from the alpha and starting again. This allowed us to use the principles
that we'd learned without carrying forward the technical debt that we had
deliberately accrued. It was an opportunity to rethink how we'd like our
deployment process to work, which is something that can be difficult to
make big technical or cultural changes to once you've started. We retained
the same principles about making it easy to create reproducible
environments.

Our colleague [Hector Rivas Gandara][hector] was the first to suggest that
we use this shiny new thing called Concourse. After some exploratory work,
we started creating the deployment pipeline that we use today. You can see
our new codebase at [alphagov/paas-cf][].

XXX: Include picture?

Here is how we solved some of the deployment related problems from our
alpha..

[beta phase]: https://www.gov.uk/service-manual/agile-delivery/how-the-beta-phase-works
[alphagov/paas-cf]: https://github.com/alphagov/paas-cf
[hector]: https://uk.linkedin.com/in/hectorrivasgandara

### Separation of concerns

A pipeline in Concourse is made up of jobs/tasks (which are scripts) and
resources (which are state). The jobs/tasks have ephemeral storage, so all
state must be passed as inputs and outputs using resources.

This separation of concerns made us think much more carefully about the
discrete steps in our deployment and how they interact with one another. It
has produced something that is much easier to understand, both broadly and
in specific detail, without needing to read through all of the code.

It also put all of the state that we need to care about in a single place
(e.g. S3), which made it easier to think about securing and backing it up.

### Debugging

Concourse comes with a web interface that displays your pipeline of
interconnected jobs and resources. It's pretty, but also functional, because
it shows an overview of the deployment process and highlights where it's
progressing or failing.

To resume a failed deployment without starting from the beginning you can
restart an individual job with the original set of inputs. For more complex
debugging you can use [`fly intercept`][] to get an interactive shell under the
same environment that the job would have run in. These features have made
our development process much simpler and quicker.

For consistency, we deploy everything from a Concourse pipeline. This means
that we can use the same tooling and idioms throughout, rather than having
slightly different processes for different components and environments. The
fact that Concourse has a good API to configure the pipelines and doesn't
allow any configuration from the web interface has proved valuable -
basically the exact opposite of Jenkins.

[`fly intercept`]: https://concourse.ci/fly-intercept.html

### Connectivity

We solved our previous connectivity problems by deploying Concourse within
the environment (e.g. AWS VPC) that it would manage. You can now start a
deployment job on Concourse, close your laptop, and come back later to check
on it, without any risk of the deployment halting or losing the logs.

### Runtime dependencies

Concourse uses containers (Docker images executed in [garden-runc][]) for
all jobs, tasks, and resources within the pipeline. There are many things
attributed and misattributed to containers, but one of the features that I
really like is the reduction and isolation of runtime dependencies.

We produced minimalistic containers mostly based on [Alpine Linux][] that
are clear in purpose and only have the necessary dependencies. This has made
it easier to retrospectively upgrade, replace, or remove individual
utilities and their dependencies.

The container name and version are declared in the pipeline configuration
and Concourse takes care of pulling the container when required. So we no
longer need to tell team members what and how to install, or when to
upgrade.

You can see the code for the containers we use within our pipeline at
[alphagov/paas-docker-cloudfoundry-tools][].

[garden-runc]: https://content.pivotal.io/blog/adopting-the-runc-container-standard-in-cloud-foundry
[Alpine Linux]: https://alpinelinux.org/
[alphagov/paas-docker-cloudfoundry-tools]: https://github.com/alphagov/paas-docker-cloudfoundry-tools/

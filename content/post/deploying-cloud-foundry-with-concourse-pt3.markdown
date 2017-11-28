---
date: "2017-11-14T08:21:14Z"
title: "Deploying Cloud Foundry with Concourse Pt3"
draft: true
---

This is the third blog post in a series of three:

1. [What originally led us to use Concourse][pt1]
1. [Some interesting things we've done using Concourse][pt2]
1. [Problems that we encountered using Concourse][pt3]

[pt1]: XXX
[pt2]: XXX
[pt3]: XXX

## Problems we've encountered

On balance, I'm glad that we chose to use Concourse and I hope to see less
Jenkins in my future, but it's fair to say that it hasn't been all unicorns
and rainbows for us. Here are some of the problems that we've encountered..

### Bootstrapping

As previously described we wanted our entire deployment process to run from
Concourse. However there was a chicken-and-egg problem:

- we want Concourse to deploy BOSH
- we needed BOSH to deploy Concourse

To solve this we had to use two different Concourse servers. The first uses
[Vagrant][] and [Concourse in Docker][] to create a temporary server, which
we call "Bootstrap Concourse", outside of the target environment. That in
turn creates a BOSH Director and a permanent server, which we call "Deployer
Concourse", inside the target environment.

This setup has evolved a bit over time. For a short period of time the
"Bootstrap Concourse" was run locally using VirtualBox, but we later moved
it to AWS because it made deploying the subsequent components faster and
more reliable.

The "Deployer Concourse" was originally deployed before the BOSH Director.
We later changed the order, so that "Bootstrap Concourse" creates BOSH first
and then uses BOSH to create "Deployer Concourse", because we wanted a
re-usable way to create permanent Concourse servers and we've had problems
using `bosh-init`; it isn't well supported by BOSH releases like Concourse
and the [lack of a package cache][bosh-init-cache] makes it very slow.

Until very recently the "Bootstrap Concourse" was using a
[concourse-lite][], however the Concourse team stopped publishing updates to
the AMI a long time ago and we didn't want to maintain the AMI build process
ourselves. The switch to Docker was straightforward and works really well
for our ephemeral use case.

You can see our code for creating Concourse servers at [alphagov/paas-bootstrap][].

[vagrant]: https://www.vagrantup.com/
[Concourse in Docker]: https://concourse.ci/docker-repository.html
[concourse-lite]: https://github.com/concourse/concourse-lite
[bosh-init-cache]: https://github.com/cloudfoundry/bosh-init/issues/19
[alphagov/paas-bootstrap]: XXX

### Learning curve

As with any new technology, it took us a while to [grok][] how to use
Concourse. Especially how to use it correctly. It's very opinionated in
places, which I consider to be a good thing, but there's a really steep
learning curve.

We bought ourselves some time at the beginning of our beta build by
developing new Cloud Foundry manifests against our alpha deployment
codebase. Meanwhile some of the team worked on [spikes][] to test out
Concourse and demonstrate what they'd learnt to the rest of the team.

As is with all internalised knowledge, it's difficult for me to now pinpoint
what we struggled with. Though I'm still frequently frustrated by
aviation-themed project names and not remembering which is responsible for
what.

[grok]: https://en.wikipedia.org/wiki/Grok
[spikes]: https://en.wikipedia.org/wiki/Spike_(software_development)

### So much YAML

It seems that the cost of having a declarative configuration these days is
that you have to deal with tonnes and tonnes of YAML. So much YAML.

I'm still on the fence about whether to split your pipeline configurations
across multiple files. We decided not to, except for where tasks could be
re-used, because we found it incredibly hard to read the configurations of
third-party projects that had done so. However it has made it harder to
search commit history with [git pickaxe][] for a specific change, such as
"when and why did we change the container for this task?".

While we're not currently making best use of it, I'd recommend that you run
automated checks against your configurations before they reach a real
Concourse server. [`yamllint`][] can highlight simple problems and enforce a
consistent style in your configurations. [`fly validate-pipeline`][] can
check your configurations for semantic errors.

[git pickaxe]: XXX
[`yamllint`]: XXX
[`fly validate-pipeline`]: https://concourse.ci/fly-validate-pipeline.html

### Pipeline locking

Build and test pipelines for software can normally be run concurrently
multiple times because each run operates in isolation from one another, e.g.
against a temporary database. We can't allow that to happen for our
deployment pipeline though because each deployment modifies the state of a
single environment. We can't reliably test or guarantee the safety of two
changes being applied concurrently to the same environment, e.g. Terraform
applying merge commit B while BOSH is still applying merge commit A.

Concourse has a [`serial_groups`][] option to prevent more than one *job*
from running concurrently but it doesn't address our need for a changeset to
have made it all the way through the pipeline before the next changeset
starts deploying. To do that we needed to use the [pool-resource][] which
provides a semaphore that can be claimed at the beginning, passed through
the deployment, and then released at the end. New changesets will wait until
they are able to claim the semaphore.

This works, but required [quite a lot of work][] to automate the setup. The
resource keeps it state in a git repository and we didn't want to use GitHub
because we would have to pre-create and share credentials for each
environment. We chose to use [AWS Code Commit][] because it allowed us to
programmatically create and grant access to repositories.

In the future we could swap it out for a simpler backing store, like Redis
co-located with Concourse, or [native support in Concourse][].

[`serial_groups`]: https://concourse.ci/configuring-jobs.html#serial_groups
[pool-resource]: https://github.com/concourse/pool-resource
[quite a lot of work]: https://github.com/alphagov/paas-cf/pull/173
[AWS Code Commit]: https://aws.amazon.com/codecommit/
[native support in Concourse]: https://github.com/concourse/concourse/issues/282

### Self updating pipelines

- ensure jobs match code

### Stability

We started using Concourse at version 0.68 and it felt a bit bleeding edge.
The quality of the releases has definitely improved immeasurably since then.

For a long time we have trouble with Concourse 2.x slowing down and not
scheduling new jobs. We spent a lot of time investigating and discussing in
upstream issues, but it became so common that we wrote [a script to turn it
off and back on again][shake] and referred to the act of "shaking
Concourse".

Thankfully the [lifecycle rewrite][] in Concourse 3.x has since fixed our
problem and we haven't had any ongoing issues since.

[shake]: https://github.com/alphagov/paas-cf/blob/7b426184edcfffb896fc3d28497129090109b3e6/concourse/scripts/shake_concourse_volumes.sh
[lifecycle rewrite]: https://github.com/concourse/concourse/issues/629

### Size of the community

When I first thought about writing this blog post, more than a year ago, I
would have written about the size and diversity of interests in the
Concourse community. At that time it was basically just a small subset of
the Cloud Foundry community. This had an impact on Concourse features, for
example it was only possible to deploy with BOSH which is basically only
used by Cloud Foundry operators. This had a circular impact on additional
features and increasing the size of the community.

That's definitely changed though. You can now run Concourse without BOSH in
a variety of well supported ways. There's more interest in Concourse from
outside the Cloud Foundry community. It's just one of those things that took
time.

---
comments: true
date: 2014-06-12T00:00:00Z
title: Other people's firewalls
---

The more appropriate title would be "ingress and egress firewalls that
affect your connectivity but which you have no visibility and limited
control of" but it was too long. I've experienced this tale many times with
just one minor variation to the beginning of the plot and the rest of the
details remaining the same. It's either a:

- corporate firewall: owned by another team or group in a much larger
  organisation.
- vendor firewall: owned by a \*aaS provider that you have other services
  with.

The usual premise is that they are providing some value-add security for
you, possibly other tenants, and indeed themselves. However in reality it
usually winds up having the opposite effect on yourself.

## Lost in translation

To configure your own firewall you'll use a domain-specific configuration
syntax. You might not be particularly fond of the syntax (iptables, I'm
looking at you) but you can have confidence that it clearly describes the
thing that you have asked for and it will quickly draw your attention to any
syntactical mistakes. It might look something like:

    pass in on $ext_if proto { udp, tcp } from any to 10.0.0.1 port 53
    pass out on $ext_if proto icmp from 10.0.0.0/8 to any icmp-type 8 code 0

The same doesn't normally exist for other people's firewalls. Your interface
is a free-form text field in a change request application or email. The
syntax is a plain English description of your changes, because you don't
know what technology their firewalls are or what else their engineers are
familiar with. Everyone will have their own specific style and the level of
detail will range somewhere between:

- "Please open inbound DNS and outbound ping"
- "Please allow UDP/53 and TCP/53 to 10.0.0.1 and ICMP echo-reply from 10/8"

All of which harbour some degree of ambiguity. And even if you manage to
describe your rule perfectly, it still has to be transcribed by a human into
the right syntax without any typos and placed at the correct order in the
ruleset. All in all, there's a pretty good chance that you won't get the
thing you wanted first time.

## Troubleshooting

Like raw configuration, it's very rare that you're able to get hold of logs
or packet captures from devices under other people's control. Which means
that when a change request doesn't behave as intended your means of
debugging the problem are very much hindered. At best you can probably tell
whether a connection is being blocked or dropped if you own both sides of
the connection. Though the latter, if drop is the default policy, can be
indistinguishable from a routing or addressing mistake.

This reminds me of something that my colleague [Cal][calpaterson] said when
we were talking with someone else about their corporate firewall woes,
with some paraphrasing: "surely you'd put a logging rule in place for a few
days and see what traffic matched first". Which is when it struck me that
I'd forgotten that this was a Done Thing. I'd been dealing with devices that
I couldn't get logs from for so long that it probably wouldn't cross my mind
any longer. Which is a depressing realisation.

There is of course a special place reserved for people that break utilities
like `ping(1)` and `traceroute(1)` that can prove essential when debugging
network issues.

[calpaterson]: https://twitter.com/calpaterson

## Default deny egress

Something that "other people" seem incredibly fond of is default deny
policies on outbound traffic. A whitelist of protocols that you are allowed
to connect out on, usually limited to DNS, HTTP and HTTPS.

The biggest problem is that this goes against the principle of least
astonishment. Most people are used to working with networks that have
restrictive ingress and permissive egress. People are frequently surprised
when things don't work that way; they deploy a new tool or service and find
that it doesn't work in a given environment, eventually track down the
problem and raise a firewall change request, forget the solution and get on
with their life, then repeat the same process a month or two later.

I've often heard this justified in the corporate context as a means to
prevent an attacker from leaking data out of the network if a machine within
was compromised - for example FTPing all of your customer database to a host
in `$OTHER_COUNTRY`. Except some important facts are often disregarded:

1. Outbound initiated HTTP and HTTPS are themselves perfectly good means of
   data transfer.
1. TCP is stateful two-way protocol. If an attacker is able to initiate an
   inbound connection and subvert that service then they can send traffic
   back out on the very same channel.
1. Unless there is some [DPI][dpi] (in which case there should be a better
   [IPS][ips] than default deny) then there's no guarantee that TCP/80 is
   actually HTTP. It any could be any protocol that an attacker wishes to
   stand up on that port. And even with DPI, TCP/443 could be *anything*
   encapsulated in TLS.

It is sometimes driven by a concern that their users/tenants will become a
platform to attack others, such as email spam or DoS reflection attacks.
Blocking everything might be an appropriate defence for cheap shared
hosting. But I feel like at some stage you need to differentiate users that
know what they're doing and are prepared to take responsibility for
themselves.

NB: I don't mean [BCP46][bcp46] which includes guidelines about preventing
your network from emitting traffic that doesn't belong to you. Something
that everyone should implement.

[dpi]: http://en.wikipedia.org/wiki/Deep_packet_inspection
[ips]: http://en.wikipedia.org/wiki/Intrusion_prevention_system
[bcp46]: http://tools.ietf.org/html/bcp46#section-4.4

## Refactoring and rationalisation

Something that sysadmins and developers often do when working on
configuration or code is refactor to ensure that it reads well and executes
efficiently, in addition to rationalising old content that is no longer
relevant.

In the process of adding a new firewall rule it's not uncommon to discover
existing rules in the same vicinity that duplicate or contradict each other,
or that are simply no longer required due to services being decommissioned.

The trouble with being abstracted away from the real config and having
someone else implement it for you is that these things rarely happen. The
person editing the config doesn't have enough context to make those
decisions for you and there is limited incentive for them to liaise
back-and-forth with you to clean it up. So technical debt is left to
accumulate.

## Over compensation

Every one of those frustrations inherently increases the time it takes for a
change to be correctly implemented and degrades the feedback loop.

A cumulative effect is that users/tenants often react by over compensating
with their changes. They make requests for rules that are more permissive
than they need to be. They don't make requests to remove rules that are no
longer needed.

This has exactly the opposite effect of what you want from a firewall.
You're less secure because too much is allowed through. Yet because nobody
can see the detail some people will continue to either:

- *think* that they are secure regardless
- not ask any questions because it's too hard

## Solution?

I'm not sure that I have a good solution to offer from this rant. Other than
try to take ownership of the things that matter to you. The answer to "who
owns my security?" is usually the same as the answer to
["who owns my availability?"](http://www.whoownsmyavailability.com/).

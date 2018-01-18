---
date: 2018-01-18T18:17:00Z
title: BT Infinity and AWS CloudFront IPv6 MTU
---

Late last year I converted this blog from Octopress to Hugo and migrated it
from a Linode VM to AWS S3, in an effort to spend less of my free time
maintaining dependencies and virtual machines. It also reduced the runtime
costs from $5/mo to $0.2/mo.

I wanted to keep IPv6 support and enable TLS, so I put it behind AWS
CloudFront. When testing the new site from my home connection, which has native
IPv6, I noticed that initial page loads were extremely slow. I debugged it with
a combination of:

- [`go-httpstat`](https://github.com/tcnksm/go-httpstat)
- [`curl --trace-time`](https://ec.haxx.se/usingcurl-verbose.html#-trace-time)
- [Wireshark](https://www.wireshark.org/)

These showed that three seconds were spent on the TLS handshake. Since MTU
related problems seem to have become "[my][] [thing][]" I had a hunch about
where this was going.

[my]: https://github.com/gds-attic/paas-os-conf-release/pull/2
[thing]: https://github.com/alphagov/paas-cf/pull/887

Thankfully a [James Dobson][] has written a really good blog post describing an
identical problem with another ISP. In summary: PPPoE requires an extra 8
bytes, IPv6 doesn't allow fragmentation, and PMTUD is nearly always broken.

[James Dobson]: https://jamesdobson.name/post/mtu/

Being a good netizen I wanted to make this better..

## AWS CloudFront

This wasn't CloudFront's fault but as a popular CDN provider they could do a
better job of dealing with broken ISPs, because there will always be broken
ISPs.

I'm fortunate to have access to an AWS Premium Support account through my
job and I realised that the same problem affected a number of sites on our
project. I raised a feature request for CloudFront to clamp the MSS in their
SYN-ACK to 1420 bytes.

They took my request seriously and the change was deployed in December, which
fixed my immediate problem and possibly many other affected people.

## BT Infinity

The root of the problem was with my BT broadband connection. Initially I
tried contacting customer support to report the problem, but had real
trouble getting first line to triage or escalate it.

I eventually took to Twitter in frustration. A kind person referred my tweet
to an amazingly helpful engineer at BT who arranged a call to debug the
problem. It turns out that my router was a new variant (Smart Hub 6B) that
didn't have the workarounds from previous models applied to it.

They contacted me again in January to confirm that a new firmware has been
rolled out which uses [IPv6 Router Advertisement options][ipv6-ra] to reduce
the MTU to 1492.

[ipv6-ra]: https://tools.ietf.org/html/rfc4861#section-4.6.4

## Reflections

It's worth trying to make the Internet a better place no matter how futile
it may seem at times. It feels good that a couple of relatively small
changes will have had a positive impact on many people, even if they don't
realise it.

I originally joined Twitter because it allowed me to talk to clever people in
good places and that still stands true today. There are lots of helpful people
out there, you just need to find them.

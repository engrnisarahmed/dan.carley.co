---
layout: post
title: "Problems with online services"
date: 2015-08-10T18:16:51+01:00
---

I recently had problems with the online services of two well known
companies; [Nationwide][] and [Eurostar][]. That in itself is not unusual or
noteworthy. But there are some things in common between the two experiences.

[Nationwide]: http://www.nationwide.co.uk/
[Eurostar]: http://www.eurostar.com/

## tl;dr

Please consider the following when you're building online services.

### Error messages

Try to make error messages useful to the user. Tell them what went wrong.
Don't suggest trying again, without making any changes, unless you think
it's going to help. Moreover, don't lie about people being aware of the
problem and that it's being investigated unless you have a really robust
process to do so.

I realise that this is easier said than done. Not all errors are expected.
Bugs are common in software. There's also a tension with security about
disclosing the inner workings of your code to users. You probably don't want
to give them all of your debug information, especially if it's a sensitive
system that deals with bookings or money.

For example though, if you know that a problem may happen when validating a
users details then surface that information. It may help the user
self-diagnose their issue before they even contact you. If they do need to
contact you then it will be easier for your support staff to triage the
case. If you're unable to provide descriptive messages then consider using
codes, either unique to the problem or that users transaction, and provide a
good mechanism for subsequently looking them up.

### Channels for when things go wrong

Provide a good channel for when things go wrong. Start by making it easier
for users to report problems and allowing them to include contextual
information.

For example, [GOV.UK][] has a "Is there anything wrong with this page?" link
at the bottom of every page, which asks the users to describe what they were
trying to do, what they expected to happen, and what really happened.
[Google Cloud Platform][] has a feedback link which lets you capture a
screenshot of the current page and then highlight pertinent sections, as
well as omitting sensitive information that you don't want to submit.

Once you have received the information make sure it's triaged in a timely
manner and passed onto the correct people. Give first line support staff
some way of reporting software bugs and tallying repeated occurrences. You
don't have to commit to fixing them immediately, but at least you'll be
aware of the problems and have data to prioritise them.

[GOV.UK]: https://www.gov.uk/
[Google Cloud Platform]: https://cloud.google.com

My suspicion is that many developers in very large companies have no idea of
the bugs that their users experience because the business has disconnected
them so far from their users. Or they know about the bugs and would love to
fix them, but they never get prioritised, because they don't have enough
data to support doing so.

### Assisted digital

My recent experiences have left me suddenly quite empathetic with [assisted
digital][]. As someone that has a good understanding of and access to
computers, I am definitely not a use case. But I found myself in a not
dissimilar position whereby it was only possible (or otherwise *deeply*
inconvenient) to do the thing that I needed to do online and I wasn't able
to do so because of circumstances beyond my control.

[assisted digital]: https://www.gov.uk/service-manual/assisted-digital

I was also reminded of this first hand when seeing customers at the Eurostar
terminal who were told that they had to look up additional travel advice and
rebook tickets online but didn't have access to the Internet. One lady
approached us outside because she didn't have a smartphone, wasn't able to
lookup any information, and had already spent a long time on hold to a call
centre. I guess the simplest lesson is not to assume that everyone will be
able to do the thing you're suggesting.

## My woes

Onto my specific woes. Besides being therapeutic, my hope is that either
other people will search for these errors and find a solution to their
problem, or (less likely) the companies will be shamed into fixing the bugs
that I was unable to report.

### Nationwide

My wife and I have a mortgage with Nationwide. The rate we were on had come
to the end of its deal period, so we wanted to switch to a new deal and thus
lower rate.

As an aside, it seems that there were some changes to legislation last year
that meant mortgage lenders have to clearly distinguish between applications
that are based on product advice (after a long discussion about the
customers circumstances) from those that are execution-only (the customer
has chosen the product that they want without any advice from the lender).

It seems that an interpretation of this, perhaps to cover themselves, is
that you can only perform execution-only changes yourself online. If you're
not able to do it online then you have to book an appointment with a
mortgage advisor which involves talking in detail about your circumstances,
which will take between 1 to 2 hours.

We knew the product that we wanted and had done it before online. However
this time it wouldn't let us. When submitting the second page of terms and
conditions acceptance, it would say "please wait" for 30 seconds, then
produce an error page with the message:

> Sorry, we are unable to process your request due to a system error.  
> We are aware of the issue and our technical team is investigating the problem.  
> Please try submitting your request again.  

I tried a few more times and got the same each time. Contrary to the
message, I knew from my experience of using and supporting online systems
that nobody was aware of my problem and that nobody would be currently
investigating it.

So over the course of the next two weeks I tried the following. Meanwhile
some lenders were withdrawing their deals because of projected base rate
rises:

1. First of all I tried reporting the problem using the "secure messaging"
section of their online banking. They replied the following day to suggest
that I clear my cookies and try another browser or computer. That of course
did not help.

2. Next I called them and they suggested that I try a different method, by
selecting "not registered for Internet banking", because it was known that
some people had experienced problems with the other method. Same error
again.

3. I called again and they reviewed my account details, found that our
occupancy status was incorrect, changed it and advised me to try again in 24
hours, allowing for their systems to update. That didn't work either.

4. I called again and was transferred to someone related to technical
faults. They couldn't accept a screenshot of the error page, so I had to
talk them through the user journey and describe each of the pages including
the error message. They said it would take three to five days so I should
pursue other means of making the application and that they would contact me
back soon with an reference and update.

5. I went into a branch to see if I could do the execution-only application
there. I couldn't, I would have to book an appointment with a mortgage
advisor. They let me try the online application on their computers but
ironically the browser was either too old or too locked down that I couldn't
navigate their Javascript-heavy website to get to the first page of the
application. They tried to chase up the fault report for me and couldn't
find any reference of it, but they were able to find phone appointments
sooner than I could get one in branch.

6. Reluctantly, I called again to make a phone appointment and report the
problem again. It would be at least an hour and half at a time that the
other account holder is also contactable. They weren't able to transfer me
to anyone that would take a fault report and the best that they could do was
record that there was a generic problem (without taking any details of the
journey or error).

While booking the phone appointment I was asked to confirm my email address
because the system wouldn't let them proceed with the one that was already
listed for my account. I instantly knew that this was significant. I use
[Gmail's "+" aliasing feature][] to categorise and track emails from
different parties. Despite being a perfectly legitimate address, every so
often a company will build a sign-up form where such addresses are rejected,
or much worse they will accept the address at sign-up and then prevent you
from using it later ([ASOS][], I'm looking at you).

[ASOS]: http://www.asos.com/
[Gmail's "+" aliasing feature]: https://support.google.com/mail/answer/12096

I asked them to change the address on my account and finished booking the
phone appointment. Then immediately rushed off to try the online process
again. No luck. I waited 24 hours, because that's apparently how long
computers take to update information. Success! The "invalid" email address
on my account was the cause of the problem.

It felt like I'd found it by pot luck though. There is nothing about the
error message or the application process that indicated it cared about my
email address. I seem to recall that the page after the error asks you to
confirm your contact details and my guess is that it was trying to parse or
validate them before displaying, but never got that far. I should note that
everyone I spoke to was incredibly helpful in what they did. They just
weren't able to help the *actual* problem.

### Eurostar

My wife and I recently travelled to Belgium for her birthday. On our way
back we got to Brussels to find that our Eurostar train had been cancelled
and there would be no further services that day. We had a very stressful few
hours arranging childcare for our son back home and trying to find a hotel
which hadn't been fully booked. Oh well, these things happen.

When we had eventually sorted those things out we attempted to rebook our
Eurostar journey for the following day. All of the morning departures had
already gone. We tried booking for the first afternoon departure that was
available but when submitting the very last confirmation page it gave an
error message, paraphrasing everything but the error code:

> Unfortunately a technical problem occurred. Please try again later. (EIF_132)

I tried again several times. I reluctantly tried booking a later departure
time, even though it wouldn't get us home until the evening and would make
logistics with our son even harder, but still got the same error. I kept
trying. Eventually the earlier departure became fully booked and no longer
available either.

There is a web form that you can fill out if you're having trouble booking,
whereby you specify roughly when you'd like to travel and wait for them to
contact you back. But it's quite difficult to find and it's asynchronous so
you have no idea when they will contact you, if at all, and whether you'll
miss other departures in the meantime. I submitted it but didn't hear
anything back.

I kept trying for nearly an hour. I got quite good at remembering where all
of the fields and buttons on the forms were. Meanwhile my wife was on the
phone, on hold, trying to talk to a human.

I thought about trying to book a much later departure to see if it was just
a problem with the departure times being oversubscribed, but the error only
occurred on the final confirmation page and we couldn't afford to arrive
home any later than we already would.

Out of desperation I tried something else. I rebooked my own ticket
individually and it worked. I then, very hurriedly and quite nervously,
rebooked my wife's ticket and that also worked. We were eight coaches apart
and later than we had first hoped, but at least we were going home.

My wife did eventually get through on the phone, almost an hour after first
calling and a while after I had managed to rebook individually. They weren't
able to change our booking to anything more preferable.

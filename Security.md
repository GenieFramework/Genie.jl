# Security Policy

## Supported Versions

Versions of Genie.jl currently being supported with security updates.

| Version    | Supported          |
| ---------- | ------------------ |
| >= 4.16.x  |        ✔           |
| <= 4.15.x  |        x           |

# Security Policies and Procedures

This document outlines security procedures and general policies for the Genie
project.

  * [Reporting a Bug](#reporting-a-bug)
  * [Disclosure Policy](#disclosure-policy)
  * [Comments on this Policy](#comments-on-this-policy)

## Reporting a Bug

The Genie team and community take all security bugs in Genie seriously.
Thank you for improving the security of Genie. We appreciate your efforts and
responsible disclosure and will make every effort to acknowledge your
contributions.

Report security bugs by emailing the lead maintainer on following email: <report@stipple.app> with subject as followed: 

`**[SECURITY Genie.jl] followed with subject of security bug**`

To ensure the timely response to your report, please ensure that the entirety
of the report is contained within the email body and not solely behind a web
link or an attachment.

The lead maintainer will acknowledge your email within 42 hours, and will send a
more detailed response within 42 hours indicating the next steps in handling
your report. After the initial reply to your report, the security team will
endeavor to keep you informed of the progress towards a fix and full
announcement, and may ask for additional information or guidance.

Report security bugs in third-party modules to the person or team maintaining
the module with cc'ed report@stippple.app if Genie.jl is using the module as one of the dependencies

## Disclosure Policy

When the security team receives a security bug report, they will assign it to a
primary handler. This person will coordinate the fix and release process,
involving the following steps:

  * Confirm the problem and determine the affected versions.
  * Audit code to find any potential similar problems.
  * Prepare fixes for all releases still under maintenance. These fixes will be
    released as fast as possible and will be available with latest tagged Genie version and announced on [Genie's twitter](https://twitter.com/GenieMVC) and [Genie's Discord #announcement channel](https://discord.com/invite/9zyZbD6J7H).

## Comments on this Policy

If you have suggestions on how this process could be improved please submit a
pull request.

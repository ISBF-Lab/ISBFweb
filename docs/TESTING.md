# Discourse Developer Testing Guide

Some notes about testing Discourse:

## MailHog

Discourse depends heavily on (sending) email for notifications. We use [MailHog](https://github.com/mailhog/MailHog)
to test emails. It's super convenient!

> MailHog runs a super simple SMTP server which catches any message sent to it to display in a web interface. Run mailhog, set your favourite app to deliver to smtp://127.0.0.1:1025 instead of your default SMTP server, then check out http://127.0.0.1:8025 to see the mail that's arrived so far.

For Docker development, start the email capture service separately:

```bash
bin/docker/mailhog
```

Keep this terminal running while testing email. Publishing port `8025` does not
start the service: if the browser reports a connection reset, check that the
service is running inside the container and listening on ports `8025` and `1025`.
After restarting the container, start the email capture service again.

When the development host is remote, forward port `8025` through your editor or
SSH before opening `http://127.0.0.1:8025` on your own computer.

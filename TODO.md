# TODO — HTTP Health Checks

This file captures open questions and decisions from the design sessions.
It is intended to be read by an agent continuing this work in a new session.
The platform constitution (injected at session start) governs all decisions here.


## Motivation

Uptime monitoring for websites should be effortless: add a URL to the config and the platform handles everything else — provisioning the health check, configuring the check interval and thresholds, and wiring up alerting. No manual interaction with any monitoring service is required.

This is a platform system in the constitutional sense: the config drives the creation of real monitoring resources. Adding a URL creates a health check; removing a URL deletes it. The config is the single source of truth.


## Technology Options

### Cloudflare Health Checks

- Native to Cloudflare, which is already used for DNS (no additional account needed)
- Manageable via Terraform (Cloudflare provider)
- Health check features are fairly basic compared to dedicated tools
- Can monitor any publicly reachable hostname or IP address — not restricted to Cloudflare-proxied targets
- No free tier: requires Pro plan ($25/mo) for 10 checks, Business plan ($250/mo) for 50 checks
- Now marketed as part of "Smart Shield" — product positioning is drifting away from standalone monitoring

### UptimeRobot

- Dedicated uptime monitoring service with a generous free tier
- Simple API, Terraform provider available
- Not already in the stack (new account/dependency)
- More monitoring-specific features than Cloudflare

### Checkly

- Developer-focused; supports scripted checks (not just simple HTTP pings)
- Terraform provider available
- Paid; more powerful than needed for simple uptime checks

### Pingdom / Better Uptime / others

- Mature, feature-rich tools but paid and not already in the stack
- No strong reason to prefer over UptimeRobot for this use case

### Why not Prometheus?

Prometheus is pull-based: it scrapes metrics from targets that expose a `/metrics` endpoint. Websites don't instrument themselves this way. While the Blackbox Exporter can simulate HTTP checks, this adds operational overhead (Prometheus instance, exporter, storage) for a problem that dedicated uptime tools solve natively. Prometheus belongs in the platform as infrastructure for applications to emit metrics — not for external uptime checks.


## Validation and Remediation Strategy

The constitutional validation/remediation loop maps directly onto a scheduled `terraform apply`:

- `terraform apply` is inherently both validation and remediation in one command: it compares declared config against actual state (validation), and if drift is detected it re-applies to correct it (remediation).
- On the first run with an empty state, `apply` provisions all declared health checks.
- On subsequent runs, if nothing has drifted it is a no-op; if a health check was accidentally deleted or modified outside Terraform, `apply` recreates or corrects it.

### GitHub Actions Workflow

A single workflow covers both triggers:

1. **On push to `main`** — runs `terraform apply` immediately to realise any config change
2. **On schedule** (e.g. daily) — runs `terraform apply` to detect and self-heal drift

Both triggers run the same job. No separate validation step is needed — `apply` subsumes it. This satisfies the constitutional requirement that validation runs automatically, covers every declared item, and triggers on config changes and periodically.


## Open Question: Alerting

When a health check fails, how should the alert reach the user? Options:

- **Email** — supported natively by all monitoring services; no setup beyond an address
- **Slack** — webhook-based; requires a Slack workspace and incoming webhook config
- **PagerDuty** — on-call escalation; overkill for personal/small-team use
- **GitHub Issues** — could open an issue automatically; keeps everything in GitHub but unusual for alerts
- **SMS** — supported by some services (UptimeRobot, Checkly); immediate but requires a phone number

Note: alerting here is not the constitutional Remediation step. Remediation in this system means: if a health check resource is accidentally deleted from the monitoring service, validation detects the drift and recreates it. Alerting on a website being down is a separate concern — it is the monitoring service doing its job, not the platform responding to configuration drift.

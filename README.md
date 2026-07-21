![CyberDrain Light](github_assets/img/CIPP.png#gh-dark-mode-only)
![CyberDrain Dark](github_assets/img/CIPP-Light.png#gh-light-mode-only)

# What is CIPP?

The CyberDrain Improved Partner Portal (CIPP) is a multi-tenant management portal for Microsoft Partners. The current Microsoft partner landscape makes it fairly hard to manage multi-tenant situations, with loads of manual work. Microsoft Lighthouse might resolve this in the future, but its development is lagging far behind the needs of the current market for Microsoft Partners.

CIPP helps you with day-to-day administration across all of your Microsoft 365 tenants from a single pane of glass, including:

- **Tenant administration** — manage users, groups, mailboxes, devices, and licenses across every tenant you service, without switching portals or juggling GDAP relationships by hand.
- **Standards & best practices** — define your preferred security and configuration standards once, then deploy and continuously enforce them across all tenants.
- **Security & compliance visibility** — review alerts, incidents, and tenant health from one place, and act on them quickly.
- **Automation** — scheduled tasks, alerting, and integrations that remove repetitive work and save several hours per engineer per month.

For detailed documentation about the features of CIPP, please check out our [documentation](https://docs.cipp.app).

# How it works

This repository is the monorepo for CIPP, combining the frontend and backend into a single containerized deployment powered by the [Craft](https://github.com/CyberDrain/Craft) runtime:

- **`frontend/`** — the web interface, built with [Next.js](https://nextjs.org/) and React.
- **`backend/`** — the API layer, written in PowerShell and executed by the Craft runtime.
- **`build/`** — Dockerfiles, docker-compose definitions, and tooling used to build and run the containerized deployment.

# Our sponsors

You can find our sponsors [here.](https://docs.cipp.app/#our-sponsors)

---
description: >-
  Keeping CIPP up-to-date ensures you have the latest features, security
  patches, and bug fixes.
---

# Updating Versions

{% hint style="warning" %}
## **CyberDrain Hosted Clients**

If you’re using a CyberDrain-hosted instance of CIPP, updates happen automatically; generally, within **48 hours** of a new release. You can safely skip the rest of this page; however, it is important to perform a permissions check via CIPP > Application Settings > [permissions.md](../../user-documentation/cipp/settings/permissions.md "mention") to ensure any newly added permissions are accounted for.
{% endhint %}

Update your self-hosted CIPP instance to the latest release using the following instructions:

{% stepper %}
{% step %}
### Log in to CIPP

Log in to CIPP as a superadmin account
{% endstep %}

{% step %}
### Open Container Management

Go to CIPP -> Advanced -> SuperAdmin -> [container.md](../../user-documentation/cipp/advanced/super-admin/container.md "mention")
{% endstep %}

{% step %}
### Update Management

Set your auto-update settings or press the "Check now" button to check for updates and install them.

{% hint style="info" %}
You can optionally change which Release Channel you target for updates. Use caution when running Dev or Nightly as these can contain untested changes.
{% endhint %}
{% endstep %}
{% endstepper %}

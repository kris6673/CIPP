# Migrating to the Latest Version of CIPP

In July of 2026, we were pleased to announce new infrastructure for CIPP. Migrating to the new infrastructure gains speed and controlled cost. Newly deployed CIPP instances are already on the new infrastructure.

## CyberDrain Hosted Clients

{% stepper %}
{% step %}
### Open the Management Portal

Navigate to [management.cipp.app](https://management.cipp.app/).
{% endstep %}

{% step %}
### Go to Early Opt-In


{% endstep %}

{% step %}
### Complete the Form


{% endstep %}

{% step %}
### Submit

The Overview tab will show when your migration is complete.&#x20;

{% hint style="info" %}
If you receive an error during migration rest assured that the helpdesk has been alerted and will work to resolve the error quickly.
{% endhint %}
{% endstep %}

{% step %}
### SSO Setup

If you haven't already completed the SSO set up steps you will be prompted to complete that setup when you first open CIPP again. See [roles.md](../setting-up-cipp/roles.md "mention")
{% endstep %}

{% step %}
### Custom Domain

If you had a custom domain on your old version of CIPP, you'll need to migrate it too. To migrate a domain to the new generation of CIPP, point its existing CNAME record at CIPPXXXX.azurewebsites.net, then add the domain here. It will move over automatically. If a TXT record named `asuid.<your domain>` exists from your previous setup, remove it — domain-verification TXT records are no longer used, and a leftover one blocks validation. This step must be performed in the [management portal](https://management.cipp.app/).

{% hint style="warning" %}
Users who load your pre-existing custom domain prior to the certificate being provisioned will be redirected to the new Azure URL. After the certificate is provisioned they may still experience this behavior as their local DNS cache will remember the redirect. Please direct those users to clear their cache.
{% endhint %}
{% endstep %}
{% endstepper %}

{% @storylane/embed subdomain="app" linkValue="d3kcpzf2efuj" url="https://app.storylane.io/share/d3kcpzf2efuj" %}

## Self-Hosted Clients

More information coming at a future date. We are only handling CyberDrain hosted migrations at this time.

# Custom Domains

{% hint style="info" %}
## CyberDrain Hosted Next Generation Migration

For those who have just migrated to the next generation of CIPP infrastructure, you must use the [management portal](https://management.cipp.app/) to readd your custom domain as CIPP itself is missing some of the permissions to manage the move of the domain from your old instance.
{% endhint %}

The Custom Domains page maps custom domains onto the Azure App Service that hosts this CIPP instance, so you can reach CIPP on your own hostname instead of the default `*.azurewebsites.net` address. Setting up a domain involves a DNS ownership record and an alias record, a hostname binding on the App Service, and an optional free managed TLS certificate. A wizard walks through all three and can be reopened at any time to finish or fix a domain. The default `*.azurewebsites.net` hostname always remains available.

## App Service Details

The App Service card shows the read-only details you need when creating DNS records for a custom domain.

| Field                  | Description                                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| Site name              | The name of the App Service hosting this CIPP instance.                                                 |
| Default hostname       | The App Service's default hostname. Use this as the CNAME target when adding a subdomain.               |
| Inbound IP (A record)  | The App Service's inbound IP address. Use this as the A record value when adding an apex (root) domain. |
| Domain verification ID | The value for the ownership TXT record (at `asuid.<domain>`). Only needed for apex, wildcard, or proxied domains — a subdomain CNAME proves ownership on its own. |

## Table Details

The Custom Domains table lists every hostname bound to the App Service. Selecting a row opens a details flyout showing the hostname, its SSL state, the binding type, and — where a certificate is present — its thumbprint and expiry date.

| Column   | Description                                                                                                                                                                                             |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Hostname | The domain bound to the App Service.                                                                                                                                                                    |
| Status   | The security state of the binding: Default (Azure-managed) for the built-in hostname, Secured (SNI SSL) or Secured (IP SSL) when a certificate is bound, or Not secured when no certificate is present. |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Manage / Fix</td><td>Reopens the setup wizard for the selected domain so you can finish or repair its configuration. Available for custom domains only.</td><td>true</td></tr><tr><td>Remove domain</td><td>Removes the custom domain from the CIPP App Service, along with any managed certificate for it. The default hostname is unaffected. Available for custom domains only.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

## Adding or Fixing a Domain

Select **Add Custom Domain** to start the wizard, or use **Manage / Fix** on an existing domain to resume where it left off. The wizard has three steps.

{% stepper %}
{% step %}
### Verify domain ownership

Enter the fully qualified domain CIPP should answer on. This can be a subdomain (for example `portal.contoso.com`), an apex domain (`contoso.com`), or a wildcard (`*.contoso.com`). The wizard then lists the DNS records to create at your DNS provider:

* An **Alias** record: a CNAME pointing to the App Service default hostname for a subdomain, or an A record pointing to the inbound IP for an apex domain.
* For apex and wildcard domains only, an **Ownership** TXT record at `asuid.<domain>`, set to the domain verification ID. A subdomain's CNAME proves ownership on its own, so no TXT record is needed there.

Create the records, then select **Check DNS** to verify them. Once verified you can continue. Two situations are handled gracefully: a wildcard domain is verified by ownership alone (its alias is validated by Azure when the binding is created), and a proxied alias — such as a Cloudflare "orange-cloud" record — is not visible to the check, in which case the wizard asks for the ownership TXT record instead and Azure makes the final check at binding time.

{% hint style="warning" %}
If an `asuid.<domain>` TXT record exists from a previous setup with a different value, **remove it**. A stale verification record blocks Azure's validation even when the CNAME is correct.
{% endhint %}
{% endstep %}

{% step %}
### Create hostname binding

The wizard creates the hostname binding on the App Service. Azure re-validates the DNS records as part of this step.
{% endstep %}

{% step %}
### Enable HTTPS certificate

The wizard provisions a free App Service Managed Certificate for the domain and enables the SNI SSL binding, which can take a minute or two. If the domain's alias is proxied through a CDN, temporarily set it to DNS-only while the certificate is issued and re-enable the proxy afterwards, since issuance validates the domain directly.

Wildcard domains are the exception: App Service Managed Certificates do not support them, so you will need to upload your own certificate and binding from the Azure Portal to secure a wildcard domain.
{% endstep %}
{% endstepper %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}

# Breach Lookup

Breach Lookup checks a single email address or domain against known breach data on demand, returning one card per breach the address appears in. Use it to investigate a specific account, or as the follow-up when an address turns up in a tenant-wide search.

Nothing on this page is tenant-scoped. Any address or domain can be checked, whether or not it belongs to a tenant you manage.

{% hint style="warning" %}
This page is in beta and may not always give expected results.
{% endhint %}

## Breach Lookup

Enter an **Email address or domain name** and select **Check**.

The two inputs are answered differently. An address containing `@` is checked against Have I Been Pwned directly and returns the full breach record for each breach the account appears in. A bare domain is checked against CIPP's breach service instead, which returns the breaches associated with that domain.

{% hint style="info" %}
Looking up an email address requires a [have-i-been-pwned.md](../../cipp/integrations/have-i-been-pwned.md "mention") API key on your instance. Where no key is configured, the lookup fails with a connection error rather than returning an empty result. CyberDrain hosted tenants receive a complimentary key. Be sure to enable the integration to leverage the full functionality of this lookup.
{% endhint %}

## Results

Where breaches are found, each one is shown as its own card headed with the breach name and the breached service's logo. An export button above the results downloads the full set as a CSV.

| Field                      | Description                                                                                                                                                                                                                                                                    |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Partial Password Available | Whether the breach data includes a password for this account. Where one is available, a copy button places it on the clipboard without displaying it on screen.                                                                                                                |
| Description                | The breach's published description, explaining what happened and when.                                                                                                                                                                                                         |
| Domain                     | The domain of the breached service, linked so you can read more about it.                                                                                                                                                                                                      |
| Leaked Data classes        | The categories of information exposed in the breach, such as email addresses, passwords, or physical addresses. Each is shown as its own chip.                                                                                                                                 |
| Breach Information         | Chips describing the nature of the breach, such as whether it is verified, sensitive, fabricated, retired, a spam list, sourced from malware, or drawn from a stealer log. Only the characteristics that apply are shown, so a card with few chips is not missing information. |

Where nothing is found, a **No breaches detected** card is shown in place of the results. This is a genuine answer rather than a failure: an account with no breach history returns no results.

Where the lookup could not be completed, an **Error** card reports that the connection to the breach service failed, along with the underlying error where one was returned.

{% hint style="info" %}
Password data is generally only returned for domain lookups. A breach record for an individual account normally carries the breach's details rather than the credentials themselves, so **Partial Password Available** will often read No even where the account is genuinely affected.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}

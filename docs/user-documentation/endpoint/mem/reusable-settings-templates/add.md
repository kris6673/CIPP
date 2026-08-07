# Add Reusable Settings Template

Creates a reusable settings template in CIPP holding a Microsoft Defender Firewall dynamic keyword address list. The template can then be deployed to tenants from [reusable-settings](../reusable-settings/ "mention") or applied through a [standards](../../../tenant/standards/ "mention"). Templates are stored in CIPP rather than in a tenant.

## Template

| Field                          | Description                                                                                                                                                                                            |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Template / Policy Display Name | The name of the template. Required. This is also the name the reusable setting takes when it is created in a tenant, and the name CIPP matches on when deciding whether to update an existing setting. |
| Template / Policy Description  | The description recorded against the template.                                                                                                                                                         |

## Group Setting Collection (Policy)

Each row in this table is one entry in the address list. **Add row** appends another, and **Remove** deletes one.

| Field       | Description                                                                                                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Autoresolve | Whether the keyword is resolved to the addresses it currently points at. Set to True for a domain name that should be resolved, and False for an address or range supplied directly. |
| Keyword     | The domain, IP address or address range the entry covers. Wildcards are allowed using the `*` character, and CIPP variables can be inserted so the value differs per tenant.         |

{% hint style="info" %}
Each entry also carries an identifier, which CIPP generates automatically and does not show. Nothing needs entering for it.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}

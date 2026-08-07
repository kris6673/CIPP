# Edit Reusable Settings Template

Opens a saved reusable settings template so its name, description and address list can be changed. Edits are stored against the template in CIPP, so they take effect the next time the template is deployed rather than changing any reusable setting already created in a tenant.

The form is the same as [add.md](add.md "mention"), populated with the template's stored configuration.

## Template

| Field                          | Description                                    |
| ------------------------------ | ---------------------------------------------- |
| Template / Policy Display Name | The name of the template. Required.            |
| Template / Policy Description  | The description recorded against the template. |

## Group Setting Collection (Policy)

Each row is one entry in the address list. **Add row** appends another and **Remove** deletes one. Rows added here are given an identifier automatically; rows already in the template keep the identifier they were saved with.

| Field       | Description                                                                                                                                                                  |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Autoresolve | Whether the keyword is resolved to the addresses it currently points at.                                                                                                     |
| Keyword     | The domain, IP address or address range the entry covers. Wildcards are allowed using the `*` character, and CIPP variables can be inserted so the value differs per tenant. |

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}

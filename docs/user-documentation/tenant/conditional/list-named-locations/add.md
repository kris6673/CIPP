# Add Named Location

This page creates a Conditional Access named location. Unlike most pages in CIPP, it is not limited to the tenant selected in the menu bar: you choose the tenants explicitly, and the same named location is created in each of them. That makes it a quick way to roll a standard office IP range or country restriction out across your estate in one pass.

## Fields

| Field               | Description                                                                                                                   |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Select Tenants      | The tenants to create the named location in. At least one is required, and All Tenants is available.                          |
| Named Location Name | The name of the location, as it will be referenced by Conditional Access policies. Required.                                  |
| Type of Location    | Either **Countries Location** or **IP Location**. The remaining fields depend on this choice. Defaults to Countries Location. |

### Countries Location

| Field                                 | Description                                                             |
| ------------------------------------- | ----------------------------------------------------------------------- |
| Countries                             | The countries or regions the location covers. At least one is required. |
| Include unknown countries and regions | Includes addresses that cannot be mapped to a country. Off by default.  |

### IP Location

| Field                    | Description                                                                                   |
| ------------------------ | --------------------------------------------------------------------------------------------- |
| IPs                      | The address ranges, one per line, in CIDR format, for example `111.111.111.111/24`. Required. |
| Mark as trusted location | Marks the location as trusted. Off by default.                                                |

{% hint style="info" %}
A named location is either country-based or IP-based, never both. If you need to combine the two in a policy, create separate named locations and reference them together in the policy's location condition.
{% endhint %}

{% hint style="warning" %}
Creating the same named location across several tenants gives you locations that share a name but are separate objects, each with its own identifier. Later edits are per tenant, so if the underlying ranges change you will need to update each one, either from the named locations list or by creating a replacement here.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}

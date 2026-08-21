# Add Mapping

Create a new mapping. The fields shown depend on the source type you select, because automatic synchronisation and manual entry need different information.

## Tenant Selection

Select the tenants the mapping applies to. More than one tenant can be selected, and All Tenants applies the mapping everywhere including tenants added later.

## Source Type

| Source Type  | Description                                                                                                                                         |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Reporting DB | Copies values from data CIPP already caches for the tenant into the custom data attribute, on a daily schedule.                                     |
| Manual Entry | Turns the custom data attribute into a field on the Add User and Edit User forms, and makes it available in the User Patch Wizard for bulk updates. |

## Source Details

Shown when the source type is Reporting DB.

| Field                  | Description                                                                                                                           |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| Extension Sync Dataset | The cached dataset the value is read from. The panel alongside the form shows the dataset name and a description of what it contains. |
| Source Property        | The individual property within the dataset to copy. Shown only for datasets that expose individual properties.                        |

The available datasets are:

| Dataset             | Contents                                                                                                                     | Matched on                                            |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| Mailboxes           | User mailbox properties such as type, quotas, forwarding, holds, and email addresses. Properties are mapped individually.    | Mailbox directory object ID to the user's ID.         |
| Mailbox Permissions | Mailbox permission entries, stored as JSON in a multi-valued attribute. Each entry records the user and their access rights. | Mailbox identity to the user's ID or mail nickname.   |
| CAS Mailbox         | Client access settings such as OWA, IMAP, POP, MAPI, EWS, and ActiveSync state. Properties are mapped individually.          | Mailbox directory object ID to the user's ID.         |
| Mailbox Usage       | Mailbox size and item counts from the usage reports, including quota status. Properties are mapped individually.             | User principal name.                                  |
| One Drive Usage     | OneDrive site URL, file counts, storage used and allocated, and last activity date. Properties are mapped individually.      | Site owner principal name to the user principal name. |

## Destination Details

Shown when the source type is Reporting DB.

| Field                 | Description                                                                                                                                                                                       |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Directory Object Type | The directory object type the value is written to. User is currently the only supported option.                                                                                                   |
| Destination Property  | The custom data attribute to write to. The list is filtered to attributes compatible with the selected dataset, so array datasets such as Mailbox Permissions only offer multi-valued attributes. |

## Manual Entry Configuration

Shown when the source type is Manual Entry.

| Field                 | Description                                                                                                                                              |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Field Label           | The label shown to technicians on the user forms, for example Employee ID or Department. Choose something meaningful rather than the raw attribute name. |
| Directory Object Type | The directory object type the field applies to. User is currently the only supported option.                                                             |
| Attribute             | The custom data attribute the entered value is written to. The list is filtered to attributes that target the selected object type.                      |

{% hint style="info" %}
The form control CIPP renders follows the attribute's data type. Boolean attributes become a toggle, DateTime attributes become a date picker, and everything else becomes a text field.
{% endhint %}

{% hint style="warning" %}
Reporting DB mappings synchronise on a daily schedule per tenant and depend on CIPP having cached data for that tenant. Values will not appear immediately after saving the mapping.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}

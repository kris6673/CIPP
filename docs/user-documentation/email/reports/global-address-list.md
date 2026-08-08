---
description: The Global Address List for the selected tenant, and what is hidden from it.
---

# Global Address List

This report lists every recipient in the selected tenant's Global Address List, covering mailboxes, shared mailboxes, resources, mail contacts, and mail enabled groups. Its main use is checking what is and is not visible in the address book, and hiding or unhiding entries without going near Exchange Online PowerShell.

## Filters

Preset filters are available from the **Filters** button:

| Filter                | Shows                                                                    |
| --------------------- | -------------------------------------------------------------------------- |
| Hidden from GAL       | Recipients that are hidden from the address list.                        |
| Shown in GAL          | Recipients that appear in the address list.                              |
| Cloud only mailboxes  | Recipients that are not synchronised from on-premises Active Directory.  |

## Table Details

The properties returned are for the Exchange Online PowerShell command `Get-Recipient`. For more information on the command please see the [Microsoft documentation](https://learn.microsoft.com/powershell/module/exchangepowershell/get-recipient).

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Unhide from Global Address List</td><td>Puts the entry back in the address book so people can find it when composing mail. Greyed out where the entry is already visible.</td><td>true</td></tr><tr><td>Hide from Global Address List</td><td>Takes the entry out of the address book. Mail addressed to it directly still arrives. Greyed out where the entry is already hidden.</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

Both actions confirm first, and both apply to mailbox backed recipients only. Running them against a mail contact or a mail enabled group returns an error.

{% hint style="warning" %}
Where **Is Dir Synced** is `Yes`, the entry is owned by on-premises Active Directory. Make the change on the on-premises object instead, or directory synchronisation will put the old value back.
{% endhint %}

***

{% include "../../../../.gitbook/includes/feature-request.md" %}

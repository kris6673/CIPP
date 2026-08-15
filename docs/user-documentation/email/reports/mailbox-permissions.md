# Mailbox Permissions

This report shows who has been granted access to whose mailbox across the selected tenant, covering Full Access, Send As, and Send on Behalf grants. It can be read either way round, listing what each user can reach or listing who can reach each mailbox, and unwanted grants can be removed in bulk from the table.

## Action Buttons

<details>

<summary>By User / By Mailbox</summary>

Switches how the report is grouped. **By User** is the default and gives one row per user with the mailboxes they can reach. Clicking it changes to **By Mailbox**, which gives one row per mailbox with the users who can reach it. The columns and the removal options change with the grouping.

</details>

## Table Details

In the **By User** grouping:

| Column            | Description                                                                             |
| ----------------- | ----------------------------------------------------------------------------------------- |
| User              | The person who has been granted access to one or more mailboxes.                        |
| User Mailbox Type | The kind of mailbox that person has of their own, or `Unknown` where they have none.    |
| Permissions       | The mailboxes this person can reach. See the note below.                                |

In the **By Mailbox** grouping:

| Column               | Description                                                                        |
| -------------------- | ------------------------------------------------------------------------------------ |
| Mailbox UPN          | The address of the mailbox the row describes.                                      |
| Mailbox Display Name | The friendly name of that mailbox.                                                 |
| Mailbox Type         | The kind of mailbox, for example `UserMailbox` or `SharedMailbox`.                 |
| Permissions          | The users who can reach this mailbox. See the note below.                          |

**Permissions** is a button labelled with the number of entries behind it. Clicking it opens the detail: in the **By User** grouping that is the mailbox, its address, and the access rights, and in the **By Mailbox** grouping it is the user and the access rights.

The `NT AUTHORITY\SELF` grant that every mailbox carries is left out, as are inherited deny entries, so a mailbox with no delegated access does not appear at all.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Bulk Remove Mailbox Permissions</td><td>Takes away the grants you choose from the selected row(s). The <strong>Permissions to remove</strong> list is built from the rows you selected, so it only ever offers grants that really exist. In the <strong>By User</strong> grouping you pick mailbox and access right pairs and the selected user loses access to those mailboxes; in the <strong>By Mailbox</strong> grouping you pick user and access right pairs and those users lose access to the selected mailboxes.</td><td>true</td></tr></tbody></table>

Both groupings are refreshed once the removal completes, so the report reflects the change straight away.

{% include "../../../../.gitbook/includes/feature-request.md" %}

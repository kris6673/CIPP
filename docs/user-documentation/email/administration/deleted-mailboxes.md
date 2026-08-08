# Deleted Mailboxes

This page lists the soft-deleted mailboxes in the selected tenant, which are mailboxes Exchange Online is still holding after deletion and before it purges them for good. Use it to confirm what was deleted and when, and to check whether a mailbox is still recoverable before starting a restore.

## Table Details

| Column                 | Description                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------------- |
| Display Name           | The name the mailbox had when it was deleted.                                                                 |
| When Soft Deleted      | When the mailbox was deleted, and therefore when its retention window started.                                |
| UPN                    | The user principal name of the account the mailbox belonged to.                                               |
| Primary Smtp Address   | The address the mailbox received mail on.                                                                     |
| Recipient Type Details | The kind of mailbox it was, for example `UserMailbox` or `SharedMailbox`.                                     |
| Archive Enabled        | Whether the mailbox had an online archive.                                                                    |
| Retention Policy       | The messaging records management retention policy that was applied to the mailbox.                            |
| In Place Holds         | Any holds that were in force on the mailbox. A mailbox under hold is kept beyond the normal retention window. |

The page is read only and has no row actions. To bring a mailbox back, use the mailbox restore tools.

***

{% include "../../../../.gitbook/includes/feature-request.md" %}

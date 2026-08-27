# Calendar Permissions

This report shows who has been granted access to whose calendar across the selected tenant. It can be read either way round, listing what each user can see or listing who can see each calendar, which makes it a quick way to audit delegated calendars without checking mailboxes one at a time.

## Action Buttons

<details>

<summary>By User / By Calendar</summary>

Switches how the report is grouped. **By User** is the default and gives one row per user with the calendars they can reach. Clicking it changes to **By Calendar**, which gives one row per calendar with the users who can reach it. The columns change with the grouping.

</details>

## Table Details

In the **By User** grouping:

| Column            | Description                                                                                                    |
| ----------------- | ---------------------------------------------------------------------------------------------------------------- |
| User              | The person who has been granted access to one or more calendars.                                               |
| User Mailbox Type | The kind of mailbox that person has of their own, or `Unknown` where they have none.                           |
| Permissions       | The calendars this person can reach. See the note below.                                                       |

In the **By Calendar** grouping:

| Column                | Description                                                                        |
| --------------------- | ------------------------------------------------------------------------------------ |
| Calendar UPN          | The address of the mailbox whose calendar the row describes.                       |
| Calendar Display Name | The friendly name of that mailbox.                                                 |
| Calendar Type         | The kind of mailbox, for example `UserMailbox` or `SharedMailbox`.                 |
| Permissions           | The users who can reach this calendar. See the note below.                         |

**Permissions** is a button labelled with the number of entries behind it. Clicking it opens the detail: in the **By User** grouping that is the calendar, its address, the access rights, and the calendar folder name, and in the **By Calendar** grouping it is the user, the access rights, and the folder name.

The `Default` and `Anonymous` entries that every calendar carries are left out, so a calendar with no explicit delegate does not appear at all. The folder name is worth reading where a mailbox was created in another language, because the calendar folder is named in that language rather than being called Calendar.

{% include "../../../../.gitbook/includes/feature-request.md" %}

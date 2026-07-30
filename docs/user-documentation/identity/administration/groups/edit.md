# Edit Group

The Edit Group page changes the properties, membership, and settings of an existing group. Membership is managed by adding and removing users, groups, contacts, and devices rather than by editing a list, so each save applies the additions and removals you have specified. Which fields appear depends on the group's type — Microsoft 365, Security, Mail-Enabled Security, or Distribution List — since not every setting applies to every kind of group. A group synced from on-premises Active Directory shows a warning at the top of the page: changes to those groups should be made on-premises instead, as edits made here will be overwritten by the next sync.

## Viewing Current Membership

A button beside the page title switches between the editing form and a read-only view of the group's current membership. Select **View members** to see who is currently in the group, and **Edit Membership** to return to the form.

| Column              | Description                                                       |
| ------------------- | ----------------------------------------------------------------- |
| Type                | Whether the entry is an Owner, a Member, or a Contact.            |
| User Principal Name | The sign-in name of the user, or the email address for a contact. |
| Display Name        | The name of the user or contact.                                  |

## Group Properties

| Setting          | Description                                                                                                 |
| ---------------- | ----------------------------------------------------------------------------------------------------------- |
| Display Name     | The name of the group as it appears to users.                                                               |
| Description      | A description of the group's purpose.                                                                       |
| Mail Nickname    | The alias used in the group's email address.                                                                |
| Membership Rules | The rule that determines which objects belong to the group. Shown only for groups using dynamic membership. |

## Add Members

Anything selected here is added to the group when you save. Objects that already belong to the group are filtered out of the lists, so you cannot add the same member twice.

| Setting                       | Description                                                                                                                                                                     |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Add Members (Users or Groups) | Adds users or other groups as members. Several can be selected at once.                                                                                                         |
| Add Owners                    | Adds users as owners of the group.                                                                                                                                              |
| Add Contacts                  | Adds mail contacts as members.                                                                                                                                                  |
| Add Devices                   | Adds devices as members. Devices are listed by name and several can be selected. Not shown for Distribution List or Mail-Enabled Security groups, which cannot contain devices. |

## Remove Members

Anything selected here is removed from the group when you save. The lists show only the group's current members, owners, and contacts.

| Setting                          | Description                                          |
| -------------------------------- | ---------------------------------------------------- |
| Remove Members (Users or Groups) | Removes the selected users or groups from the group. |
| Remove Owners                    | Removes the selected users as owners.                |
| Remove Contacts                  | Removes the selected mail contacts.                  |

## Group Settings

These settings apply to mail-enabled groups, and which of them appear depends on the group's type.

| Setting                                                       | Description                                                                                                                 | Shown for                        |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| Group visibility                                              | Whether the group is Public, so anyone can see its content and join, or Private, so membership is controlled by the owners. | Microsoft 365                    |
| Let people outside the organization email the group           | Allows senders from outside your organisation to email the group.                                                           | Microsoft 365, Distribution List |
| Send Copies of team emails and events to team members inboxes | Delivers a copy of the group's messages and calendar events to each member's own mailbox.                                   | Microsoft 365                    |
| Hide group mailbox from Outlook                               | Hides the group's mailbox from Outlook clients.                                                                             | Microsoft 365                    |
| Security Enabled                                              | Marks the group as security enabled, so it can be used to grant access to resources as well as for mail.                    | Microsoft 365                    |

## Licences

Licences assigned to a group are applied automatically to everyone in it, which is how group-based licensing is managed. Changes can take a few minutes to take effect. This section is shown for Security groups that are not synced from on-premises Active Directory.

The licences currently assigned to the group are listed above the fields.

| Setting         | Description                                                                                                                     |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Add Licenses    | Assigns one or more licences to the group, which are then applied to all of its members.                                        |
| Remove Licenses | Removes one or more of the licences currently assigned to the group. The list contains only the licences the group already has. |

## Saving

Select Save to apply your changes. Additions and removals are processed together, and only the settings you have actually changed are submitted, so leaving a toggle untouched will not overwrite it. Where an individual change cannot be applied — for example adding a device to a group type that does not support devices — the result reports that item as an error while the remaining changes still go through.

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}

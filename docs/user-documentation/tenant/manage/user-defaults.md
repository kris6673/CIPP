# User Defaults

This page will allow you to manage your new user default templates.

## Action Buttons

<details>

<summary>Add Template</summary>

Opens a modal to allow you to create a new template. Enter the Template Name and set your desired user attributes. You can optionally set the template to be the default for the tenant. Note, the form will remain open with your changes displayed. This will allow you to quickly create multiple, similar templates.

</details>

### Shared Mailboxes and Calendars

A template can list the tenant's shared mailboxes that every new user should get access to, and separately the shared mailboxes whose **calendar** they should get access to, each with the level to grant (`Shared Mailbox Permissions`, one or more of Full Access, Send As and Send on Behalf, defaults to `Full Access`; `Shared Calendar Permission`, defaults to `Editor`). Both lists are pre-filled on the **Add User** form and can still be changed per user.

{% hint style="info" %}
Mailbox access with Full Access is automapped, so Outlook adds the mailbox on its own. Calendar access cannot work that way: it is granted with a sharing invitation, and the user adds the calendar by clicking the link in the email they receive.

Since a brand-new user is not a usable Exchange recipient right away, both grants are queued as scheduled tasks that run **15 minutes after the user is created**, visible under **CIPP > Scheduler**. For calendars, only the access levels Exchange sends an invitation for are offered: `Editor`, `Reviewer`, `Limited Details` and `Availability Only`.
{% endhint %}

## Table Details

Your existing templates will be displayed in this table along with the attributes that you have set.

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Edit Template</td><td>Opens the selected template to allow you to change the attributes that were previously set.</td><td>false</td></tr><tr><td>Delete Template</td><td>Opens a modal to confirm deletion of the selected template(s)</td><td>true</td></tr><tr><td>More Info</td><td>Opens the Extended Info flyout with the full details for the selected row.</td><td>false</td></tr></tbody></table>

***

{% include "../../../../.gitbook/includes/feature-request.md" %}

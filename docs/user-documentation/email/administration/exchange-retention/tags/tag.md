# Add/Edit Tag

This page creates a retention tag, or opens an existing one for editing when you arrive from the **Edit Tag** action. The two modes use the same form, with one difference: **Tag Type** can only be set when the tag is created, so it is locked when you are editing.

| Field              | Description                                                                                                                                                                                                                                                                                          |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Tag Name           | The name the tag is listed and selected under. Required.                                                                                                                                                                                                                                             |
| Tag Type           | What the tag applies to. Required, and fixed once the tag exists. `Personal` is the type users apply themselves, `All` is a default policy tag covering the whole mailbox, and the remaining options target a single default folder such as `Inbox`, `Sent Items`, `Deleted Items`, or `Junk Email`. |
| Retention Action   | What happens when the age limit is reached: **Delete and Allow Recovery**, **Permanently Delete**, **Move to Archive**, or **Mark as Past Retention Limit**.                                                                                                                                         |
| Age Limit (Days)   | How many days a message is kept before the retention action is applied.                                                                                                                                                                                                                              |
| Retention Enabled  | Whether the tag actually acts on mail. Turning it off leaves the tag in place but stops it doing anything, which is the usual way to suspend a tag without unlinking it from its policies.                                                                                                           |
| Comment            | Free text stored with the tag, useful for recording why it exists.                                                                                                                                                                                                                                   |
| Localized Tag Name | A display name shown to users whose Outlook runs in another language.                                                                                                                                                                                                                                |
| Localized Comment  | A comment shown to users whose Outlook runs in another language.                                                                                                                                                                                                                                     |

{% hint style="info" %}
A tag on its own does nothing. It has to be added to a retention policy on [policy.md](../policies/policy.md "mention"), and that policy applied to a mailbox, before it affects any mail.
{% endhint %}

{% include "../../../../../../.gitbook/includes/feature-request.md" %}

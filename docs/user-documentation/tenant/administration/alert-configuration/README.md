# Alert Configuration

Alerts in CIPP come in two flavours, and both are listed here. Audit log alerts watch the Microsoft 365 audit log and fire as matching entries arrive. Scripted alerts run on a recurring schedule and check a specific condition each time they execute. This page shows every configured alert rule of both kinds, with the tenants they cover and what happens when they trigger, and lets you edit, clone or remove them.

## Action Buttons

Use [alert.md](alert.md "mention") to create a new alert rule of either type.

## Table Details

| Column           | Description                                                                                                                                                                                                                             |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Tenants          | The tenants or tenant groups the alert is scoped to.                                                                                                                                                                                    |
| Event Type       | Whether the rule is an audit log alert (`Audit log Alert`) or a scripted alert that runs on a schedule (`Scheduled Task`).                                                                                                              |
| Conditions       | For audit log alerts, the configured conditions written out in plain language, joined with "and" when more than one is set. For scripted alerts, the name of the alert being run.                                                       |
| Repeats Every    | How often the alert runs. Audit log alerts show `When received`, as they fire as matching log entries arrive; scripted alerts show their configured recurrence.                                                                         |
| Actions          | What CIPP does when the alert triggers. For audit log alerts this is the list of chosen response actions, such as generating a ticket or disabling the user in the log entry. For scripted alerts it is the configured delivery method. |
| Alert Comment    | The optional free-text comment saved with the alert.                                                                                                                                                                                    |
| Excluded Tenants | Any tenants or tenant groups left out of the alert's scope.                                                                                                                                                                             |

{% hint style="info" %}
Excluded tenants only apply where the alert is scoped broadly, such as to all tenants or to a tenant group. A scripted alert that names its tenants individually has nothing to exclude, so this column stays empty.
{% endhint %}

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>View Task Details</td><td>Opens the underlying scheduled task, showing its run history and results. Only available for rows with an Event Type of Scheduled Task.</td><td>false</td></tr><tr><td>Edit Alert</td><td>Opens the alert for editing so its tenants, conditions, schedule and actions can be adjusted and saved back over the existing rule.</td><td>false</td></tr><tr><td>Clone &#x26; Edit Alert</td><td>Opens a copy of the alert for editing, saving it as a new rule and leaving the original untouched. Useful for applying the same alert to a different set of tenants.</td><td>false</td></tr><tr><td>Delete Alert</td><td>Removes the alert rule after confirmation. The alert stops firing immediately and cannot be recovered.</td><td>true</td></tr></tbody></table>

{% include "../../../../../.gitbook/includes/feature-request.md" %}

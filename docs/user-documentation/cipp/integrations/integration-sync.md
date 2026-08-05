# Integration Sync

This page lists the scheduled synchronisation tasks that push CIPP's cached tenant data out to your configured integrations, along with when each one last ran and what the result was. It is the quickest way to confirm that an integration is actually syncing rather than silently failing.

Only integrations that register a recurring push task appear here. In practice that means Hudu and Custom Data, each of which gets one task per mapped tenant. Integrations that sync on demand or through their own orchestrator, such as NinjaOne and Gradient, do not create tasks in this table. If you have upgraded from an older release you may briefly see legacy sync tasks listed; these are removed automatically the next time the sync tasks are registered.

## Table Details

| Column         | Description                                                                                                                         |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Tenant         | The tenant the sync task runs for. Each mapped tenant gets its own task.                                                            |
| Sync Type      | The integration the task belongs to.                                                                                                |
| Scheduled Time | The relative time until the next run.                                                                                               |
| Executed Time  | The relative time since the task was last picked up.                                                                                |
| Repeats Every  | The recurrence of the task. Extension sync tasks are registered to run daily.                                                       |
| Results        | The outcome of the last run. Where the task recorded structured output, it is shown as an expandable object rather than plain text. |

The underlying task name, for example `Hudu Extension Sync`, is also returned and can be shown by adding the **Name** column.

{% hint style="info" %}
Scheduled tasks are picked up on the quarter hour (:00, :15, :30, :45). Anything due or overdue is collected at the next quarter hour, so the Scheduled Time tells you which one your task will land on rather than the exact minute it will run.
{% endhint %}

{% hint style="warning" %}
Tasks are created and removed automatically when you change an integration's tenant mappings, so there is nothing to add or delete here. A tenant disappearing from this table usually means its mapping was removed rather than that the sync has broken.
{% endhint %}

***

{% include "../../../../.gitbook/includes/feature-request.md" %}

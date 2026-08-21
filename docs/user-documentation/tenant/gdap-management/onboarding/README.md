# Onboarding

Onboarding tenants can be a challenge sometimes, especially when you haven't really taken care of your GDAP environments yet. CIPP handles the work for you: tenant onboarding automatically adds missing groups, adds missing users, and finishes everything off, removing all of the manual GDAP labour except accepting the invite.

This page lists previous and in-progress onboarding attempts, so you can see how far each one got and retry any that failed. Use the [start.md](start.md "mention") button to begin a new one.

## Table Details

| Column                                 | Description                                                                             |
| -------------------------------------- | --------------------------------------------------------------------------------------- |
| Timestamp                              | When the onboarding was last updated.                                                   |
| Relationship - Customer - Display Name | The customer tenant the onboarding relates to.                                          |
| Status                                 | The overall state of the onboarding, for example queued, running, succeeded, or failed. |
| Onboarding Steps                       | The individual steps and their current status. See below.                               |
| Logs                                   | The detailed log entries recorded during the run, useful for diagnosing a failure.      |

### Onboarding Steps

Each onboarding runs through the same five steps in order.

| Step                       | Description                                                                            |
| -------------------------- | -------------------------------------------------------------------------------------- |
| Step 1: GDAP Invite        | Confirms the relationship has been approved by the customer and is active.             |
| Step 2: GDAP Role Test     | Checks the relationship contains the roles CIPP expects.                               |
| Step 3: GDAP Group Mapping | Assigns the relationship's roles to the mapped security groups in your partner tenant. |
| Step 4: CPV Refresh        | Refreshes the CIPP-SAM application's consent in the customer tenant.                   |
| Step 5: Graph API Test     | Confirms CIPP can successfully call Microsoft Graph against the tenant.                |

## Table Actions

<table><thead><tr><th>Action</th><th>Description</th><th data-type="checkbox">Bulk Action Available</th></tr></thead><tbody><tr><td>Cancel Onboarding</td><td>Stops an onboarding that is still in progress.</td><td>true</td></tr><tr><td>Retry Onboarding</td><td>Runs a failed onboarding again.</td><td>true</td></tr></tbody></table>

{% hint style="info" %}
Onboarding also runs on a nightly schedule, so an approved invite is picked up automatically even if you never start the process by hand.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}

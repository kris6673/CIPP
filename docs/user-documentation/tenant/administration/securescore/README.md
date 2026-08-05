# Secure Score

This page provides an overview of the Secure Score of the tenant. The default page view is with each secure score component displayed as a card.

## All Tenants

When the tenant selector is set to **All Tenants**, the page shows an estate-wide view instead of the per-tenant cards, built from the nightly score cache:

* **Tenant Overview tab**: the portfolio average, its change across the retained history, and the highest and lowest scoring tenants, alongside a portfolio trend chart and Top 5 / Bottom 5 leaderboards. Selecting a tenant on a leaderboard opens that tenant's own Secure Score page.
* **Table Overview tab**: every tenant's latest cached score in a sortable, exportable table, with an action to jump to the tenant's own Secure Score page.

{% hint style="info" %}
Scores appear after the nightly cache job has run, so a freshly added tenant will not show a score until the next refresh cycle.
{% endhint %}

The filters and card actions below apply to the per-tenant view.

## Filters

| Filter                | Description                                                                                                            |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| All Recommendations   | Shows all Secure Score recommendations regardless of status.                                                           |
| Completed (100%)      | Shows all Secure Score recommendations that have been completed.                                                       |
| Not Started (0%)      | Shows all Secure Score recommendations that have not been started.                                                     |
| In Progress (Started) | Shows all secure score recommendations that have been started but not completed. This is anything from 1-99% complete. |

## Card Actions

| Action        | Description                                                                                                  |
| ------------- | ------------------------------------------------------------------------------------------------------------ |
| Change Status | Opens a modal that allows you to change the status of the score component                                    |
| Remediate     | Will launch the appropriate Microsoft portal or recommended CIPP standard to remediate this score component. |
| Updates       | Displays a chart of updates to the score since CIPP started tracking                                         |

***

### Feature Requests / Ideas

We value your feedback and ideas. Please raise any [feature requests](https://github.com/KelvinTegelaar/CIPP/issues/new?assignees=\&labels=enhancement%2Cno-priority\&projects=\&template=feature.yml\&title=%5BFeature+Request%5D%3A+) on GitHub.

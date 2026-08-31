# Mail Flow Statistics

This page charts the selected tenant's mail flow over the last 7, 14, 30 or 90 days: how much mail arrived, how much of it was good, and how much Exchange Online stopped as spam, phishing or malware. A stacked bar chart breaks the dispositions down by day, a donut splits traffic by direction (inbound, outbound and intra-org), and two tables list the top mail senders and the top spam recipients.

## Where the numbers come from

The daily disposition counts come from the Exchange Online `Get-MailFlowStatusReport` cmdlet, and the top sender and top spam recipient tables from `Get-MailTrafficSummaryReport`. Both support at most 90 days of history, which is why the period selector stops there.

{% hint style="info" %}
This page reports on a single tenant at a time — it is not available in All Tenants mode.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}

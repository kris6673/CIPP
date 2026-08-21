# Bulk Add Sites

Creates several SharePoint sites at once from a CSV upload.

{% stepper %}
{% step %}
### Tenant Selection

Select the tenant you want to bulk create SharePoint sites for. This will auto-select the tenant you have selected in the top menu bar.
{% endstep %}

{% step %}
### Upload CSV

{% hint style="info" %}
Select **Download Example CSV** to get a correctly formatted file to work from. The columns are `siteName`, `siteDescription`, `siteOwner`, `templateName`, `siteDesign` and `sensitivityLabel`.
{% endhint %}

Upload your CSV file, or select **Add Item** to add a row by hand.

Review the table. If a row is wrong, select **Delete Row** from the actions column and add it again.
{% endstep %}

{% step %}
### Review and Confirm

Review the information for accuracy and select **Submit**.
{% endstep %}
{% endstepper %}

{% include "../../../../.gitbook/includes/feature-request.md" %}

# Edit Group Template

This page changes a saved group template. It opens the template's stored values in the same form used to create one. The fields and the settings that appear for each group type are described on [add.md](add.md "mention").

Saving overwrites the existing template in place rather than creating a second one, because the template keeps its identifier through the edit.

{% hint style="info" %}
Groups already created from a template are not affected by editing it. A template only supplies values at the moment it is applied, so changes here take effect the next time the template is deployed.
{% endhint %}

{% hint style="warning" %}
Changing the group type on an existing template changes which settings apply to it. Values belonging to the previous type stay on the record but stop being offered, so a template switched from a Distribution List to a Security Group keeps its aliases without any way to see or clear them from this page. Where the type is wrong it is usually cleaner to create a new template and delete the old one.
{% endhint %}

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}

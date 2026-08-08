# Add/Edit Policy

This page creates a retention policy, or opens an existing one for editing when you arrive from the **Edit Policy** action. The two modes use the same form. The difference is that editing preselects the tags already linked to the policy, and saving replaces that set with whatever is selected when you submit.

| Field          | Description                                                                                                                                                                                                                                                                                                                                      |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Policy Name    | The name the policy is listed and selected under. Required.                                                                                                                                                                                                                                                                                      |
| Retention Tags | The retention tags the policy contains. More than one can be chosen, and the drop down is populated from the tags that already exist in the selected tenant, each listed as its name followed by its type in brackets. Only existing tags can be picked, so create the tag first on [tag.md](../tags/tag.md "mention") if it is not in the list. |

{% hint style="info" %}
The tag list you submit replaces the policy's existing links rather than adding to them, so removing a tag from the selection removes it from the policy.
{% endhint %}

***

{% include "../../../../../../.gitbook/includes/feature-request.md" %}

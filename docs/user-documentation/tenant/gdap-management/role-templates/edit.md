# Edit Template

Editing a role template updates the set of role mappings that future invites and onboardings will be built from. The form is the same one used to create a template, prefilled with the current name and mappings.

## Editing a Template

{% stepper %}
{% step %}
### Open the template

Selecting **Edit Template** loads the template by name and populates the form with its current role mappings.
{% endstep %}

{% step %}
### Adjust the name or mappings

Change **Template Name** to rename the template, or add and remove entries under **Select GDAP Role Mappings**. Only mappings that already exist on the roles page can be selected, and at least one is required.
{% endstep %}

{% step %}
### Save

Submitting writes the changes back. A renamed template keeps its mappings and history, as CIPP tracks the original name behind the scenes rather than creating a second template.
{% endstep %}
{% endstepper %}

{% hint style="warning" %}
Editing a template does not change GDAP relationships that were created from it. To bring an existing relationship in line with an updated template, use the **Reset Role Mapping** action on the relationships page.
{% endhint %}

{% hint style="info" %}
Renaming the template named `CIPP Defaults` causes CIPP to prompt you to recreate it, since it checks for that exact name.
{% endhint %}

{% include "../../../../../.gitbook/includes/feature-request.md" %}

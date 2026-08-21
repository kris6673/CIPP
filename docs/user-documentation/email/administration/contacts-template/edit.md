# Edit Contact Template

The **Edit Contact Template** action on [README.md](README.md "mention") opens the template on this page with its stored values filled in. The fields are the same as on [add.md](add.md "mention").

**Display Name** is read only here, because it is the name the template is listed and selected under. Everything else can be changed, and saving overwrites the existing template rather than creating a new one.

{% hint style="info" %}
Editing a template changes only the template. Contacts already created from it in a tenant are not updated, and the change is picked up the next time the template is deployed or the **Deploy Mail Contact Template** standard runs.
{% endhint %}

{% include "../../../../../.gitbook/includes/feature-request.md" %}

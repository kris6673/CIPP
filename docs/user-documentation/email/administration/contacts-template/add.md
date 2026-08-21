# Add Contact Template

This page creates a new contact template. Only the display name and email address are required, and the template is stored in CIPP rather than in any tenant, so nothing is created until it is deployed.

| Field                           | Description                                                                                        |
| ------------------------------- | -------------------------------------------------------------------------------------------------- |
| Display Name                    | The name the contact is created with, and the name the template is listed under. Required.         |
| First Name                      | The contact's first name.                                                                          |
| Last Name                       | The contact's last name.                                                                           |
| Email                           | The external address the contact routes to. Required, and validated as an email address.           |
| Hidden from Global Address List | Hides the contact from the Global Address List when it is created.                                 |
| Company Name                    | The company recorded on the contact.                                                               |
| Job Title                       | The job title recorded on the contact.                                                             |
| Website                         | A web address to record against the contact. Validated as a URL when filled in.                    |
| Street Address                  | The street part of the contact's address.                                                          |
| City                            | The city for the contact.                                                                          |
| State/Province                  | The state or province for the contact.                                                             |
| Postal Code                     | The postal code for the contact.                                                                   |
| Country                         | The country for the contact. Select a valid option from the drop down.                             |
| Mobile Phone                    | The contact's mobile number.                                                                       |
| Business Phone                  | The contact's business number.                                                                     |
| Mail Tip                        | A short message Outlook shows to anyone composing mail to this contact. Limited to 175 characters. |

**Submit** stores the template and clears the form so another can be created straight away. **Contact Templates** at the top of the page returns you to [README.md](README.md "mention").

{% hint style="warning" %}
Note that the email box does not support Custom Variable inclusion at this time.
{% endhint %}

{% include "../../../../../.gitbook/includes/feature-request.md" %}

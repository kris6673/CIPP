# Microsoft Entra Connect Report

This report lists the users, contacts and groups synchronised from on-premises Active Directory together with any provisioning errors Entra ID has recorded against them. Objects carrying an error are the ones to act on: a provisioning error means the object failed to synchronise correctly, commonly because of a duplicate attribute or an invalid value that has to be corrected on-premises.

## Table Details

CIPP queries users, contacts and groups separately and combines the results, adding the Object Type column so the rows can be told apart.

| Column                          | Description                                                                                        |
| ------------------------------- | -------------------------------------------------------------------------------------------------- |
| Display Name                    | The name of the object.                                                                            |
| Object Type                     | Whether the row is a User, Contact or Group.                                                       |
| Created Date Time               | When the object was created.                                                                       |
| On Premises Provisioning Errors | The synchronisation errors recorded against the object. Empty for an object synchronising cleanly. |

{% hint style="info" %}
Sort or filter on **On Premises Provisioning Errors** to bring the objects that need attention to the top, since the table lists every user, contact and group rather than only the ones in error.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}

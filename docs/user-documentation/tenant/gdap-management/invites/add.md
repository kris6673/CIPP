# New Invite

This page generates GDAP invites from a role template. Each invite creates a pending relationship in Partner Center and returns two links: an invite link for the customer, and an onboarding link for you.

## Generating Invites

| Field                         | Description                                                                                                      |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Select GDAP Role Template     | The role template the invite is built from. This determines which roles the relationship will request. Required. |
| Number of Invites to generate | How many invites to create in one go. Useful when preparing several tenants at once. Defaults to 1.              |
| Internal Reference Message    | An optional note recorded against each invite, for example a client name or ticket number.                       |

Once a template is selected, the **Selected Role Mappings** section lists the roles it contains and the security group each will be assigned through. Click **Add Invites** to generate them. The resulting links appear in a table at the bottom of the page.

| Link           | Description                                                                                       |
| -------------- | ------------------------------------------------------------------------------------------------- |
| Invite Url     | Send this to your client, or accept it yourself as a Global Administrator on the customer tenant. |
| Onboarding Url | Open this as a CIPP administrator to complete the onboarding process once the invite is approved. |

{% hint style="info" %}
This will ensure that the correct roles are mapped to the GDAP relationship, and test that the CIPP-SAM application is correctly pushed to the tenant. The invite needs to be accepted by a Global Administrator in the customer tenant.
{% endhint %}

{% hint style="info" %}
The onboarding process will also run on a nightly schedule, so an approved invite is picked up automatically even if you never open the onboarding link. For automated onboardings, see [partner-webhooks.md](../../../cipp/settings/partner-webhooks.md "mention") in Application Settings.
{% endhint %}

{% hint style="warning" %}
**Please note:** Any other user that needs to gain access to your Microsoft CSP Tenants will need to be manually added to these groups.\
To easily add users to these groups, you can do the following

* Create a new security group in your partner tenant with the `Microsoft Entra roles can be assigned to the group` option set to yes. Ex. GDAP\_CIPP\_Recommended\_Roles
* Add the users to the created group
* Add the created group to the individual GDAP security groups that CIPP created for you. Ex. M365 GDAP Exchange Administrator
{% endhint %}

If multiple invites are generated but not used, the unused ones can be found on the . page, where onboarding can be started again later.

{% include "../../../../../.gitbook/includes/feature-request.md" %}

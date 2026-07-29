# SSO

The SSO App Registration page manages the Entra ID app registration that backs CIPP single sign-on. From here you provision the sign-on app, repair or recreate it, rotate its client secret, choose between single- and multi-tenant login, and for advanced cases store an existing app's credentials by hand.

## App Registration Status

The top of the card shows the current state of the SSO app registration.

| Status                         | Meaning                                                                                         |
| ------------------------------ | ----------------------------------------------------------------------------------------------- |
| Not Configured                 | No SSO app registration has been set up yet.                                                    |
| App Created — Secret Pending   | The app registration was created, but its client secret has not yet been generated.             |
| App ID Stored — Secret Pending | The app's ID has been stored, but its client secret is still pending.                           |
| Secrets Stored                 | The app ID and client secret have both been stored.                                             |
| Complete                       | Single sign-on is fully configured.                                                             |
| Error                          | The last setup attempt failed. The error is shown, along with the appropriate recovery buttons. |

Once an app exists, the card also shows its Application (client) ID and the date it was created. If a setup attempt failed, an alert explains what went wrong and points to the right next step — Repair or Recreate when the app was created but the secret failed or Create when no App ID was ever saved and an orphaned CIPP-SSO app may need deleting from Entra by hand.

## Managing the SSO App

The buttons on the card change depending on the current status. The available actions are:

| Action         | Description                                                                                                                                           |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Create SSO App | Provisions the CIPP-SSO app registration in your tenant. Shown when no working app exists.                                                            |
| Repair         | Retries generating the client secret on the existing app registration. Used when the app was created but its secret could not be generated.           |
| Recreate       | Clears the current SSO record and provisions a brand-new app registration. The previous app is left in your Entra tenant for you to delete manually.  |
| Rotate Secret  | Generates a new client secret for the existing SSO app.                                                                                               |
| Save Changes   | Applies changes to the SSO settings, such as toggling multi-tenant mode. This restarts CIPP, and the change can take up to 60 seconds to take effect. |

## Manual Configuration

The Manual configuration (advanced) section lets you store an existing Application (client) ID and client secret directly in Key Vault; for example, to rotate the secret by hand or to point SSO at a different app registration. Enter the App ID (a GUID) and client secret, optionally set multi-tenant mode, and select **Save Manual Configuration**. This overwrites the stored values, so an incorrect App ID or secret will break single sign-on. The instance must then be restarted (from the Container Management page on a self-hosted instance) for the change to take effect.

## Single-Tenant vs Multi-Tenant Login

By default, CIPP sign-on is single-tenant: it trusts sign-ins only from your partner tenant. This is the right choice when the people who log in to CIPP have accounts in the partner tenant.

Multi-tenant mode allows users from more than one Entra ID tenant to sign in. Use it for split-tenant deployments where your MSP's staff sign in from a tenant other than the partner tenant. Multi-tenant mode is currently the supported way to handle that scenario.

One important caveat: multi-tenant mode currently accepts sign-ins from any Entra ID tenant. Whether a user can actually reach CIPP is still governed by the [cipp-users.md](cipp-users.md "mention") list and the roles assigned there, so only the intended users should be added.

## Configuring Multi-Tenant Mode

To enable multi-tenant login:

1. Turn on the **Multi-tenant mode (allow users from multiple Entra ID tenants)** switch on the SSO App Registration card. You can also set it while creating the app, or from the Manual Configuration section.
2. Select **Save Changes** to apply it. CIPP restarts, and the change can take up to 60 seconds.
3. On the [cipp-users.md](cipp-users.md "mention") page, add the users who should have access and assign them appropriate roles.

{% hint style="warning" %}
**Restricting to specific tenants:** multi-tenant mode is currently all-or-nothing and cannot yet be limited to a chosen list of tenant IDs from this page. The ability to restrict multi-tenant sign-in to specific tenant IDs is a planned addition to the SSO settings; until it is available, scope who can actually sign in through the CIPP Users list. This section will be updated with the configuration steps once the feature ships.
{% endhint %}

## Recovering Login Credentials

If the SSO client secret expires, single sign-on stops working and users may be unable to log in. How you recover depends on how CIPP is hosted.

**Self-hosted:** the SSO app's Application ID and client secret are stored in your instance's Key Vault. If you can still reach this page, use **Rotate Secret** to issue and store a new secret, or use **Manual Configuration** to write a known-good App ID and secret and then restart the instance. If the interface itself is inaccessible, an administrator with access to the underlying Azure resources can retrieve or replace the stored SSO values directly in the instance's Key Vault and then restart the container to restore access.

**Hosted:** for CIPP-hosted instances, credential recovery will be handled through a "recover your login" flow in the management portal. This flow is planned; this section will be updated once it is available.

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}

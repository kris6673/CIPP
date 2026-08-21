# Cloudflare

CIPP stores a single set of Cloudflare Access service account credentials here, which other integrations then use to reach services sitting behind a Cloudflare Zero Trust tunnel. Entering the credentials on this page does nothing on its own. Each integration that needs them has its own toggle to turn them on.

## Settings

| Setting                                                   | Description                                                                                                                                                        |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Enable Integration                                        | Makes the stored credentials available to other integrations. The credential fields stay disabled until this is on, and the webhook toggle does not appear at all. |
| CloudFlare Tunnel Service Account Client ID               | The Client ID of the Cloudflare Access service token, sent as the `CF-Access-Client-Id` header.                                                                    |
| CloudFlare Tunnel Service Account Client Secret           | The Client Secret of the service token, sent as the `CF-Access-Client-Secret` header. Stored securely and masked once saved.                                       |
| Use CloudFlare Service Account credentials with webhooks. | Adds the two headers to outbound webhook alerts, for webhook endpoints that are themselves behind Cloudflare Access.                                               |

{% hint style="info" %}
This page has no **Test** button, because there is nothing to connect to on its own. Validate the credentials by testing whichever integration you have pointed through the tunnel.
{% endhint %}

## Configuring the Integration

{% stepper %}
{% step %}
### Create a service token in Cloudflare

In Cloudflare Zero Trust, create a service token and record its Client ID and Client Secret. Make sure the Access application protecting your service accepts that token, otherwise CIPP's requests will still be challenged.
{% endstep %}

{% step %}
### Enable the integration

Turn on **Enable Integration**. The credential fields stay disabled until it is on.
{% endstep %}

{% step %}
### Enter the credentials

Enter the **CloudFlare Tunnel Service Account Client ID** and **CloudFlare Tunnel Service Account Client Secret**, then select **Submit**.
{% endstep %}

{% step %}
### Turn it on where it is needed

Enable the corresponding option in each integration that sits behind the tunnel, as listed below. Nothing uses these credentials until you do.
{% endstep %}
{% endstepper %}

## Where the Credentials Are Used

| Integration                                      | Option to enable                                                                | Description                                                                                  |
| ------------------------------------------------ | ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| [hudu.md](hudu.md "mention")                     | Connect to HUDU through CloudFlare Tunnel with the Service Account credentials. | Sends the Access headers with every request CIPP makes to Hudu.                              |
| [passwordpusher.md](passwordpusher.md "mention") | Behind a CF-ZTNA Tunnel                                                         | Sends the Access headers with every request CIPP makes to Password Pusher.                   |
| Webhook alerts                                   | Use CloudFlare Service Account credentials with webhooks.                       | Sends the Access headers with alerts delivered to the webhook endpoint set in Notifications. |

{% hint style="info" %}
The per-integration toggles only appear once this integration is enabled and saved, so configure this page first. Both the toggle on the other integration and **Enable Integration** here must be on before the headers are sent.
{% endhint %}

{% hint style="warning" %}
The same credentials are used everywhere. If your Hudu instance and your webhook endpoint sit behind different Cloudflare Access applications, the one service token needs to be accepted by both.
{% endhint %}

{% include "../../../../.gitbook/includes/feature-request.md" %}

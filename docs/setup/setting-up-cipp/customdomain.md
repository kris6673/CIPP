---
description: Custom domain
---

# Adding a Custom Domain Name

## Why set up a custom domain?

1. The automatically generated domain uses azurewebsites.net which is often blocked by web filtering products as it's often used by spammers and phishing sites due to the ease of obtaining an azurewebsites.net subdomain.
2. Your bookmark stays the same if you redeploy.
3. Easier to communicate internally and looks better for your team.

At the moment of deployment, the application uses a generated domain name. To change this, follow these instructions:

## CyberDrain Hosted Clients

{% stepper %}
{% step %}
### Log In to Management Portal

Go to [management.cipp.app](https://management.cipp.app/)
{% endstep %}

{% step %}
### Pick the Domains tab


{% endstep %}

{% step %}
### Click Add Domain
{% endstep %}

{% step %}
### Add DNS Records

The screen will give you an A record and a TXT record that you need to add to your DNS provider.

{% hint style="info" %}
Adding a subdomain? Create the records on the subdomain instead: an A record named and a TXT record named asuid.
{% endhint %}
{% endstep %}

{% step %}
### Enter Domain and Submit

Enter your desired domain into the management portal. Click Add Domain
{% endstep %}

{% step %}
### Wait

The system will validate that the DNS record exists and provision a certificate. The custom domain will become available when certificate provisioning is complete and its status changes to Ready.
{% endstep %}
{% endstepper %}

## Self-Hosted

{% stepper %}
{% step %}
### Go to the Azure Portal


{% endstep %}

{% step %}
### Find the resource group you deployed CIPP in


{% endstep %}

{% step %}
### Click on the App Service


{% endstep %}

{% step %}
### In the sidebar, click on Settings, Custom Domains


{% endstep %}

{% step %}
### Click on Add Custom Domain and enter your information


{% endstep %}
{% endstepper %}

For more information see Microsoft's documentation at [https://learn.microsoft.com/en-us/azure/app-service/app-service-web-tutorial-custom-domain?tabs=root%2Cazurecli](https://learn.microsoft.com/en-us/azure/app-service/app-service-web-tutorial-custom-domain?tabs=root%2Cazurecli)

---
hidden: true
---

# Migrating to the new infrastructure

### Back up first

In CIPP, go to **Application Settings → Manage Backups**, run a fresh backup, and download the backup file. It captures your instance configuration in case anything fails during the migration.

### Confirm prerequisites

* **PowerShell 7+** with the **Az** module, signed in to the Azure subscription that holds CIPP.
* **Owner** on the resource group — or **Contributor + User Access Administrator**. Owner is needed because the migration grants the new Web App's managed identity Contributor on the resource group, which requires `roleAssignments/write`. The script checks this up front and stops if it's missing.
* Download the files below, d**ownload both into the same folder.** The script loads its template from its own directory.
  * [`Invoke-CippMigration.ps1`](https://raw.githubusercontent.com/CyberDrain/CIPP/refs/heads/main/deployment/Invoke-CippMigration.ps1)
  * [`cipp-migration.json`](https://raw.githubusercontent.com/CyberDrain/CIPP/refs/heads/main/deployment/cipp-migration.json)

{% hint style="danger" %}
**Running the migration in could be destructive.** A live run **deletes** the existing Function Apps, App Service Plan, Application Insights components (and their smart-detector alert rules), and the Static Web App. Storage and Key Vault (your credentials) are preserved. Always run `-TestOnly` first, read the output, and only proceed once it looks right.
{% endhint %}

### Finish SSO migration

SSO must be at **`secrets_stored`** or **`complete`** before you cut over.&#x20;

You can find the SSO setup and state under CIPP -> Advanced -> Authentication-> SSO.

### Test run (`-TestOnly`)

From the folder where you saved both files, execute the following PowerShell command:

```powershell
.\Invoke-CippMigration.ps1 -ResourceGroupName '<your-resource-group>' -TestOnly
```

Add `-CippUrl 'cipp.contoso.com'` if you use a custom domain, this will make sure the final  the summary includes the DNS records to create.&#x20;

During a test run nothing is changed, and we see if you have enough permissions to run the migration.

If it says the resource group isn't found even though it exists, pass the subscription explicitly:

```powershell
$subId = (Get-AzContext).Subscription.Id
.\Invoke-CippMigration.ps1 -ResourceGroupName '<your-resource-group>' -SubscriptionId $subId -TestOnly
```

### Live run

If the test run looks right, run the same command without `-TestOnly`:

```powershell
.\Invoke-CippMigration.ps1 -ResourceGroupName '<your-resource-group>' -CippUrl 'cipp.contoso.com'
```

### Repoint DNS

Point your custom-domain CNAME at the new Web App hostname the script printed, then add the domain in App Service. The script removes custom domains from the Static Web App before deleting it, but does **not** add them to the new App Service for you.

To add the domain in Azure:

1. **App Service → your CIPP app → Custom domains → Add custom domain**
2. Set **Domain provider** to **All other domain services**, **TLS/SSL certificate** to **App Service Managed Certificate**, **TLS/SSL type** to **SNI SSL**
3. Enter your hostname and complete validation, then confirm the managed certificate is issued and bound

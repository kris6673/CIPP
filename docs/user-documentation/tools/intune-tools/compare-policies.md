# Compare Policies

The Compare Intune Policies page lets you compare two Intune policy configurations side by side and see exactly where they differ. Each side of the comparison can be a CIPP template, a live policy from one of your tenants, or a template file from a community repository, so you can check a tenant's policy against a baseline, compare the same policy across two tenants, or confirm that a template matches what is actually deployed.

The comparison looks at configuration only. Properties that always differ between two policies, or that Intune manages itself, are ignored: identifiers, created and modified timestamps, version numbers, scope tags, setting counts, sync state, and **assignments**. Two policies reported as identical may still be assigned to entirely different groups.

## Choosing What to Compare

The page presents two identical selectors, **Source A** and **Source B**. Each has a **Source Type** option that determines where its policy is read from, and the fields below it change to match. The two sources are independent, so any combination of types can be compared.

### CIPP Template

Compares against a policy template stored in CIPP.

| Field           | Description                                                                                                       |
| --------------- | ----------------------------------------------------------------------------------------------------------------- |
| Select Template | The CIPP Intune template to use. Templates are listed by name with their policy type shown in brackets. Required. |

Templates are read as stored. Tenant variable replacement and reusable settings are not resolved, because no tenant is chosen for this source type, so a template containing variables will show those variables rather than the values a deployment would substitute.

### Tenant Policy

Compares against a policy as it is currently deployed in one of your tenants.

| Field         | Description                                                                                                                                                          |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Tenant        | The tenant to read the policy from. Required.                                                                                                                        |
| Select Policy | The policy to compare. Policies are listed by name with their policy type shown in brackets, and the list is only populated once a tenant has been chosen. Required. |

### Community Repository

Compares against a template file held in a community repository.

| Field                | Description                                                                                                                                                |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Select Repository    | The community repository to read from. Required.                                                                                                           |
| Select Branch        | The branch within the repository. This is set to the repository's default branch automatically when you choose a repository, and can be changed. Required. |
| Select Template File | The template file within the chosen branch. The list is only populated once a repository and branch have been chosen. Required.                            |

{% hint style="info" %}
Only repositories registered with your CIPP instance appear in the list. There is no way to point at an arbitrary GitHub URL from this page. CIPP ships with the CyberDrain template repositories already registered, and you can add your own: [community-repos](../community-repos/ "mention")

Reading from a private repository requires the GitHub integration to be configured with a token. Without it, public repositories still work.
{% endhint %}

Changing the repository clears the branch and file selections, and changing the branch clears the file selection, so the choices always remain valid.

Two file formats are accepted. A CIPP template export carries its policy type with it and is read directly. A raw Intune policy export has its type worked out from the payload, which is not always possible: where the type cannot be determined, the file is still compared but without the type-aware handling described below.

## Running the Comparison

Select **Compare** to run the comparison. The button stays unavailable until both sources are fully specified, meaning a template, a policy, or a repository file depending on each source's type. If either policy cannot be retrieved, an error explaining what went wrong is shown in place of the results.

## Comparison Results

A summary banner reports the outcome and names the two policies being compared. Where the configurations match, it confirms that the policies are identical and no differences were found. Where they do not, it reports how many differences were found and the results below break them down.

Each source is named with where it came from, so a template reads as `(Template)`, a tenant policy as `(<tenant domain>)`, and a repository file as `(Repo: <owner/repository>)`. This matters when comparing two policies that share a display name.

### Differences

| Column   | Description                                |
| -------- | ------------------------------------------ |
| Property | The policy setting that differs.           |
| Source A | The value configured in the first policy.  |
| Source B | The value configured in the second policy. |
| Status   | How the two differ, as described below.    |

| Status           | Meaning                                                           |
| ---------------- | ----------------------------------------------------------------- |
| Different        | Both policies configure the setting, but with different values.   |
| Only in Source A | The setting is configured in the first policy but not the second. |
| Only in Source B | The setting is configured in the second policy but not the first. |

Rows are tinted to match their status, so differences stand out from settings present on only one side when scanning a long result. Where a value is a nested object rather than a simple setting, it is shown as formatted JSON. A setting absent from one side shows **N/A** in that column.

### Settings Catalog Policies

Where both sources resolve to settings catalog policies, a type-aware comparison is used instead of a plain property-by-property one. Settings are matched by their definition, so the **Property** column shows the setting's name as it appears in Intune rather than its underlying definition ID, and choice values are shown by their option name rather than their raw value. Nested group settings are expanded and compared individually.

{% hint style="info" %}
Microsoft Defender onboarding and offboarding blobs are skipped in settings catalog comparisons, since those values are unique to each tenant and would otherwise be reported as a difference on every comparison.
{% endhint %}

This handling applies only when both sides are settings catalog policies. Comparing a settings catalog policy against a source whose type could not be determined falls back to the plain comparison, which reports differences against the raw structure and is considerably harder to read.

### Full Settings

Beneath the differences, the complete configuration of each policy is shown in its own panel, headed **Source A Settings** and **Source B Settings** with the policy's name. These show everything each policy contains, not only the settings that differ, which is useful for reviewing a policy in full or confirming a setting that the comparison treated as matching.

***

{% include "../../../../.gitbook/includes/feature-request.md" %}

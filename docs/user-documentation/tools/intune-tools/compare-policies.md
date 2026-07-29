# Compare Policies

The Compare Intune Policies page lets you compare two Intune policy configurations side by side and see exactly where they differ. Each side of the comparison can be a CIPP template, a live policy from one of your tenants, or a template file from a community repository, so you can check a tenant's policy against a baseline, compare the same policy across two tenants, or confirm that a template matches what is actually deployed. Metadata that always differs between policies — identifiers, timestamps, version numbers, and scope tags — is ignored, so the results show only meaningful configuration differences.

## Choosing What to Compare

The page presents two identical selectors, **Source A** and **Source B**. Each has a **Source Type** option that determines where its policy is read from, and the fields below it change to match. The two sources are independent, so any combination of types can be compared.

### CIPP Template

Compares against a policy template stored in CIPP.

| Field           | Description                                                                                                       |
| --------------- | ----------------------------------------------------------------------------------------------------------------- |
| Select Template | The CIPP Intune template to use. Templates are listed by name with their policy type shown in brackets. Required. |

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

Changing the repository clears the branch and file selections, and changing the branch clears the file selection, so the choices always remain valid.

## Running the Comparison

Select **Compare** to run the comparison. The button stays disabled until both sources are fully specified — a template, a policy, or a repository file, depending on each source's type. If either policy cannot be retrieved, an error explaining what went wrong is shown in place of the results.

## Comparison Results

A summary banner reports the outcome and names the two policies being compared. Where the configurations match, it confirms that the policies are identical and no differences were found. Where they do not, it reports how many differences were found and the results below break them down.

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

### Full Settings

Beneath the differences, the complete configuration of each policy is shown in its own panel, headed **Source A Settings** and **Source B Settings** with the policy's name. These show everything each policy contains, not only the settings that differ, which is useful for reviewing a policy in full or confirming a setting that the comparison treated as matching.

***

{% include "../../../../.gitbook/includes/feature-request.md" %}

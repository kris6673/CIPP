function Test-CIPPCAGapIdentityProtection {
    <#
    .SYNOPSIS
        Tenant-wide check for risk-based Conditional Access (user risk and sign-in risk conditions).
    .DESCRIPTION
        Raises one High finding when no enabled policy uses user risk levels as a condition and another High finding
        when no enabled policy uses sign-in risk levels. Both propose the corresponding Identity Protection templates.
        Licensing is not consulted here (the CIS evaluation handles the Entra ID P2 gate).
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    # Risk-based policies need Entra ID P2; without it there is nothing to find.
    if ($Context.Licenses.HasEntraIdP2 -ne $true) { return @() }

    $Findings = [System.Collections.Generic.List[object]]::new()
    $Templates = $Context.Data.Reference.templates

    $HasUserRiskPolicy = @($Context.Enabled | Where-Object { @($_.conditions.userRiskLevels).Count -gt 0 }).Count -gt 0
    $HasSignInRiskPolicy = @($Context.Enabled | Where-Object { @($_.conditions.signInRiskLevels).Count -gt 0 }).Count -gt 0

    if (-not $HasUserRiskPolicy) {
        $Params = @{
            Severity    = 'High'
            Category    = 'Identity Protection'
            Title       = 'No policy enforces controls based on user risk level'
            Description = 'No enabled Conditional Access policy was found that uses user risk levels as a condition. Microsoft Entra ID Protection continuously evaluates user accounts for compromise indicators such as leaked credentials, anomalous behavior patterns, and threat intelligence signals. Without user risk policies, compromised accounts can operate undetected until manual discovery, attackers with stolen credentials gain persistent access, there is no automated response to credential leaks or account takeovers, and you are not using Microsoft''s threat intelligence for proactive defense. User risk is calculated from leaked credentials found on the dark web / paste sites, anomalous user activity, impossible travel, anonymous IP usage (TOR/VPN) and malware-linked IP addresses. Microsoft recommends blocking high-risk users or requiring password change + MFA.'
            Remediation = 'Requires Entra ID P2. Create a user risk policy: target All users (exclude break-glass accounts), condition User risk level = High, grant Require password change + MFA (or Block access for high-risk users), session Sign-in frequency = Every time. Review Entra Admin Center > Protection > Identity Protection > Risky Users, set up alerts for high-risk detections, and start in report-only mode to understand impact. See https://learn.microsoft.com/entra/id-protection/howto-identity-protection-configure-risk-policies#user-risk-policy'
            CaTemplate  = "$($Templates.userRisk)"
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    if (-not $HasSignInRiskPolicy) {
        $Params = @{
            Severity    = 'High'
            Category    = 'Identity Protection'
            Title       = 'No policy enforces controls based on sign-in risk level'
            Description = 'No enabled Conditional Access policy was found that uses sign-in risk levels as a condition. Microsoft Entra ID Protection analyzes each sign-in in real time for risk indicators such as unfamiliar locations, anonymous IPs, malware-linked infrastructure, and atypical behavior. Without sign-in risk policies, attackers with valid credentials can sign in from anywhere without additional verification, credential stuffing goes undetected, sign-ins from TOR, VPNs, or known malicious IPs are allowed, there is no automated response to suspicious sign-in patterns, and adversary-in-the-middle (AiTM) phishing attacks may succeed. Sign-in risk is calculated from anonymous IP addresses, atypical travel, malware-linked IPs, unfamiliar sign-in properties, password spray, impossible travel and token anomalies. Microsoft recommends requiring MFA for medium/high-risk sign-ins or blocking high-risk sign-ins entirely.'
            Remediation = 'Requires Entra ID P2. Create a sign-in risk policy: target All users (exclude break-glass accounts), condition Sign-in risk level = Medium and High, grant Require MFA (phishing-resistant recommended). Consider a second policy that blocks sign-in risk = High. Review Entra Admin Center > Protection > Identity Protection > Risky Sign-Ins and start in report-only mode to baseline detections. See https://learn.microsoft.com/entra/id-protection/howto-identity-protection-configure-risk-policies#sign-in-risk-policy'
            CaTemplate  = "$($Templates.signInRisk)"
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}

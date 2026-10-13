# SharePoint Online prioritises traffic decorated as 'ISV|Company|App/Version' over undecorated traffic.

BeforeAll {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))
    . (Join-Path $RepoRoot 'Modules/CIPPCore/Public/GraphHelper/Get-CippUserAgent.ps1')
}

Describe 'Get-CippUserAgent' {
    BeforeEach {
        $env:CippVersion = '11.1.0'
        $script:CippUserAgentContextStorage = [System.Threading.AsyncLocal[hashtable]]::new()
    }
    AfterAll { Remove-Item Env:\CippVersion -ErrorAction SilentlyContinue }

    It 'uses the SharePoint ISV decoration' {
        Get-CippUserAgent | Should -BeExactly 'ISV|CyberDrain|CIPP/11.1.0'
    }

    It 'keeps the attribution context as a comment after the product token' {
        $script:CippUserAgentContextStorage.Value = @{ Source = 'user'; Identity = 'john@msp.com' }
        Get-CippUserAgent | Should -BeExactly 'ISV|CyberDrain|CIPP/11.1.0 (user:john@msp.com)'
    }
}

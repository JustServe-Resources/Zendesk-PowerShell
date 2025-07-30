function Test-ZendeskEnvironment {
    <#
    .SYNOPSIS
        Checks for the presence of required Zendesk environment variables.

    .DESCRIPTION
        This function iterates through a predefined list of environment variables
        (ZendeskEmail, ZendeskApiToken, ZendeskUrl) and verifies if each is set.
        If any required environment variable is not found, it throws an error.

    .NOTES
        This function does not return any value. It throws an error if environment variables are not set.
    #>
    foreach ($envVar in @("ZendeskEmail", "ZendeskApiToken", "ZendeskUrl")) {
        $missingVars = @()
        if (-not (Test-Path -Path "Env:$envVar")) {
            $missingVars += $envVar
        }
    }

    if ($missingVars.Count -gt 0) {
        $errorMessage = "Required environment variable(s) not set: $($missingVars -join ', ')"
        throw $errorMessage
    }
}
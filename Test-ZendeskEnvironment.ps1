function Test-ZendeskEnvironment {
    <#
    .SYNOPSIS
        Checks for the presence of required Zendesk environment variables.

    .DESCRIPTION
        This function iterates through a predefined list of environment variables
        (ZendeskEmail, ZendeskApiToken, ZendeskUrl) and verifies if each is set.
        If any required environment variable is not found, it writes an error
        message and exits the script with an error code.
    #>
    foreach ($envVar in @("ZendeskEmail", "ZendeskApiToken", "ZendeskUrl")) {
        if (-not (Get-Item -Path "Env:$envVar" -ErrorAction SilentlyContinue)) {
            Write-Error "$envVar environment variable is not set."
            exit 1
        }
    }
}
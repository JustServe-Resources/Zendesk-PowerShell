
function Get-Fields {
    <#
    .SYNOPSIS
        Retrieves the field map for Zendesk ticket fields.

    .DESCRIPTION
        This function makes an API call to Zendesk to retrieve all available
        ticket fields and returns them as a PowerShell object. This can be
        useful for dynamically mapping fields or for inspection.

    .NOTES
        This function requires the following environment variables to be set:
        - ZendeskUrl
        - ZendeskEmail
        - ZendeskApiToken
    #>
    return (($(Invoke-ZendeskApiCall -UriPath "/api/v2/ticket_fields" -Method 'GET').Content) | ConvertFrom-Json).ticket_fields
}
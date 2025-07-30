function Add-Tickets {
    [CmdletBinding()]
    param (
        <#
        .SYNOPSIS
            Adds multiple tickets to Zendesk using the create_many API endpoint.

        .DESCRIPTION
            This function takes an array of ticket objects (typically generated from Jira CSV
            exports) and sends them to Zendesk's bulk ticket creation API. It handles
            batching of tickets to adhere to API limits (currently 100 tickets per request).

        .NOTES
            This function requires the following environment variables to be set:
            - ZendeskUrl
            - ZendeskEmail
            - ZendeskApiToken
        #>
        [Parameter(Mandatory = $true)]
        [array]
        $JiraTickets
    )

    Test-ZendeskEnvironment

    $endRange = [math]::Min(99, $JiraTickets.Count)
    $progressParams = @{
        Activity       = "Adding Zendesk Tickets"
        Status         = "Found $($JiraTickets.Count) tickets to import. Processing $($endRange - 1) tickets."
        PercentComplete = 0
    }
    Write-Progress @progressParams
    $responses = @()
    if ($JiraTickets.Count -gt $endRange) {
        $responses += Add-Tickets $JiraTickets[($endRange + 1) .. ($JiraTickets.Count - 1)]
    }
    $body = @{tickets = $JiraTickets[0..$endRange]} | ConvertTo-Json -Depth 100
    $responses = Invoke-ZendeskApiCall -UriPath "/api/v2/tickets/create_many.json" -Method 'POST' -Body $body
    foreach ($response in $responses) {
        $Content = ($response.Content | ConvertFrom-Json -Depth 100).job_status
        Write-Verbose "ZENDESK RESPONSE SUMMARY:`n`t`tid: $($Content.id)`n`t`turl: $($Content.url)`n`t`tstatus: $($Content.status) `n`t`ttotal: $($Content.total)"
    }
    return $responses
}

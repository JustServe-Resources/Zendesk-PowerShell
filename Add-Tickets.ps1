function Add-Tickets {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]
        $JiraTickets
    )

    Test-ZendeskEnvironment

    $endRange = [math]::Min(99, $JiraTickets.Count)
    Write-Host "Found $($JiraTickets.Count) tickets to import. Processing $($endRange - 1) tickets."
    $responses = @()
    if ($JiraTickets.Count -lt $endRange) {
        $responses += Add-Tickets $JiraTickets[($endRange + 1) .. ($JiraTickets.Count - 1)]
    }
    $body = @(tickets = $JiraTickets[0..$endRange]) | ConvertTo-Json -Depth 100
    $responses += Invoke-ZendeskApiCall -UriPath "/api/v2/tickets/create_many.json" -Method 'POST' -Body $body
    return $responses
}

function Add-Tickets {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $JiraTickets
    )

    Test-ZendeskEnvironment

    Write-Host "Found $($JiraTickets.Count) tickets to import. Processing in batches of $batchSize."

    $endRange = [math]::Min(99, $JiraTickets.Count)
    if ($JiraTickets.Count -lt $endRange) {
        Add-Tickets $JiraTickets[($endRange + 1) .. ($JiraTickets.Count - 1)]
    }
    $body = @(tickets = $JiraTickets[0..$endRange]) | ConvertTo-Json -Depth 100
    return Invoke-ZendeskApiCall -UriPath "/api/v2/tickets/create_many.json" -Method 'POST' -Body $body
}

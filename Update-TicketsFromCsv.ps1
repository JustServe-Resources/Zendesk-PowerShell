function  Update-TicketsFromCsv {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [file]
        $ZendeskExportFile,
        [Parameter(Mandatory = $true)]
        [file]
        $UpdatesFile,
        [Parameter(Mandatory = $true)]
        [String]
        $matchingColumnName,
        [Parameter(Mandatory = $true)]
        [String]
        $columnNameToAdd
    )
    Test-ZendeskEnvironment
    $export = Import-Csv $ZendeskExportFile
    $updates = Import-Csv $UpdatesFile

    $endRange = [math]::Min(99, $tickets.Count)
    $progressParams = @{
        Activity        = "Updating Zendesk Tickets"
        Status          = "Found $($tickets.Count) tickets to import. Processing $($endRange - 1) tickets."
        PercentComplete = 0
    }
    Write-Progress @progressParams
    $responses = @()
    if ($tickets.Count -gt $endRange) {
        $responses += Add-Tickets $tickets[($endRange + 1) .. ($tickets.Count - 1)]
    }
    $body = @{tickets = $tickets[0..$endRange]} | ConvertTo-Json -Depth 100
    $response = Invoke-ZendeskApiCall -UriPath "api/v2/tickets/update_many.json" -Method 'PUT' -Body $body
    $ResponseContent = ($response.Content | ConvertFrom-Json -Depth 100).job_status
    Write-Verbose "ZENDESK RESPONSE SUMMARY:`n`tid: $($ResponseContent.id)`n`turl: $($ResponseContent.url)`n`tstatus: $($ResponseContent.status) `n`ttotal: $($ResponseContent.total)"
    $responses += $response
    return $responses
}

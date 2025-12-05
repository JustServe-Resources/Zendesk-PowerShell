function Update-InformationRequestRecipient {
  [CmdletBinding()]
  param (
    <#
        .SYNOPSIS
            Updates tickets for a specific requester where the CC field has exactly one ID.
            The CC is promoted to Requester, and the CC field is cleared.

        .DESCRIPTION
            This function searches for tickets matching a specific requester ID and checks if
            they have exactly one email CC. If so, it updates the ticket to set the requester
            to that CC user and removes the CC.

        .NOTES
            This function requires the following environment variables to be set:
            - ZendeskUrl
            - ZendeskEmail
            - ZendeskApiToken
        #>
    [Parameter(Mandatory = $false)]
    [long]$RequesterId = 18885940524699
  )

  # Dot-source dependencies
  . "$PSScriptRoot\Invoke-ZendeskApiCall.ps1"
  . "$PSScriptRoot\Test-ZendeskEnvironment.ps1"
  . "$PSScriptRoot\Update-Ticket.ps1"

  Test-ZendeskEnvironment

  $query = "type:ticket requester:$RequesterId -status:closed -status:solved"
  $encodedQuery = [uri]::EscapeDataString($query)
  $uriPath = "api/v2/search.json?query=$encodedQuery"

  Write-Verbose "Starting search with query: $query"

  $processedCount = 0
  $totalCount = 0

  do {
    Write-Verbose "Fetching: $uriPath"
    $response = Invoke-ZendeskApiCall -UriPath $uriPath -Method 'GET'
    $json = $response.Content | ConvertFrom-Json
        
    if ($totalCount -eq 0) {
      $totalCount = $json.count
      Write-Verbose "Found $totalCount tickets matching the query."
    }

    foreach ($ticket in $json.results) {
      $processedCount++
            
      $progressParams = @{
        Activity        = "Updating Tickets"
        Status          = "Processing ticket $processedCount of $totalCount (ID: $($ticket.id))"
        PercentComplete = if ($totalCount -gt 0) { [math]::Min(100, [int](($processedCount / $totalCount) * 100)) } else { 0 }
      }
      Write-Progress @progressParams

      if ($ticket.requester_id -eq $RequesterId -and $ticket.email_cc_ids.Count -eq 1) {
        $newRequesterId = $ticket.email_cc_ids[0]
        $ticketId = $ticket.id
                
        Write-Verbose "Updating Ticket ID: $ticketId. Changing Requester from $RequesterId to $newRequesterId and clearing CCs."
                
        $ticketData = @{
          requester_id = $newRequesterId
          email_cc_ids = @()
        }

        try {
          Update-Ticket -TicketId $ticketId -TicketData $ticketData
          Write-Host "Successfully updated Ticket $ticketId" -ForegroundColor Green
        }
        catch {
          Write-Error "Failed to update Ticket $ticketId : $_"
        }
      }
    }
        
    $nextPageUrl = $json.next_page
    if ($nextPageUrl) {
      $parts = $nextPageUrl -split "/api/v2/"
      if ($parts.Count -ge 2) {
        $uriPath = "api/v2/" + $parts[1]
      }
      else {
        Write-Warning "Could not parse next_page URL: $nextPageUrl"
        $nextPageUrl = $null
      }
    }
        
  } while ($nextPageUrl)

  Write-Progress -Activity "Updating Tickets" -Completed
  Write-Host "Finished updating $processedCount information requests with their Specialist as the requester"
}

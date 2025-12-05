function Update-ManyTickets {
  [CmdletBinding()]
  param (
    <#
        .SYNOPSIS
            Updates multiple tickets in Zendesk in batches.

        .DESCRIPTION
            This function updates multiple tickets in Zendesk using the bulk update endpoint.
            It accepts an array of ticket objects (each containing an 'id' and fields to update).
            It automatically batches requests to adhere to the API limit of 100 tickets per request.

        .PARAMETER Tickets
            An array of hashtables, where each hashtable represents a ticket update.
            Each hashtable MUST contain an 'id' property.
            Example: @( @{ id = 1; status = 'solved' }, @{ id = 2; status = 'pending' } )

        .NOTES
            This function requires the following environment variables to be set:
            - ZendeskUrl
            - ZendeskEmail
            - ZendeskApiToken
        #>
    [Parameter(Mandatory = $true)]
    [array]$Tickets
  )

  Test-ZendeskEnvironment

  $batchSize = 100
  $totalTickets = $Tickets.Count
  $allJobStatuses = @()

  Write-Verbose "Starting bulk update for $totalTickets tickets."

  for ($i = 0; $i -lt $totalTickets; $i += $batchSize) {
    $endIndex = [math]::Min($i + $batchSize - 1, $totalTickets - 1)
    $batch = $Tickets[$i..$endIndex]
        
    $body = @{ tickets = $batch } | ConvertTo-Json -Depth 10

    Write-Verbose "Processing batch $($i/100 + 1): Tickets $i to $endIndex"

    try {
      $response = Invoke-ZendeskApiCall -UriPath "api/v2/tickets/update_many.json" -Method 'PUT' -Body $body
      $jsonResponse = $response.Content | ConvertFrom-Json
            
      if ($jsonResponse.job_status) {
        $allJobStatuses += $jsonResponse.job_status
        Write-Verbose "Batch submitted. Job ID: $($jsonResponse.job_status.id)"
      }
    }
    catch {
      Write-Error "Failed to update batch starting at index $i : $_"
    }
  }
  return $allJobStatuses
}

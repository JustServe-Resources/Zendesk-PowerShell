function Update-Ticket {
  [CmdletBinding()]
  param (
    <#
        .SYNOPSIS
            Updates a single ticket in Zendesk.

        .DESCRIPTION
            This function updates a specific ticket in Zendesk using the provided data.
            It constructs a PUT request to the /api/v2/tickets/{id}.json endpoint.

        .PARAMETER TicketId
            The ID of the ticket to update.

        .PARAMETER TicketData
            A hashtable containing the fields to update (e.g., @{ status = 'solved'; comment = @{ body = 'Done' } }).

        .NOTES
            This function requires the following environment variables to be set:
            - ZendeskUrl
            - ZendeskEmail
            - ZendeskApiToken
        #>
    [Parameter(Mandatory = $true)]
    [long]$TicketId,

    [Parameter(Mandatory = $true)]
    [hashtable]$TicketData
  )

  Test-ZendeskEnvironment

  $body = @{ ticket = $TicketData } | ConvertTo-Json -Depth 10

  try {
    Write-Verbose "Updating Ticket ID: $TicketId"
    $response = Invoke-ZendeskApiCall -UriPath "api/v2/tickets/$TicketId.json" -Method 'PUT' -Body $body
    return ($response.Content | ConvertFrom-Json).ticket
  }
  catch {
    Write-Error "Failed to update Ticket $TicketId : $_"
    throw $_
  }
}

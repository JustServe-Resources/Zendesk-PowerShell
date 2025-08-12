function Get-Ticket {
    [CmdletBinding()]
    param (
        <#
        .SYNOPSIS
            Retrieves a single ticket from Zendesk by its ID.

        .DESCRIPTION
            This function constructs the appropriate URL for the Zendesk Tickets API
            and uses Invoke-ZendeskApiCall to perform a GET request for a specific ticket.

        .NOTES
            This function requires the following environment variables to be set:
            - ZendeskUrl
            - ZendeskEmail
            - ZendeskApiToken
            
        .PARAMETER TicketId
            The unique identifier of the Zendesk ticket to retrieve.
        #>
        [Parameter(Mandatory = $true)]
        [int]$TicketId
    )
    Test-ZendeskEnvironment

    try {
        $response = Invoke-ZendeskApiCall -UriPath "/api/v2/tickets/$($TicketId)"-Method 'GET'
        $content = $response.Content | ConvertFrom-Json
        return $content.ticket
    }
    catch {
        Write-Error "Error getting ticket $($TicketId): $($_.Exception.Message)"
        throw $_
    }
}
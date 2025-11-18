function Get-Problems {
    [CmdletBinding()]
    param (
        <#
        .SYNOPSIS
            Retrieves all problems from Zendesk.

        .DESCRIPTION
            This function constructs the appropriate URL for the Zendesk Tickets API
            and uses Invoke-ZendeskApiCall to perform a GET request for a specific ticket.

        .NOTES
            This function requires the following environment variables to be set:
            - ZendeskUrl
            - ZendeskEmail
            - ZendeskApiToken
          
        #>
    )
    Test-ZendeskEnvironment
    $problems = @()
    try {
        $response = Invoke-ZendeskApiCall -UriPath "/api/v2/problems.json"-Method 'GET'
        $response = $response | ConvertFrom-Json
        $problems += $response.Tickets
        while ($null -ne $response.next_page) {
          Write-Verbose "Fetching $(($response.next_page -split '`?')[-1]) of problems."
          $response = Invoke-ZendeskApiCall -UriPath "/api/v2/$(($response.next_page -split '/')[-1])"-Method 'GET'
          $response = $response | ConvertFrom-Json
          $problems += $response.Tickets
        }
    }
    catch {
        Write-Error "Error getting problems for ticket $($TicketId): $($_.Exception.Message)"
        throw $_
    }
    return $problems
  }
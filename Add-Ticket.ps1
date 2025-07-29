function Add-Ticket {
    [CmdletBinding()]
    param (
        <#
        .SYNOPSIS
            Adds a new ticket to Zendesk.

        .DESCRIPTION
            This function creates a new ticket in Zendesk using the provided subject,
            comment, and optional parameters like requester email/name, tags, type, and priority.
            It constructs the appropriate JSON payload and uses Invoke-ZendeskApiCall
            to perform a POST request to the Zendesk Tickets API.

            It requires the following environment variables to be set:
            - ZendeskUrl
            - ZendeskEmail
            - ZendeskApiToken

        .PARAMETER Subject
            The subject line of the new Zendesk ticket.

        .PARAMETER Comment
            The main body or comment of the new Zendesk ticket.

        .PARAMETER RequesterEmail
            (Optional) The email address of the ticket requester. If provided, RequesterName can also be used.

        .PARAMETER RequesterName
            (Optional) The name of the ticket requester. Requires RequesterEmail to be provided.

        .PARAMETER Tags
            (Optional) An array of strings representing tags to be applied to the ticket.

        .PARAMETER Type
            (Optional) The type of the ticket (e.g., "question", "incident", "problem", "task").

        .PARAMETER Priority
            (Optional) The priority of the ticket (e.g., "low", "normal", "high", "urgent").
        #>
        [Parameter(Mandatory = $true)]
        [string]$Subject,

        [Parameter(Mandatory = $true)]
        [string]$Comment,

        [Parameter(Mandatory = $false)]
        [string]$RequesterEmail,

        [Parameter(Mandatory = $false)]
        [string]$RequesterName,

        [Parameter(Mandatory = $false)]
        [string[]]$Tags,

        [Parameter(Mandatory = $false)]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$Priority
    )
    Test-ZendeskEnvironment

    $ticketBody = @{
        "ticket" = @{
            "subject" = $Subject
            "comment" = @{
                "body" = $Comment
            }
        }
    }

    if ($RequesterEmail) {
        $ticketBody.ticket.requester = @{ "email" = $RequesterEmail }
        if ($RequesterName) {
            $ticketBody.ticket.requester.name = $RequesterName
        }
    }

    if ($Tags) {
        $ticketBody.ticket.tags = $Tags
    }

    if ($Type) {
        $ticketBody.ticket.type = $Type
    }

    if ($Priority) {
        $ticketBody.ticket.priority = $Priority
    }

    $jsonBody = $ticketBody | ConvertTo-Json -Depth 4

    $url = "$($env:ZendeskUrl)/api/v2/tickets"

    try {
        $response = Invoke-ZendeskApiCall -Url $url -Method 'POST' -Body $jsonBody
        return $response
    }
    catch {
        Write-Error "Error adding ticket: $($_.Exception.Message)"
        throw $_
    }
}
function Invoke-ZendeskApiCall {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url = "https://justserve.zendesk.com",

        [Parameter(Mandatory=$false)]
        [string]$Method = 'GET',

        [Parameter(Mandatory=$false)]
        [hashtable]$Headers,

        [Parameter(Mandatory=$false)]
        [string]$Body
    )

    $base64AuthInfo = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($Global:ZendeskEmail)/token:$($Global:ZendeskApiToken)"))

    $defaultHeaders = @{
        "Authorization" = "Basic $base64AuthInfo"
        "Content-Type" = "application/json"
    }

    if ($Headers) {
        $mergedHeaders = $defaultHeaders + $Headers
    } else {
        $mergedHeaders = $defaultHeaders
    }

    try {
        $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $mergedHeaders -Body $Body -ContentType "application/json"

        return $response
    }
    catch {
        Write-Error "Error making API call to $($Url): $($_.Exception.Message)"
        throw $_
    }
}

function Add-Ticket {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Subject,

        [Parameter(Mandatory=$true)]
        [string]$Comment,

        [Parameter(Mandatory=$false)]
        [string]$RequesterEmail,

        [Parameter(Mandatory=$false)]
        [string]$RequesterName,

        [Parameter(Mandatory=$false)]
        [string[]]$Tags,

        [Parameter(Mandatory=$false)]
        [string]$Type,

        [Parameter(Mandatory=$false)]
        [string]$Priority
    )

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

    $url = "$($Global:ZendeskUrl)/api/v2/tickets.json"

    try {
        $response = Invoke-ZendeskApiCall -Url $url -Method 'POST' -Body $jsonBody
        return $response
    }
    catch {
        Write-Error "Error adding ticket: $($_.Exception.Message)"
        throw $_
    }
}
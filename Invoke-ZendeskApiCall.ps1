function Invoke-ZendeskApiCall {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,

        [Parameter(Mandatory=$true)]
        [string]$ZendeskEmail,

        [Parameter(Mandatory=$false)]
        [string]$Method = 'GET',

        [Parameter(Mandatory=$false)]
        [hashtable]$Headers,

        [Parameter(Mandatory=$false)]
        [string]$Body
    )

    $base64AuthInfo = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($ZendeskEmail)/token:$($env:ZendeskApiToken)"))

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
        $response = Invoke-WebRequest -Uri $Url -Method $Method -Headers $mergedHeaders -Body $Body -ContentType "application/json"
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


function AddTicketsBulk(){
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$baseUrl,

        [Parameter(Mandatory=$true)]
        [string]$ZendeskEmail,

        [Parameter(Mandatory=$true)]
        [string]$jiraCsvPath
    )
    $env:ZendeskApiToken=(get-content "./.env.txt").split('=')[1]

    . ./Convert-JiraToZendesk.ps1
    
    $tickets=ConvertFrom-JiraCsvToZendeskTicket -jiraCsvPath $jiraCsvPath
    $url = "$($baseUrl)/api/v2/tickets/create_many.json"
    

    #convert tickets array into batches of no more than 100
    $ticketBatches=New-Object System.Collections.ArrayList
    for($i=0; $i -lt $tickets.Length ;$i++){   
        $ticket=$tickets[$i]
        $ticketBatch=[Math]::Floor($i/100)

        #since ticket batch starts out as zero a new batch is automatically created right from the beginning
        if($i-1 -eq ($ticketBatch*100)-1){
            $newArray=New-Object System.Collections.ArrayList
            $newArray.Add($ticket)
            $ticketBatches.Add($newArray) 
        }else{
            $ticketBatches[$ticketBatch].Add($ticket)
        }
    }

    foreach($batch in $ticketBatches){
        try {
            $jsonBody = @{tickets=$batch} | ConvertTo-Json -Depth 7
            $response = Invoke-ZendeskApiCall -Url $url -ZendeskEmail $zendeskEmail -Method 'POST' -Body $jsonBody
            Write-Output $response
        }
        catch {
            Write-Error "Error adding tickets: $($_.Exception.Message)"
            throw $_
        }
    }
}

function Get-Ticket {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [int]$TicketId
    )

    $url = "$($env:ZendeskUrl)/api/v2/tickets/$($TicketId)"

    try {
        $response = Invoke-ZendeskApiCall -Url $url -Method 'GET'
        return $response
    }
    catch {
        Write-Error "Error getting ticket $($TicketId): $($_.Exception.Message)"
        throw $_
    }
}

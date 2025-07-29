function Add-Tickets() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$jiraCsvPath
    )

    Test-ZendeskEnvironment
    
    $tickets = ConvertFrom-JiraCsvToZendeskTicket -jiraCsvPath $jiraCsvPath
    $url = "$($baseUrl)/api/v2/tickets/create_many.json"
    

    #convert tickets array into batches of no more than 100
    $ticketBatches = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $tickets.Length ; $i++) {   
        $ticket = $tickets[$i]
        $ticketBatch = [Math]::Floor($i / 100)

        #since ticket batch starts out as zero a new batch is automatically created right from the beginning
        if ($i - 1 -eq ($ticketBatch * 100) - 1) {
            $newArray = New-Object System.Collections.ArrayList
            $newArray.Add($ticket)
            $ticketBatches.Add($newArray) 
        }
        else {
            $ticketBatches[$ticketBatch].Add($ticket)
        }
    }

    foreach ($batch in $ticketBatches) {
        try {
            $jsonBody = @{tickets = $batch } | ConvertTo-Json -Depth 7
            $response = Invoke-ZendeskApiCall -Url $url -ZendeskEmail $zendeskEmail -Method 'POST' -Body $jsonBody
            Write-Output $response
        }
        catch {
            Write-Error "Error adding tickets: $($_.Exception.Message)"
            throw $_
        }
    }
}
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

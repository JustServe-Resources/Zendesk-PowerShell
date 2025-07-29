function Invoke-ZendeskApiCall {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [string]$Method = 'GET',

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers,

        [Parameter(Mandatory = $false)]
        [string]$Body
    )

    Test-ZendeskEnvironment

    $base64AuthInfo = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($env:ZendeskEmail)/token:$($env:ZendeskApiToken)"))

    $defaultHeaders = @{
        "Authorization" = "Basic $base64AuthInfo"
        "Content-Type"  = "application/json"
    }

    if ($Headers) {
        $mergedHeaders = $defaultHeaders + $Headers
    }
    else {
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

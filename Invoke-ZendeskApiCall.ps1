function Invoke-ZendeskApiCall {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UriPath,

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
        return Invoke-WebRequest -Uri "$($env:ZendeskUrl)/$($UriPath)" -Method $Method -Headers $mergedHeaders -Body $Body -ContentType "application/json"
    }
    catch {
        Write-Error "Error making API call to $($UriPath): $($_.Exception.Message)"
        throw $_
    }
}


function Invoke-ZendeskApiCall {
    [CmdletBinding()]
    param (
        <#
        .SYNOPSIS
            Makes an authenticated API call to the Zendesk API.

        .DESCRIPTION
            This function constructs and executes an authenticated HTTP request
            to the Zendesk API. It automatically handles authentication using
            environment variables (ZendeskEmail, ZendeskApiToken, ZendeskUrl)
            and sets the Content-Type header to application/json.
            It supports GET, POST, PUT, and DELETE methods and allows for
            custom headers and request bodies.

        .NOTES
            This function requires the following environment variables to be set:
            - ZendeskUrl
            - ZendeskEmail
            - ZendeskApiToken

        .PARAMETER UriPath
            The path segment of the URI relative to the Zendesk base URL (e.g., "/api/v2/tickets").
        .PARAMETER Method
            The HTTP method to use for the request (e.g., 'GET', 'POST', 'PUT', 'DELETE'). Defaults to 'GET'.
        .PARAMETER Headers
            A hashtable of additional HTTP headers to include in the request. These will be merged with default headers.
        .PARAMETER Body
            The body of the HTTP request. This should typically be a JSON string for POST/PUT requests.
        #>
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



function ConvertFrom-JiraCsvToZendeskTickets {
    <#
.SYNOPSIS
    Reads Jira issues from a CSV file, transforms them into a format
    suitable for the Zendesk Tickets API, and converts them to JSON.

.DESCRIPTION
    This script is designed to help migrate ticket data from a Jira CSV export to Zendesk.
    It handles mapping standard fields, custom fields, tags, comments, and date formats.

    You MUST customize the mapping sections (hashtables) within this script to match your
    specific Jira and Zendesk configurations before running.

    .NOTES
    This function requires the following environment variables to be set:
    - ZendeskUrl
    - ZendeskEmail
    - ZendeskApiToken
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('f')]
        [ValidateScript({ Test-Path -Path $_ })]
        [string]$jiraCsvPath,
        [Parameter(Mandatory = $false)]
        [Array]
        $Fields,
        [Parameter(Mandatory = $false)]
        [hashtable]
        $statusMap,
        [Parameter(Mandatory = $false)]
        [PSCustomObject]
        $sampleTicket
    )
    if ($null -eq $Fields) {
        $Fields = Get-Fields
    }
    if ($null -eq $statusMap) {
        $statusMap = @{
            "Accepted"    = "Solved"
            "Analysis"    = "Open"
            "Blocked"     = "Open"
            "Closed"      = "Open"
            "In Progress" = "Open"
            "New"         = "Open"
            "Ready"       = "Open"
            "Resolved"    = "Solved"
        }
    }
    $JiraData = Import-Csv $jiraCsvPath

    Write-Host "Processing $($jiraData.Count) tickets from '$jiraCsvPath'..."
    $tickets = foreach ($jiraTicket in $jiraData) {

        # Build the main ticket object structure that Zendesk expects.
        $zendeskTicketPayload = @{
            "id"             = $jiraTicket.'Issue id'
            "external_id"    = $null
            "via"            = @{
                "channel" = "web"
                "source"  = @{
                    "from" = @{}
                    "to"   = @{}
                    "rel"  = $null
                }
            }
            "created_at"     = "$((Get-Date $jiraTicket.Created).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))"
            "updated_at"     = "$((Get-Date $jiraTicket.Updated).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))"
            "type"           = "problem"
            "subject"        = "$($jiraTicket.Summary)"
            "description"    = "$($jiraTicket.Description)"
            "comment"        = @{
                "body"   = "$($jiraTicket.Description)`n<hr>`n*Original Jira Comment:*`n$($jiraTicket.Comment)"
                "public" = $false
            }
            "status"         = "$($statusMap[$jiraTicket.Status])"
            "requester_id"   = $sampleTicket.requester_id # Add justus as the requester
            "group_id"       = $sampleTicket.group_id
            "ticket_form_id" = $sampleTicket.ticket_form_id
            "brand_id"       = $sampleTicket.brand_id
            "submitter_id"   = $sampleTicket.submitter_id
            "custom_fields"  = @{
                "$($Fields.Where({$_.title -eq 'Feature Request' -and $_.type -eq 'checkbox'}).id)" = ($jiraTicket.'Issue Type' -eq "New Feature")
                "$($Fields.Where({$_.title -eq 'Regression'}).id)"                                  = ($jiraTicket.'Issue Type' -eq "Regression")
                "$($Fields.Where({$_.title -eq 'Jira Ticket'}).id)"                                 = ($jiraTicket.'Issue id')
                "$($Fields.Where({$_.title -eq 'Steps to produce behavior'}).id)" = ($jiraTicket.'Custom field (Steps To Reproduce)')
            }
        }
        $zendeskTicketPayload
    }
    return $tickets
}


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
        [string]$jiraCsvPath
    )

    $fieldMap = @{
        "Question"                             = 38622750189851
        "Approval Status"                      = 39065569798171
        "Actual Behavior"                      = 30573553563675
        "Assignee"                             = 8978283930395
        "Browser / App version"                = 30837891882523
        "Category of Concern"                  = 10800716325019
        "Description"                          = 8978290634779
        "Email Requester's City"               = 34844017990171
        "Expected Behavior"                    = 30572845583899
        "Feature Request"                      = 39186352385051
        "Group"                                = 8978312161819
        "Jira Ticket"                          = 39188651800603
        "Priority"                             = 8978259209115
        "Problem Status"                       = 39187352002203
        "Regression"                           = 39188175429147
        "Regression Of"                        = 39188323306011
        "Report a concern - Organization Link" = 11678997467035
        "Report a concern - Project Link"      = 11678970701467
        "Steps to produce behavior"            = 30574241522075
        "Subject"                              = 8978275191707
        "Task"                                 = 38720689571483
        "Ticket status"                        = 10824624488347
        "Type"                                 = 8978275195931
        "User Type Affected"                   = 39187459300251
    }

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
            "requester_id"   = 9424731678747 # Add justus as the requester
            "group_id"       = 8978275488283 # add to support team
            "ticket_form_id" = 11002305068315 # report a concern with a project form
            "brand_id"       = 8978259459099 # I dunno what this is. if it's wrong, fix it
            "custom_fields"  = @{
                "$($fieldMap["Feature Request"])" = ($jiraTicket.'Issue Type' -eq "New Feature")
                "$($fieldMap["Regression"])"      = ($jiraTicket.'Issue Type' -eq "Regression")
                "$($fieldMap["Jira Ticket"])"     = ($jiraTicket.'Issue id')
            }
        }
        $zendeskTicketPayload
    }
    return $tickets
}

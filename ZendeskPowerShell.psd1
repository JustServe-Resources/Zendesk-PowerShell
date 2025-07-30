@{
    RootModule        = 'ZendeskPowerShell.psm1'
    ModuleVersion     = '0.0.1'
    GUID              = '30773dbd-a035-41f5-8847-ef1937211ca1'
    Author            = 'Jonathan Zollinger, James Talbot'
    CompanyName       = 'JustServe'
    Description       = 'A PowerShell module for interacting with the Zendesk API, including ticket creation and management.'
    PowerShellVersion = '7.0.0'
    FunctionsToExport = @(
        'Add-Tickets',
        'ConvertFrom-JiraCsvToZendeskTickets',
        'Get-Ticket',
        'Invoke-ZendeskApiCall',
        'Test-ZendeskEnvironment'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('Zendesk')
            ProjectUri = 'https://github.com/JustServe-Resources/Zendesk-PowerShell'
        } 
    }
}
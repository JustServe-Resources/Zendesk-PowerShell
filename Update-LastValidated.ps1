function Update-LastValidated {

  $problems = Get-Problems
  Write-Verbose "Retrieved $($problems.Count) problems from Zendesk."
  $fields = Get-Fields
  $lastValidatedId = ($fields | Where-Object { $_.title -eq "Last Validated date" }).id
  if (-not $lastValidatedId) {
    Write-Error "Could not find field 'Last Validated'"
    return
  }
  $daysSinceLastValidatedId = ($fields | Where-Object { $_.title -eq "Days since last validated" }).id
  if (-not $daysSinceLastValidatedId) {
    Write-Error "Could not find field 'Days since last validated'"
    return
  }
  $previouslyValidatedProblems = $problems | Where-Object {
    if ($_.status -eq "solved") { return $false }
    foreach ($field in $_.fields) {
      if ($field.id -eq $lastValidatedId -and $null -ne $field.value) {
        return $true
      }
    }
    return $false
  }
  $today = Get-Date
  Write-Verbose "Found $($previouslyValidatedProblems.Count) problems with a Last Validated date."
  $updatesToSend = @()

  $previouslyValidatedProblems.ForEach({
      $lastValidatedField = $_.fields | Where-Object { $_.id -eq $lastValidatedId }
      $lastValidatedDate = [datetime]$lastValidatedField.value
      $daysSinceLastValidated = ($today - $lastValidatedDate).Days
      $updatesToSend += (@{
          "id"            = $_.id
          "custom_fields" = @(
            @{
              "id"    = $daysSinceLastValidatedId
              "value" = $daysSinceLastValidated
            }
          )
        })
        Write-Verbose "added update for problem $($_.id): Last Validated = $($lastValidatedDate), Days since last validated = $($daysSinceLastValidated)"
      
    })
  if ($updatesToSend.Count -gt 0) {
    Write-Verbose "Sending updates for $($updatesToSend.Count) problems to Zendesk"
    $batchSize = 100
    $i = 0
    while ($i -lt $updatesToSend.Count) {
        $chunk = $updatesToSend | Select-Object -Skip $i -First $batchSize
        $i += $batchSize

        $body = @{ "tickets" = $chunk } | ConvertTo-Json -Depth 100
        Write-Verbose "Updating batch of $($chunk.Count) tickets."
        Invoke-ZendeskApiCall -UriPath "/api/v2/tickets/update_many.json" -Method 'PUT' -Body $body
    }
    Write-Output "Updated $($updatesToSend.Count) problems with Days since last validated."
  }
  else {
    Write-Output "No problems to update."
  }
}
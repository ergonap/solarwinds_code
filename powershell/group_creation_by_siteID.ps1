# Import Swis PowerShell module
Import-Module SwisPowerShell

# Connect to SolarWinds with interactive credentials
if (-not ($SwisConnection)) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    $SwisConnection = Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

# Direct query to get all unique SiteName values that do not have corresponding groups
$siteNamesToCreateGroups = Get-SwisData $SwisConnection @"
SELECT DISTINCT n.SiteName
FROM Orion.NodesCustomProperties n
LEFT JOIN Orion.Container c ON c.Name = n.SiteName
WHERE c.Name IS NULL AND n.SiteName IS NOT NULL AND n.SiteName NOT IN ('')
ORDER BY n.SiteName
"@

# Output for inspection
if ($siteNamesToCreateGroups.Count -eq 0) {
    Write-Host "No SiteNames found that need groups. All groups already exist or there are no SiteNames." -ForegroundColor Yellow
    return
}

Write-Host "Retrieved SiteNames that need groups:" -ForegroundColor Cyan
$siteNamesToCreateGroups | ForEach-Object { Write-Host " - SiteName: '$($_.SiteName)'" }

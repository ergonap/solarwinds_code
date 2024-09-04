# Import Swis PowerShell module
Import-Module SwisPowerShell

# Connect to SolarWinds with interactive credentials
if (-not ($SwisConnection)) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    $SwisConnection = Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

# Simple query to get all unique SiteName values from Orion.NodesCustomProperties
$testQuery = @"
SELECT DISTINCT n.SiteName
FROM Orion.NodesCustomProperties n
WHERE n.SiteName IS NOT NULL AND n.SiteName NOT IN ('')
ORDER BY n.SiteName
"@

# Run the query and assign the results to the $siteNames array
$siteNames = Get-SwisData $SwisConnection -Query $testQuery

# Check if any SiteNames are returned and display them
if ($siteNames.Count -eq 0) {
    Write-Host "No SiteNames found. Check if there are any nodes with the 'SiteName' custom property set." -ForegroundColor Red
    return
}

Write-Host "Raw SiteNames found:" -ForegroundColor Cyan
$siteNames | ForEach-Object { Write-Host "SiteName: '$($_.SiteName)'" }

Write-Host "End of SiteNames list." -ForegroundColor Green

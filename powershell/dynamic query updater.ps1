# Import Swis PowerShell module
Import-Module SwisPowerShell

# Connect to SolarWinds with interactive credentials
if (-not ($SwisConnection)) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    $SwisConnection = Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

# Get all groups with dynamic queries set to Alert_Enabled
$groupsToUpdate = Get-SwisData $SwisConnection @"
SELECT c.ContainerID, c.Name, d.DynamicQuery
FROM Orion.Container c
JOIN Orion.ContainerDynamicQueries d ON c.ContainerID = d.ContainerID
WHERE d.DynamicQuery LIKE '%Alert_Enabled%'
"@

# Output for inspection
if ($groupsToUpdate.Count -eq 0) {
    Write-Host "No groups found with dynamic queries based on Alert_Enabled." -ForegroundColor Yellow
    return
}

Write-Host "Retrieved groups with dynamic queries based on Alert_Enabled:" -ForegroundColor Cyan
$groupsToUpdate | ForEach-Object { Write-Host " - Group: '$($_.Name)', ContainerID: '$($_.ContainerID)'" }

# Update each group to use SiteID in the dynamic query
foreach ($group in $groupsToUpdate) {
    # Construct the new dynamic query to use SiteID
    $newQuery = @"
(
    SELECT NodeID FROM Orion.NodesCustomProperties
    WHERE SiteID = '${group.Name}'
)
"@

    # Update the group with the new dynamic query
    Set-SwisObject $SwisConnection -Uri "/Orion/Orion.ContainerDynamicQueries/ContainerID=${group.ContainerID}" -Properties @{ DynamicQuery = $newQuery }
    Write-Host "Updated dynamic query for group '$($group.Name)' to use SiteID." -ForegroundColor Green
}

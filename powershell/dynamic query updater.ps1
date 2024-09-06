# Import Swis PowerShell module
Import-Module SwisPowerShell

# Connect to SolarWinds with interactive credentials
if (-not ($SwisConnection)) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    $SwisConnection = Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

# Get all containers with three-character names that do not have a ContainerID in Orion.ContainerMemberDefinition
$containersToUpdate = Get-SwisData $SwisConnection @"
SELECT c.ContainerID, c.Name
FROM Orion.Container c
WHERE LEN(c.Name) = 3
AND NOT EXISTS (
    SELECT 1 
    FROM Orion.ContainerMemberDefinition d
    WHERE d.ContainerID = c.ContainerID
)
"@

# Output for inspection
if ($containersToUpdate.Count -eq 0) {
    Write-Host "No containers found with three-character names without dynamic query definitions." -ForegroundColor Yellow
    return
}

Write-Host "Retrieved containers to update with new dynamic queries:" -ForegroundColor Cyan
$containersToUpdate | ForEach-Object { Write-Host " - Container: '$($_.Name)', ContainerID: '$($_.ContainerID)'" }

# Update each container with a new dynamic query based on SiteID
foreach ($container in $containersToUpdate) {
    # Construct the new dynamic query to use SiteID
    $newExpression = "Nodes.CustomProperties.SiteID = '$($container.Name)'"

    # Check if there's an existing entry in ContainerMemberDefinition; if not, create a new entry
    $existingEntry = Get-SwisData $SwisConnection @"
SELECT ContainerID 
FROM Orion.ContainerMemberDefinition 
WHERE ContainerID = $($container.ContainerID)
"@  # Ensure there is no whitespace before this terminator

    if ($existingEntry.Count -eq 0) {
        # Create a new entry with the new dynamic query
        New-SwisObject $SwisConnection -EntityType "Orion.ContainerMemberDefinition" -Properties @{
            ContainerID = $container.ContainerID
            Expression = $newExpression
        }
        Write-Host "Created new dynamic query for container '$($container.Name)'." -ForegroundColor Green
    } else {
        # Update the existing entry with the new dynamic query
        Set-SwisObject $SwisConnection -Uri "/Orion/Orion.ContainerMemberDefinition/ContainerID=$($container.ContainerID)" -Properties @{
            Expression = $newExpression
        }
        Write-Host "Updated dynamic query for container '$($container.Name)' to use SiteID." -ForegroundColor Green
    }
}

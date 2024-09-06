Import-Module SwisPowerShell

if (-not ($SwisConnection)) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    $SwisConnection = Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

$allContainers = Get-SwisData $SwisConnection @"
SELECT ContainerID, Name 
FROM Orion.Container
"@

$allMemberDefinitions = Get-SwisData $SwisConnection @"
SELECT ContainerID 
FROM Orion.ContainerMemberDefinition
"@

$containersToUpdate = $allContainers | Where-Object {
    $_.Name.Length -eq 3 -and -not ($allMemberDefinitions | Where-Object { $_.ContainerID -eq $_.ContainerID })
}

if ($containersToUpdate.Count -eq 0) {
    Write-Host "No containers found with three-character names without dynamic query definitions." -ForegroundColor Yellow
    return
}

Write-Host "Retrieved containers to update with new dynamic queries:" -ForegroundColor Cyan
$containersToUpdate | ForEach-Object { Write-Host " - Container: '$($_.Name)', ContainerID: '$($_.ContainerID)'" }

foreach ($container in $containersToUpdate) {
    $newExpression = "Nodes.CustomProperties.SiteID = '$($container.Name)'"

    $existingEntry = Get-SwisData $SwisConnection @"
SELECT ContainerID 
FROM Orion.ContainerMemberDefinition 
WHERE ContainerID = $($container.ContainerID)
"@

    if ($existingEntry.Count -eq 0) {
        New-SwisObject $SwisConnection -EntityType "Orion.ContainerMemberDefinition" -Properties @{
            ContainerID = $container.ContainerID
            Expression = $newExpression
        }
        Write-Host "Created new dynamic query for container '$($container.Name)'." -ForegroundColor Green
    } else {
        Set-SwisObject $SwisConnection -Uri "/Orion/Orion.ContainerMemberDefinition/ContainerID=$($container.ContainerID)" -Properties @{
            Expression = $newExpression
        }
        Write-Host "Updated dynamic query for container '$($container.Name)' to use SiteID." -ForegroundColor Green
    }
}

# Import Swis PowerShell module
Import-Module SwisPowerShell

# Connect to SolarWinds with interactive credentials
if (-not ($SwisConnection)) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    $SwisConnection = Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

# Query to get all unique SiteName values from Orion.NodesCustomProperties where no group exists for that SiteName
$group = Get-SwisData $SwisConnection @"
SELECT DISTINCT n.SiteName
FROM Orion.NodesCustomProperties n
LEFT JOIN Orion.Container c ON c.Name = n.SiteName
WHERE c.Name IS NULL AND n.SiteName NOT IN ('')
ORDER BY n.SiteName
"@

# Check and display the results of the $group query
if ($group.Count -eq 0) {
    Write-Host "No new groups need to be created. All SiteNames already have corresponding groups."
    return
}

Write-Host "SiteNames found without groups:" -ForegroundColor Cyan
$group | ForEach-Object { Write-Host " - $($_.SiteName)" }

# Iterate over each unique SiteName and create a group for it if not already present
foreach ($site in $group) {
    $siteName = $site.SiteName

    # Skip if SiteName is empty or null
    if (-not $siteName) {
        continue
    }

    Write-Host "Creating group for SiteName: $siteName"

    # Define the dynamic query for the group to include nodes with the specific SiteName
    $members = @(
        @{
            Name = $siteName
            Definition = "filter:/Orion.Nodes[CustomProperties.SiteName='$siteName']"
        }
    )

    # Create the group using Invoke-SwisVerb
    $groupId = (Invoke-SwisVerb $SwisConnection "Orion.Container" "CreateContainer" @(
        # Group name
        $siteName,
        # Owner, must be 'Core'
        "Core",
        # Refresh frequency
        60,
        # Status rollup mode:
        # 0 = Mixed status shows warning
        # 1 = Show worst status
        # 2 = Show best status
        0,
        # Group description
        "",
        # Polling enabled/disabled = true/false (in lowercase)
        "true",
        # Group members
        ([xml]@(
           "<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>",
           [string]($members | % {
               "<MemberDefinitionInfo><Name>$($_.Name)</Name><Definition>$($_.Definition)</Definition></MemberDefinitionInfo>"
           }),
           "</ArrayOfMemberDefinitionInfo>"
        )).DocumentElement
    )).InnerText

    if ($groupId) {
        Write-Host "Group created with ID: $groupId for SiteName: $siteName"
    } else {
        Write-Host "Failed to create group for SiteName: $siteName" -ForegroundColor Red
    }
}

Write-Host "All groups have been created and configured with dynamic queries based on SiteName." -ForegroundColor Green

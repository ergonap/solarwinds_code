# Import Swis PowerShell module
Import-Module SwisPowerShell

# Connect to SolarWinds with interactive credentials
if (-not ($SwisConnection)) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    $SwisConnection = Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

# Get all unique SiteName values from the nodes
$SwqlQuery = @"
    SELECT DISTINCT n.CustomProperties.SiteName
    FROM Orion.Nodes n
    WHERE n.CustomProperties.SiteName IS NOT NULL
"@

# Run the query and assign the results to the $siteNames array
$siteNames = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery

# Iterate over each unique SiteName and create a group for it
foreach ($site in $siteNames) {
    $siteName = $site.SiteName

    # Skip if SiteName is empty or null
    if (-not $siteName) {
        continue
    }

    Write-Host "Creating group for SiteName: $siteName"

    # Define the properties for the new group
    $groupProperties = @{
        Name = "Group for Site: $siteName"
        Description = "Automatically managed group for site: $siteName"
        AccountID = "admin" # Adjust this to the appropriate account or leave empty for default
        AllowDelete = $true
    }

    # Create the group
    $groupUri = New-SwisObject -SwisConnection $SwisConnection -EntityType "Orion.Container" -Properties $groupProperties

    Write-Host "Group created with URI: $groupUri"

    # Define a dynamic query for the group to include nodes with the specific SiteName
    $dynamicQuery = @{
        Name = "Dynamic Query for Site: $siteName"
        Query = "SELECT Uri FROM Orion.Nodes WHERE CustomProperties.SiteName = '$siteName'"
        Definition = @{
            Rules = @(
                @{
                    Entity = "Orion.Nodes"
                    Condition = @{
                        Property = "CustomProperties.SiteName"
                        Operator = "Equal"
                        Value = $siteName
                    }
                }
            )
        }
    }

    # Add the dynamic query to the group
    $dynamicQueryUri = New-SwisObject -SwisConnection $SwisConnection -EntityType "Orion.ContainerMemberDefinition" -Properties @{
        ContainerID = $groupUri.ContainerID
        Name = $dynamicQuery.Name
        Definition = ($dynamicQuery.Definition | ConvertTo-Json)
    }

    Write-Host "Dynamic query created for group with URI: $dynamicQueryUri"
}

Write-Host "All groups have been created and configured with dynamic queries based on SiteName." -ForegroundColor Green

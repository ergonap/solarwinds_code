
Import-Module SwisPowerShell

if (-not ($SwisConnection)) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    $SwisConnection = Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

# Query to get all nodes with their NodeID and Caption
$SwqlQuery = @"
SELECT NodeID, Caption 
FROM Orion.Nodes
"@

# Get all nodes from SolarWinds
$Nodes = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery

# Loop through each node and set the SiteName custom property
foreach ($Node in $Nodes) {
    # Extract the first three letters of the node caption
    $SiteName = $Node.Caption.Substring(0, 3)

    # Correctly construct the URI for updating the node
    $Uri = "swis://$OrionServer/Orion/Nodes/NodeID=$($Node.NodeID)"

    # Update the custom property 'SiteName'
    Set-SwisObject -SwisConnection $SwisConnection -Uri $Uri -Properties @{ SiteName = $SiteName }

    Write-Host "Updated NodeID $($Node.NodeID) - Caption: $($Node.Caption) with SiteName: $SiteName"
}

Write-Host "All nodes have been updated with SiteName custom property." -ForegroundColor Green

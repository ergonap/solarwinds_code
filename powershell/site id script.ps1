# Import Swis PowerShell module
Import-Module SwisPowerShell

# Connect to SolarWinds with interactive credentials
if (-not ($SwisConnection)) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    $SwisConnection = Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

# Build the SWQL query to get all nodes with their NodeID, Caption, and Uri
$SwqlQuery = @"
    SELECT
        n.NodeID,
        n.Caption,
        n.Uri
    FROM Orion.Nodes n
"@

# Run the query and assign the results to the $nodes array
$nodes = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery

# Iterate over each node and set the SiteName custom property
foreach ($node in $nodes) {
    # Extract the first three letters of the node caption and convert to uppercase
    $SiteName = $node.Caption.Substring(0, 3).ToUpper()

    # Write out which node we're working with
    Write-Host "Working with node: $($node.Caption)..."

    # Construct the SWIS URI for the custom properties of this node
    $customPropertiesUri = "$($node.Uri)/CustomProperties"

    # Update the custom property 'SiteName'
    Set-SwisObject -SwisConnection $SwisConnection -Uri $customPropertiesUri -Properties @{ SiteName = $SiteName }

    Write-Host "Updated NodeID $($node.NodeID) - Caption: $($node.Caption) with SiteName: $SiteName"
}

Write-Host "All nodes have been updated with SiteName custom property in uppercase." -ForegroundColor Green

# Load the Swis snap-in if it's not already loaded
if (!(Get-PSSnapin | Where-Object { $_.Name -eq "SwisSnapin" })) {
    Add-PSSnapin "SwisSnapin"
}

# Define target host and connect to SolarWinds using trusted credentials
$hostname = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
$swis = Connect-Swis -Hostname $hostname -Trusted

# Build the SWQL query to get all nodes with their NodeID, Caption, and Uri
$query = @"
    SELECT
        n.NodeID,
        n.Caption,
        n.Uri
    FROM Orion.Nodes n
"@

# Run the query and assign the results to the $nodes array
$nodes = Get-SwisData $swis $query

# Iterate over each node and set the SiteName custom property
foreach ($node in $nodes) {
    # Extract the first three letters of the node caption and convert to uppercase
    $SiteName = $node.Caption.Substring(0, 3).ToUpper()

    # Write out which node we're working with
    Write-Host "Working with node: $($node.Caption)..."

    # Construct the SWIS URI for the custom properties of this node
    $customPropertiesUri = "$($node.Uri)/CustomProperties"

    # Update the custom property 'SiteName'
    Set-SwisObject -SwisConnection $swis -Uri $customPropertiesUri -Properties @{ SiteName = $SiteName }

    Write-Host "Updated NodeID $($node.NodeID) - Caption: $($node.Caption) with SiteName: $SiteName"
}

Write-Host "All nodes have been updated with SiteName custom property in uppercase." -ForegroundColor Green

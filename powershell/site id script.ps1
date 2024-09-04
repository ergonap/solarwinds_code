# this script will take the FIRST THREE LETTERS of a node only and then assign that as a custom property named SiteName
Import-Module SwisPowerShell


if (-not ($SwisConnection)) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    $SwisConnection = Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

$SwqlQuery = @"
    SELECT
        n.NodeID,
        n.Caption,
        n.Uri
    FROM Orion.Nodes n
"@


$nodes = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery

# Iterate over each node and set the SiteName custom property
foreach ($node in $nodes) {
    # Extract the first three letters of the node caption and convert to uppercase
    $SiteName = $node.Caption.Substring(0, 3).ToUpper()

    # Write out which node we're working with
    Write-Host "Working with node: $($node.Caption)..."
    $customPropertiesUri = "$($node.Uri)/CustomProperties"
    #update CP
    Set-SwisObject -SwisConnection $SwisConnection -Uri $customPropertiesUri -Properties @{ SiteName = $SiteName }
    Write-Host "Updated NodeID $($node.NodeID) - Caption: $($node.Caption) with SiteName: $SiteName"
}

Write-Host "All nodes have been updated with SiteName custom property in uppercase." -ForegroundColor Green

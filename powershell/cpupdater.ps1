Import-Module -Name SwisPowerShell

$hostname = 'myOrionServer'
$creds = Get-Credential
$swis = Connect-Swis -Hostname $hostname -Credential $creds

# Define the SWQL query
$SwqlQuery = @"
SELECT Caption, IPAddress, Location, Uri
FROM Orion.Nodes
WHERE Location NOT LIKE '' AND Location NOT LIKE '(Site Code)'
"@

# Execute the SWQL query to get nodes with the specified conditions
$nodes = Get-SwisData -SwisConnection $swis -Query $SwqlQuery

if ($nodes.Count -eq 0) {
    Write-Host "No matching nodes found." -ForegroundColor Yellow
    exit
}

# Update the custom property LocationData for each node
foreach ($node in $nodes) {
    $cpUri = $node.Uri + "/CustomProperties"
    $properties = @{
        LocationData = $node.Location
    }

    # Update the custom property
    Set-SwisObject -SwisConnection $swis -Uri $cpUri -Properties $properties
    Write-Host "Updated LocationData for node $($node.Caption) to $($node.Location)" -ForegroundColor Green
}

Write-Host "Completed updating custom properties." -ForegroundColor Green

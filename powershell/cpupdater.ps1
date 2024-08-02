Add-Type -AssemblyName System.Windows.Forms

# SWQL query to select nodes with a non-empty location
$SwqlQuery = @"
SELECT Caption, IPAddress, Location, Uri
FROM Orion.Nodes
WHERE Location NOT LIKE '' AND Location NOT LIKE '(Site Code)'
"@

function Get-SwisConnection {
    param (
        [string]$OrionServer
    )
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    return Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

if (-not ($SwisConnection)) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisConnection = Get-SwisConnection -OrionServer $OrionServer
}

# Test the SWIS connection
function Test-Connection {
    param (
        [object]$SwisConnection
    )
    try {
        $null = Get-SwisData -SwisConnection $SwisConnection -Query "SELECT TOP 1 NodeID FROM Orion.Nodes"
        return $true
    } catch {
        return $false
    }
}

# Test the connection
if (Test-Connection -SwisConnection $SwisConnection) {
    Write-Host "Connection established successfully." -ForegroundColor Green
} else {
    Write-Host "Failed to establish connection." -ForegroundColor Red
    exit
}

# Execute the SWQL query to get the nodes
$QueryResults = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery

# Check if there are any results
if ($QueryResults) {
    foreach ($node in $QueryResults) {
        $cpUri = $node.Uri + "/CustomProperties"
        $LocationData = $node.Location
        
        try {
            Set-SwisObject -SwisConnection $SwisConnection -Uri $cpUri -Properties @{
                LocationData = $LocationData
            }
            Write-Host "Updated LocationData for node $($node.Caption) to $LocationData" -ForegroundColor Green
        } catch {
            Write-Host "Failed to update LocationData for node $($node.Caption)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "No results found for the query." -ForegroundColor Yellow
}

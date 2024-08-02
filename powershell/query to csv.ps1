#

Add-Type -AssemblyName System.Windows.Forms

# SWQL
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

# test
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

# Prompt the user for the output file path using a SaveFileDialog
$SaveFileDialog = New-Object -TypeName System.Windows.Forms.SaveFileDialog
$SaveFileDialog.Filter = "CSV files (*.csv)|*.csv"
$SaveFileDialog.Title = "Save the query results to a CSV file"
$SaveFileDialog.ShowDialog() | Out-Null
$OutputFilePath = $SaveFileDialog.FileName

# Check if the user provided a file path
if ([string]::IsNullOrWhiteSpace($OutputFilePath)) {
    Write-Host "No file path selected. Exiting script." -ForegroundColor Yellow
    exit
}

# Execute the SWQL query and export the results to a CSV file
$QueryResults = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery
if ($QueryResults) {
    $QueryResults | Export-Csv -Path $OutputFilePath -NoTypeInformation
    Write-Host "Query results have been exported to $OutputFilePath" -ForegroundColor Green
} else {
    Write-Host "No results found for the query." -ForegroundColor Yellow
}

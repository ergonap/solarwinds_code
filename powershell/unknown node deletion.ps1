<#
Script to delete all nodes where the vendor is unknown
#>

$SwqlQuery = @"
SELECT [Nodes].NodeID, [Nodes].Caption, [Nodes].Vendor, [Nodes].Uri 
FROM Orion.Nodes AS [Nodes]
WHERE [Nodes].Vendor = 'Unknown'
"@

if (-not ($SwisConnection)) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    $SwisConnection = Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

$NodesToDelete = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery
if ($NodesToDelete) {
    Write-Host "Nodes with unknown vendor proposed for deletion:" -ForegroundColor Red
    $NodesToDelete | ForEach-Object {
        Write-Host "NodeID: $( $_.NodeID ), Caption: $( $_.Caption ), Vendor: $( $_.Vendor )" -ForegroundColor Red
    }
    Write-Host "Total Count: $( $NodesToDelete.Count )" -ForegroundColor Red

    $DoDelete = Read-Host -Prompt "Would you like to proceed with deleting these nodes? [Type 'delete' to confirm]"
    if ($DoDelete.ToLower() -eq 'delete') {
        $NodesToDelete.Uri | ForEach-Object {
            Remove-SwisObject -SwisConnection $SwisConnection -Uri $_
            Write-Host "Node $( $_ ) has been removed." -ForegroundColor Green
        }
    } else {
        Write-Host "'delete' response not received - No deletions were processed" -ForegroundColor Yellow
    }
} else {
    Write-Host "No nodes with unknown vendor found." -ForegroundColor Green
}

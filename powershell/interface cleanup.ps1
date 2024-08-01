<#
Simple script to display and then delete unnecessary interfaces
#>

$SwqlQuery = @"
SELECT [Interfaces].Caption, [Interfaces].NodeID, [Interfaces].Name, [Interfaces].Uri, [Interfaces].InPercentUtil, [Interfaces].OutPercentUtil 
FROM Orion.NPM.Interfaces AS [Interfaces]
WHERE [Interfaces].Name LIKE 'Loop%'
"@

if (-not ($SwisConnection)) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    $SwisConnection = Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

$InterfacesToDelete = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery
if ($InterfacesToDelete) {
    Write-Host "Proposed interfaces for deletion:" -ForegroundColor Red
    $InterfacesToDelete | ForEach-Object {
        Write-Host "$( $_.Name ) on NodeID $( $_.NodeID ) [In: $( $_.InPercentUtil )%, Out: $( $_.OutPercentUtil )%]" -ForegroundColor Red
    }
    Write-Host "Total Count: $( $InterfacesToDelete.Count )" -ForegroundColor Red

    $DoDelete = Read-Host -Prompt "Would you like to proceed? [Type 'delete' to confirm]"
    if ($DoDelete.ToLower() -eq 'delete') {
        $InterfacesToDelete.Uri | Remove-SwisObject -SwisConnection $SwisConnection
    } else {
        Write-Host "'delete' response not received - No deletions were processed" -ForegroundColor Yellow
    }
}

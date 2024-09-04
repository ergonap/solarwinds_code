# this version assumes there's a dash in the third character, then updates the sitename based on the following 3 letter code AFTER that.

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
    WHERE SUBSTRING(n.Caption, 2, 1) = '-'
"@

$nodes = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery

foreach ($node in $nodes) {
    # Check if the caption has enough characters after the dash
    if ($node.Caption.Length -ge 6) {
        # Extract the next three letters after the dash and convert to uppercase
        $SiteName = $node.Caption.Substring(3, 3).ToUpper()

        Write-Host "Working with node: $($node.Caption)..."
        $customPropertiesUri = "$($node.Uri)/CustomProperties"
        # Update the custom property 'SiteName'
        Set-SwisObject -SwisConnection $SwisConnection -Uri $customPropertiesUri -Properties @{ SiteName = $SiteName }

        Write-Host "Updated NodeID $($node.NodeID) - Caption: $($node.Caption) with SiteName: $SiteName"
    } else {
        Write-Host "Skipping NodeID $($node.NodeID) - Caption: $($node.Caption) as it does not have enough characters after the dash." -ForegroundColor Yellow
    }
}

Write-Host "All applicable nodes have been updated with SiteName custom property in uppercase." -ForegroundColor Green

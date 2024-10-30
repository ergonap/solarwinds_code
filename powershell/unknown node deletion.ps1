<#------------- CONNECT TO SWIS -------------#>

# Prompt for old server's hostname and credentials
$HostnameOld = Read-Host -Prompt "Please enter the DNS name or IP Address for the OLD Orion Server"
$SwisCredentialsOld = Get-Credential -Message "Enter your Orion credentials for $HostnameOld"
$SwisSource = Connect-Swis -Hostname $HostnameOld -Credential $SwisCredentialsOld

# Prompt for new server's hostname and credentials
$HostnameNew = Read-Host -Prompt "Please enter the DNS name or IP Address for the NEW Orion Server"
$SwisCredentialsNew = Get-Credential -Message "Enter your Orion credentials for $HostnameNew"
$SwisDest = Connect-Swis -Hostname $HostnameNew -Credential $SwisCredentialsNew

<#------------- ACTUAL SCRIPT -------------#>

# Get Alert IDs for enabled alerts
$AlertIDs = Get-SwisData -SwisConnection $SwisSource -Query "SELECT AlertID FROM Orion.AlertConfigurations WHERE Enabled = 'true' and name not like '%syslog%'"

# Migrate the alerts
foreach ($AlertID in $AlertIDs) {
    $AlertName = Get-SwisData -SwisConnection $SwisSource -Query "SELECT Name FROM Orion.AlertConfigurations WHERE AlertID = $AlertID"
    $Existing = Get-SwisData -SwisConnection $SwisDest -Query "SELECT Name FROM Orion.AlertConfigurations WHERE Name = '$AlertName'"
    
    if ($Existing.Count -eq 0) { 
        Write-Output "Migrating alert named: $AlertName"
        $ExportedAlert = Invoke-SwisVerb -SwisConnection $SwisSource -EntityName Orion.AlertConfigurations -Verb Export -Arguments $AlertID
        Invoke-SwisVerb -SwisConnection $SwisDest -EntityName Orion.AlertConfigurations -Verb Import -Arguments $ExportedAlert
    } else { 
        Write-Output "Alert named: $AlertName already exists, skipping" 
    }
}


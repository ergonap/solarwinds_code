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

# Get Group IDs and Names for enabled groups
$GroupIDs = Get-SwisData -SwisConnection $SwisSource -Query "SELECT ContainerID, Name FROM Orion.Container"

# Migrate the groups
foreach ($Group in $GroupIDs) {
    $GroupID = $Group.ContainerID
    $GroupName = $Group.Name

    # Check if the group already exists in the destination
    $ExistingGroup = Get-SwisData -SwisConnection $SwisDest -Query "SELECT Name FROM Orion.Container WHERE Name = '$GroupName'"
    
    if ($ExistingGroup.Count -eq 0) { 
        Write-Output "Migrating group named: $GroupName"
        
        # Export and import the group
        $ExportedGroup = Invoke-SwisVerb -SwisConnection $SwisSource -EntityName Orion.Container -Verb Export -Arguments $GroupID
        Invoke-SwisVerb -SwisConnection $SwisDest -EntityName Orion.Container -Verb Import -Arguments $ExportedGroup
    } else { 
        Write-Output "Group named: $GroupName already exists, skipping" 
    }
}

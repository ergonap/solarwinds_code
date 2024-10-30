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

# Get Group details
$Groups = Get-SwisData -SwisConnection $SwisSource -Query "SELECT ContainerID, Name, Description FROM Orion.Container"

# Migrate the groups
foreach ($Group in $Groups) {
    $GroupID = $Group.ContainerID
    $GroupName = $Group.Name
    $GroupDescription = $Group.Description

    # Check if the group already exists in the destination
    $ExistingGroup = Get-SwisData -SwisConnection $SwisDest -Query "SELECT Name FROM Orion.Container WHERE Name = '$GroupName'"
    
    if ($ExistingGroup.Count -eq 0) { 
        Write-Output "Migrating group named: $GroupName"
        
        # Get the dynamic query for the group from the source
        $DynamicQuery = Get-SwisData -SwisConnection $SwisSource -Query "SELECT Expression FROM Orion.ContainerMemberDefinition WHERE ContainerID = $GroupID"

        # Create the group in the destination
        $NewGroupID = New-SwisObject -SwisConnection $SwisDest -EntityName "Orion.Container" -Properties @{
            Name = $GroupName
            Description = $GroupDescription
            Enabled = 'true'
        }

        # Apply the dynamic query to the newly created group if there is one
        foreach ($Query in $DynamicQuery) {
            New-SwisObject -SwisConnection $SwisDest -EntityName "Orion.ContainerMemberDefinition" -Properties @{
                ContainerID = $NewGroupID
                Expression = $Query.Expression
            }
        }
    } else { 
        Write-Output "Group named: $GroupName already exists, skipping" 
    }
}

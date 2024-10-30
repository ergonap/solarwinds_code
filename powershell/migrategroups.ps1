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
        
        # Format dynamic queries into the members array
        $members = @()
        foreach ($Query in $DynamicQuery) {
            $members += @{ Name = $GroupName; Definition = "filter:/Orion.Nodes[$($Query.Expression)]" }
        }

        # Convert members to XML format
        $memberXml = [xml]@(
            "<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>",
            [string]($members | ForEach-Object {
                "<MemberDefinitionInfo><Name>$($_.Name)</Name><Definition>$($_.Definition)</Definition></MemberDefinitionInfo>"
            }),
            "</ArrayOfMemberDefinitionInfo>"
        ).DocumentElement

        # Create the group in the destination with dynamic members
        $groupId = Invoke-SwisVerb -SwisConnection $SwisDest -EntityName "Orion.Container" -Verb "CreateContainer" -Arguments @(
            $GroupName,       # Group Name
            "Core",           # Owner, must be 'Core'
            60,               # Refresh Frequency (in seconds)
            0,                # Status Rollup Mode: 0 = Mixed Status Shows Warning
            $GroupDescription, # Group Description
            "true",           # Polling Enabled (true)
            $memberXml        # Group Members in XML format
        ).InnerText
    } else { 
        Write-Output "Group named: $GroupName already exists, skipping" 
    }
}

<#------------- FUNCTIONS -------------#>
Function Set-SwisConnection {  
    Param(  
        [Parameter(Mandatory=$true, HelpMessage = "What SolarWinds server are you connecting to (Hostname or IP)?" ) ] [string] $solarWindsServer,  
        [Parameter(Mandatory=$true, HelpMessage = "Do you want to use the credentials from PowerShell [Trusted], or a new login [Explicit]?" ) ] [ ValidateSet( 'Trusted', 'Explicit' ) ] [ string ] $connectionType,  
        [Parameter(HelpMessage = "Which credentials should we use for an explicit logon type" ) ] $creds
    )  
     
    IF ( $connectionType -eq 'Trusted'  ) {  
        $swis = Connect-Swis -Trusted -Hostname $solarWindsServer  
    } ELSEIF(!$creds) {  
        $creds = Get-Credential -Message "Please provide a Domain or Local Login for SolarWinds"  
        $swis = Connect-Swis -Credential $creds -Hostname $solarWindsServer  
    } ELSE {
        $swis = Connect-Swis -Credential $creds -Hostname $solarWindsServer  
    } 

    RETURN $swis  
}  

# Function to convert CIDR to Subnet Mask
function Convert-CidrToSubnetMask {
    param (
        [int]$cidr
    )
    $binaryMask = ('1' * $cidr).PadRight(32, '0')
    $subnetMask = [convert]::ToInt32($binaryMask.Substring(0, 8), 2).ToString() + '.' +
                  [convert]::ToInt32($binaryMask.Substring(8, 8), 2).ToString() + '.' +
                  [convert]::ToInt32($binaryMask.Substring(16, 8), 2).ToString() + '.' +
                  [convert]::ToInt32($binaryMask.Substring(24, 8), 2).ToString()
    return $subnetMask
}

<#------------- ACTUAL SCRIPT -------------#>
clear-host

# Prompt user for hostname and connection type
$hostname = Read-Host -Prompt "What server should we connect to?"
$connectionType = Read-Host -Prompt "Should we use the current PowerShell credentials [Trusted], or specify credentials [Explicit]?"

# Establish the SWIS connection using the new permissions model
$swis = Set-SwisConnection -solarWindsServer $hostname -connectionType $connectionType

# Path to your XLSX file containing subnets
$xlsxPath = "C:\path\to\your\subnets.xlsx"

# Import Excel module if needed
# Import-Module ImportExcel

# Import the XLSX file
$subnets = Import-Excel $xlsxPath # Use Import-Csv if saved as CSV

# Group the subnets by Level 1 and Level 2
$groupedSubnets = $subnets | Group-Object -Property Level1, Level2

# Get the engines from SWIS (replace this with your actual query if needed)
$nodes = get-swisdata $swis "select ip_address, engineid from orion.nodes n where n.vendor = 'Cisco'"
$engines = $nodes.engineid | sort-object | Get-Unique

foreach ($group in $groupedSubnets) {
    $level1 = $group.Name.Split(',')[0].Trim()
    $level2 = $group.Name.Split(',')[1].Trim()

    foreach ($engine in $engines) {
        $header = "<CorePluginConfigurationContext xmlns='http://schemas.solarwinds.com/2012/Orion/Core' xmlns:i='http://www.w3.org/2001/XMLSchema-instance'>"
        $subnetList = "<Subnets>"

        # Add subnets from the group to SubnetList
        foreach ($subnet in $group.Group) {
            $cidr = $subnet.Subnet.Split('/')[-1] # Extract the CIDR value (e.g., 22)
            $subnetIP = $subnet.Subnet.Split('/')[0] # Extract the base IP (e.g., 10.124.16.0)
            $subnetMask = Convert-CidrToSubnetMask -cidr $cidr
            $subnetList += "<Subnet><SubnetIP>$subnetIP</SubnetIP><SubnetMask>$subnetMask</SubnetMask></Subnet>"
        }

        $subnetList += "</Subnets>"

        $creds = Get-SwisData $swis $credquery
        $order = 1
        $credentials = "<Credentials>"

        foreach ($row in $creds) {
            $credentials += "<SharedCredentialInfo><CredentialID>$($row)</CredentialID><Order>$order</Order></SharedCredentialInfo>"
            $order ++
        }
        $credentials += "</Credentials>"

        $footer = @"
        <WmiRetriesCount>1</WmiRetriesCount>
        <WmiRetryIntervalMiliseconds>1000</WmiRetryIntervalMiliseconds>
        </CorePluginConfigurationContext>
    "@

        $CorePluginConfigurationContext = ([xml]($header + $subnetList + $credentials + $footer)).DocumentElement
        $CorePluginConfiguration = Invoke-SwisVerb $swis Orion.Discovery CreateCorePluginConfiguration @($CorePluginConfigurationContext)

        $InterfacesPluginConfigurationContext = ([xml]"
        <InterfacesDiscoveryPluginContext xmlns='http://schemas.solarwinds.com/2008/Interfaces' 
                                          xmlns:a='http://schemas.microsoft.com/2003/10/Serialization/Arrays'>
            <AutoImportStatus>
                <a:string>Up</a:string>
                <a:string>Down</a:string>
                <a:string>Shutdown</a:string>
            </AutoImportStatus>
            <AutoImportVirtualTypes>
                <a:string>Virtual</a:string>
                <a:string>Physical</a:string>
            </AutoImportVirtualTypes>
            <AutoImportVlanPortTypes>
                <a:string>Trunk</a:string>
                <a:string>Access</a:string>
                <a:string>Unknown</a:string>
            </AutoImportVlanPortTypes>
            <UseDefaults>true</UseDefaults>
        </InterfacesDiscoveryPluginContext>
        ").DocumentElement

        $InterfacesPluginConfiguration = Invoke-SwisVerb $swis Orion.NPM.Interfaces CreateInterfacesPluginConfiguration @($InterfacesPluginConfigurationContext)

        $StartDiscoveryContext = ([xml]"
        <StartDiscoveryContext xmlns='http://schemas.solarwinds.com/2012/Orion/Core' xmlns:i='http://www.w3.org/2001/XMLSchema-instance'>
            <Name>Scripted Discovery for $level1-$level2 - $([DateTime]::Now)</Name>
            <EngineId>$Engine</EngineId>
            <JobTimeoutSeconds>36000</JobTimeoutSeconds>
            <SearchTimeoutMiliseconds>2000</SearchTimeoutMiliseconds>
            <SnmpTimeoutMiliseconds>2000</SnmpTimeoutMiliseconds>
            <SnmpRetries>1</SnmpRetries>
            <RepeatIntervalMiliseconds>1500</RepeatIntervalMiliseconds>
            <SnmpPort>161</SnmpPort>
            <HopCount>0</HopCount>
            <PreferredSnmpVersion>SNMP2c</PreferredSnmpVersion>
            <DisableIcmp>true</DisableIcmp>
            <AllowDuplicateNodes>false</AllowDuplicateNodes>
            <IsAutoImport>true</IsAutoImport>
            <IsHidden>$DeleteProfileAfterDiscoveryCompletes</IsHidden>
            <PluginConfigurations>
                <PluginConfiguration>
                    <PluginConfigurationItem>$($CorePluginConfiguration.InnerXml)</PluginConfigurationItem>
                    <PluginConfigurationItem>$($InterfacesPluginConfiguration.InnerXml)</PluginConfigurationItem>
                </PluginConfiguration>
            </PluginConfigurations>
        </StartDiscoveryContext>
        ").DocumentElement

        $DiscoveryProfileID = (Invoke-SwisVerb $swis Orion.Discovery StartDiscovery @($StartDiscoveryContext)).InnerText

        "Created Scripted Discovery for $level1-$level2 - $([DateTime]::Now)"
    }
}

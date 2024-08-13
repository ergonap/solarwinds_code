<#------------- FUNCTIONS -------------#>

# Function to set up the SWIS connection
Function Set-SwisConnection {  
    Param(  
        [Parameter(Mandatory=$true, HelpMessage = "What SolarWinds server are you connecting to (Hostname or IP)?" ) ] 
        [string] $solarWindsServer,  
        
        [Parameter(Mandatory=$true, HelpMessage = "Do you want to use the credentials from PowerShell [Trusted], or a new login [Explicit]?" ) ] 
        [ ValidateSet( 'Trusted', 'Explicit' ) ] 
        [ string ] $connectionType,  
        
        [Parameter(HelpMessage = "Which credentials should we use for an explicit logon type" ) ] 
        $creds
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

<#------------- MAIN SCRIPT -------------#>

clear-host

# Prompt user for hostname and connection type
$hostname = Read-Host -Prompt "What server should we connect to?"
$connectionType = Read-Host -Prompt "Should we use the current PowerShell credentials [Trusted], or specify credentials [Explicit]?"

# Establish the SWIS connection using the new permissions model
$swis = Set-SwisConnection -solarWindsServer $hostname -connectionType $connectionType

# Query to get list of SNMPv3 creds in use currently
$query = @"
SELECT id
FROM Orion.Credential
WHERE credentialowner='Orion' AND credentialtype = 'SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV3'
"@
$creds = Get-SwisData $swis $query

# Might need to change this for your environment
$EngineID = 1
$DeleteProfileAfterDiscoveryCompletes = "false"

# Import addresses from CSV file
$pathtocsv = "D:\Scripts\Discovery\SampleImport.csv"
$importedData = Import-Csv -Path $pathtocsv -Header Column1, Column2, Column3, Column4, Column5

# Initialize the XML string for the bulk list and subnets
$bulklistXml = ""
$subnetsXml = ""

foreach ($row in $importedData) {
    # Generate discovery name from Column2 and Column3
    $discoveryName = "$($row.Column2) $($row.Column3)"
    
    # Extract the subnet and convert CIDR to subnet mask
    $cidrParts = $row.Column5.Split('/')
    $subnetIP = $cidrParts[0]
    $cidr = [int]$cidrParts[1]
    $subnetMask = Convert-CidrToSubnetMask -cidr $cidr

    # Add the subnet to the discovery context
    $subnetsXml += "<Subnet><SubnetIP>$subnetIP</SubnetIP><SubnetMask>$subnetMask</SubnetMask></Subnet>"
}

# Build credentials XML
$order = 0
$credentialsXml = "<Credentials>"
foreach ($row in $creds) {
    $order++
    $credentialsXml += "<SharedCredentialInfo><CredentialID>$($row.id)</CredentialID><Order>$order</Order></SharedCredentialInfo>"
}
$credentialsXml += "</Credentials>"

# Complete XML context for CorePluginConfigurationContext
$CorePluginConfigurationContextXml = @"
<CorePluginConfigurationContext xmlns='http://schemas.solarwinds.com/2012/Orion/Core' xmlns:i='http://www.w3.org/2001/XMLSchema-instance'>
    <BulkList></BulkList>
    <Subnets>$subnetsXml</Subnets>
    $credentialsXml
    <WmiRetriesCount>1</WmiRetriesCount>
    <WmiRetryIntervalMiliseconds>1000</WmiRetryIntervalMiliseconds>
</CorePluginConfigurationContext>
"@

$CorePluginConfigurationContext = [xml]$CorePluginConfigurationContextXml
$CorePluginConfiguration = Invoke-SwisVerb $swis Orion.Discovery CreateCorePluginConfiguration @($CorePluginConfigurationContext)

$InterfacesPluginConfigurationContextXml = @"
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
"@
$InterfacesPluginConfigurationContext = [xml]$InterfacesPluginConfigurationContextXml

$InterfacesPluginConfiguration = Invoke-SwisVerb $swis Orion.NPM.Interfaces CreateInterfacesPluginConfiguration @($InterfacesPluginConfigurationContext)

$StartDiscoveryContextXml = @"
<StartDiscoveryContext xmlns='http://schemas.solarwinds.com/2012/Orion/Core' xmlns:i='http://www.w3.org/2001/XMLSchema-instance'>
    <Name>$discoveryName $([DateTime]::Now)</Name>
    <EngineId>$EngineID</EngineId>
    <JobTimeoutSeconds>3600</JobTimeoutSeconds>
    <SearchTimeoutMiliseconds>2000</SearchTimeoutMiliseconds>
    <SnmpTimeoutMiliseconds>2000</SnmpTimeoutMiliseconds>
    <SnmpRetries>1</SnmpRetries>
    <RepeatIntervalMiliseconds>1500</RepeatIntervalMiliseconds>
    <SnmpPort>161</SnmpPort>
    <HopCount>0</HopCount>
    <PreferredSnmpVersion>SNMPv3</PreferredSnmpVersion>
    <DisableIcmp>false</DisableIcmp>
    <AllowDuplicateNodes>false</AllowDuplicateNodes>
    <IsAutoImport>$autoImport</IsAutoImport>
    <IsHidden>$DeleteProfileAfterDiscoveryCompletes</IsHidden>
    <PluginConfigurations>
        <PluginConfiguration>
            <PluginConfigurationItem>$($CorePluginConfiguration.InnerXml)</PluginConfigurationItem>
            <PluginConfigurationItem>$($InterfacesPluginConfiguration.InnerXml)</PluginConfigurationItem>
        </PluginConfiguration>
    </PluginConfigurations>
</StartDiscoveryContext>
"@
$StartDiscoveryContext = [xml]$StartDiscoveryContextXml

$DiscoveryProfileID = (Invoke-SwisVerb $swis Orion.Discovery StartDiscovery @($StartDiscoveryContext)).InnerText

Write-Host "Discovery started. Profile ID: $DiscoveryProfileID"

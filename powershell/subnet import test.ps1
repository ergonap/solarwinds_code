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

# Construct the CorePluginConfigurationContext using New-Object to create XML elements
$CorePluginConfigurationContext = New-Object System.Xml.XmlDocument
$root = $CorePluginConfigurationContext.CreateElement('CorePluginConfigurationContext')
$root.SetAttribute('xmlns', 'http://schemas.solarwinds.com/2012/Orion/Core')
$root.SetAttribute('xmlns:i', 'http://www.w3.org/2001/XMLSchema-instance')

$bulkListElement = $CorePluginConfigurationContext.CreateElement('BulkList')
$root.AppendChild($bulkListElement)

$subnetsElement = $CorePluginConfigurationContext.CreateElement('Subnets')
$subnetsElement.InnerXml = $subnetsXml
$root.AppendChild($subnetsElement)

$credentialsElement = $CorePluginConfigurationContext.CreateElement('Credentials')
$credentialsElement.InnerXml = $credentialsXml
$root.AppendChild($credentialsElement)

$wmiRetriesCountElement = $CorePluginConfigurationContext.CreateElement('WmiRetriesCount')
$wmiRetriesCountElement.InnerText = '1'
$root.AppendChild($wmiRetriesCountElement)

$wmiRetryIntervalElement = $CorePluginConfigurationContext.CreateElement('WmiRetryIntervalMiliseconds')
$wmiRetryIntervalElement.InnerText = '1000'
$root.AppendChild($wmiRetryIntervalElement)

$CorePluginConfigurationContext.AppendChild($root)

$CorePluginConfiguration = Invoke-SwisVerb $swis Orion.Discovery CreateCorePluginConfiguration @($CorePluginConfigurationContext.OuterXml)

# Construct the InterfacesPluginConfigurationContext using New-Object to create XML elements
$InterfacesPluginConfigurationContext = New-Object System.Xml.XmlDocument
$rootInterfaces = $InterfacesPluginConfigurationContext.CreateElement('InterfacesDiscoveryPluginContext')
$rootInterfaces.SetAttribute('xmlns', 'http://schemas.solarwinds.com/2008/Interfaces')
$rootInterfaces.SetAttribute('xmlns:a', 'http://schemas.microsoft.com/2003/10/Serialization/Arrays')

$autoImportStatusElement = $InterfacesPluginConfigurationContext.CreateElement('AutoImportStatus')
$autoImportStatusElement.InnerXml = "<a:string>Up</a:string><a:string>Down</a:string><a:string>Shutdown</a:string>"
$rootInterfaces.AppendChild($autoImportStatusElement)

$autoImportVirtualTypesElement = $InterfacesPluginConfigurationContext.CreateElement('AutoImportVirtualTypes')
$autoImportVirtualTypesElement.InnerXml = "<a:string>Virtual</a:string><a:string>Physical</a:string>"
$rootInterfaces.AppendChild($autoImportVirtualTypesElement)

$autoImportVlanPortTypesElement = $InterfacesPluginConfigurationContext.CreateElement('AutoImportVlanPortTypes')
$autoImportVlanPortTypesElement.InnerXml = "<a:string>Trunk</a:string><a:string>Access</a:string><a:string>Unknown</a:string>"
$rootInterfaces.AppendChild($autoImportVlanPortTypesElement)

$useDefaultsElement = $InterfacesPluginConfigurationContext.CreateElement('UseDefaults')
$useDefaultsElement.InnerText = 'true'
$rootInterfaces.AppendChild($useDefaultsElement)

$InterfacesPluginConfigurationContext.AppendChild($rootInterfaces)

$InterfacesPluginConfiguration = Invoke-SwisVerb $swis Orion.NPM.Interfaces CreateInterfacesPluginConfiguration @($InterfacesPluginConfigurationContext.OuterXml)

# Construct the StartDiscoveryContext using New-Object to create XML elements
$StartDiscoveryContext = New-Object System.Xml.XmlDocument
$rootDiscovery = $StartDiscoveryContext.CreateElement('StartDiscoveryContext')
$rootDiscovery.SetAttribute('xmlns', 'http://schemas.solarwinds.com/2012/Orion/Core')
$rootDiscovery.SetAttribute('xmlns:i', 'http://www.w3.org/2001/XMLSchema-instance')

$nameElement = $StartDiscoveryContext.CreateElement('Name')
$nameElement.InnerText = "$discoveryName $([DateTime]::Now)"
$rootDiscovery.AppendChild($nameElement)

$engineIdElement = $StartDiscoveryContext.CreateElement('EngineId')
$engineIdElement.InnerText = "$EngineID"
$rootDiscovery.AppendChild($engineIdElement)

$jobTimeoutSecondsElement = $StartDiscoveryContext.CreateElement('JobTimeoutSeconds')
$jobTimeoutSecondsElement.InnerText = '3600'
$rootDiscovery.AppendChild($jobTimeoutSecondsElement)

$searchTimeoutElement = $StartDiscoveryContext.CreateElement('SearchTimeoutMiliseconds')
$searchTimeoutElement.InnerText = '2000'
$rootDiscovery.AppendChild($searchTimeoutElement)

$snmpTimeoutElement = $StartDiscoveryContext.CreateElement('SnmpTimeoutMiliseconds')
$snmpTimeoutElement.InnerText = '2000'
$rootDiscovery.AppendChild($snmpTimeoutElement)

$snmpRetriesElement = $StartDiscoveryContext.CreateElement('SnmpRetries')
$snmpRetriesElement.InnerText = '1'
$rootDiscovery.AppendChild($snmpRetriesElement)

$repeatIntervalElement = $StartDiscoveryContext.CreateElement('RepeatIntervalMiliseconds')
$repeatIntervalElement.InnerText = '1500'
$rootDiscovery.AppendChild($repeatIntervalElement)

$snmpPortElement = $StartDiscoveryContext.CreateElement('SnmpPort')
$snmpPortElement.InnerText = '161'
$rootDiscovery.AppendChild($snmpPortElement)

$hopCountElement = $StartDiscoveryContext.CreateElement('HopCount')
$hopCountElement.InnerText = '0'
$rootDiscovery.AppendChild($hopCountElement)

$preferredSnmpVersionElement = $StartDiscoveryContext.CreateElement('PreferredSnmpVersion')
$preferredSnmpVersionElement.InnerText = 'SNMPv3'
$rootDiscovery.AppendChild($preferredSnmpVersionElement)

$disableIcmpElement = $StartDiscoveryContext.CreateElement('DisableIcmp')
$disableIcmpElement.InnerText = 'false'
$rootDiscovery.AppendChild($disableIcmpElement)

$allowDuplicateNodesElement = $StartDiscoveryContext.CreateElement('AllowDuplicateNodes')
$allowDuplicateNodesElement.InnerText = 'false'
$rootDiscovery.AppendChild($allowDuplicateNodesElement)

$isAutoImportElement = $StartDiscoveryContext.CreateElement('IsAutoImport')
$isAutoImportElement.InnerText = 'true'
$rootDiscovery.AppendChild($isAutoImportElement)

$isHiddenElement = $StartDiscoveryContext.CreateElement('IsHidden')
$isHiddenElement.InnerText = "$DeleteProfileAfterDiscoveryCompletes"
$rootDiscovery.AppendChild($isHiddenElement)

$pluginConfigurationsElement = $StartDiscoveryContext.CreateElement('PluginConfigurations')
$pluginConfigurationItemElement = $StartDiscoveryContext.CreateElement('PluginConfigurationItem')
$pluginConfigurationItemElement.InnerXml = "$CorePluginConfiguration"
$pluginConfigurationsElement.AppendChild($pluginConfigurationItemElement)

$pluginConfigurationItemElement2 = $StartDiscoveryContext.CreateElement('PluginConfigurationItem')
$pluginConfigurationItemElement2.InnerXml = "$InterfacesPluginConfiguration"
$pluginConfigurationsElement.AppendChild($pluginConfigurationItemElement2)

$rootDiscovery.AppendChild($pluginConfigurationsElement)

$StartDiscoveryContext.AppendChild($rootDiscovery)

$DiscoveryProfileID = (Invoke-SwisVerb $swis Orion.Discovery StartDiscovery @($StartDiscoveryContext.OuterXml)).InnerText

Write-Host "Discovery started. Profile ID: $DiscoveryProfileID"

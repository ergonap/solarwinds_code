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

# Import addresses from CSV file
$pathtocsv = "D:\Scripts\Discovery\SampleImport.csv"
$importedData = Import-Csv -Path $pathtocsv -Header Column1, Column2, Column3, Column4, Column5

# Prepare XML elements for subnets
$subnetsElement = New-Object System.Xml.XmlDocument
$subnetsXml = $subnetsElement.CreateElement("Subnets")

foreach ($row in $importedData) {
    $cidrParts = $row.Column5.Split('/')
    $subnetIP = $cidrParts[0]
    $cidr = [int]$cidrParts[1]
    $subnetMask = Convert-CidrToSubnetMask -cidr $cidr

    $subnet = $subnetsElement.CreateElement("Subnet")
    $subnetIPElement = $subnetsElement.CreateElement("SubnetIP")
    $subnetIPElement.InnerText = $subnetIP
    $subnetMaskElement = $subnetsElement.CreateElement("SubnetMask")
    $subnetMaskElement.InnerText = $subnetMask

    $subnet.AppendChild($subnetIPElement)
    $subnet.AppendChild($subnetMaskElement)
    $subnetsXml.AppendChild($subnet)
}

# Prepare XML elements for credentials
$credentialsElement = New-Object System.Xml.XmlDocument
$credentialsXml = $credentialsElement.CreateElement("Credentials")

$order = 0
foreach ($row in $creds) {
    $order++
    $sharedCredentialInfo = $credentialsElement.CreateElement("SharedCredentialInfo")
    $credentialID = $credentialsElement.CreateElement("CredentialID")
    $credentialID.InnerText = $row.id
    $orderElement = $credentialsElement.CreateElement("Order")
    $orderElement.InnerText = $order

    $sharedCredentialInfo.AppendChild($credentialID)
    $sharedCredentialInfo.AppendChild($orderElement)
    $credentialsXml.AppendChild($sharedCredentialInfo)
}

# Build CorePluginConfigurationContext
$CorePluginConfigurationContext = New-Object System.Xml.XmlDocument
$coreRoot = $CorePluginConfigurationContext.CreateElement("CorePluginConfigurationContext")
$coreRoot.SetAttribute("xmlns", "http://schemas.solarwinds.com/2012/Orion/Core")
$coreRoot.SetAttribute("xmlns:i", "http://www.w3.org/2001/XMLSchema-instance")

$bulkList = $CorePluginConfigurationContext.CreateElement("BulkList")
$coreRoot.AppendChild($bulkList)
$coreRoot.AppendChild($subnetsXml)
$coreRoot.AppendChild($credentialsXml)

$wmiRetries = $CorePluginConfigurationContext.CreateElement("WmiRetriesCount")
$wmiRetries.InnerText = "1"
$coreRoot.AppendChild($wmiRetries)

$wmiInterval = $CorePluginConfigurationContext.CreateElement("WmiRetryIntervalMiliseconds")
$wmiInterval.InnerText = "1000"
$coreRoot.AppendChild($wmiInterval)

$CorePluginConfigurationContext.AppendChild($coreRoot)

$CorePluginConfiguration = Invoke-SwisVerb $swis Orion.Discovery CreateCorePluginConfiguration @($CorePluginConfigurationContext.OuterXml)

# Build InterfacesPluginConfigurationContext
$InterfacesPluginConfigurationContext = New-Object System.Xml.XmlDocument
$interfacesRoot = $InterfacesPluginConfigurationContext.CreateElement("InterfacesDiscoveryPluginContext")
$interfacesRoot.SetAttribute("xmlns", "http://schemas.solarwinds.com/2008/Interfaces")
$interfacesRoot.SetAttribute("xmlns:a", "http://schemas.microsoft.com/2003/10/Serialization/Arrays")

$autoImportStatus = $InterfacesPluginConfigurationContext.CreateElement("AutoImportStatus")
$up = $InterfacesPluginConfigurationContext.CreateElement("a:string", "http://schemas.microsoft.com/2003/10/Serialization/Arrays")
$up.InnerText = "Up"
$down = $InterfacesPluginConfigurationContext.CreateElement("a:string", "http://schemas.microsoft.com/2003/10/Serialization/Arrays")
$down.InnerText = "Down"
$shutdown = $InterfacesPluginConfigurationContext.CreateElement("a:string", "http://schemas.microsoft.com/2003/10/Serialization/Arrays")
$shutdown.InnerText = "Shutdown"
$autoImportStatus.AppendChild($up)
$autoImportStatus.AppendChild($down)
$autoImportStatus.AppendChild($shutdown)

$interfacesRoot.AppendChild($autoImportStatus)
$InterfacesPluginConfigurationContext.AppendChild($interfacesRoot)

$InterfacesPluginConfiguration = Invoke-SwisVerb $swis Orion.NPM.Interfaces CreateInterfacesPluginConfiguration @($InterfacesPluginConfigurationContext.OuterXml)

# Build StartDiscoveryContext
$StartDiscoveryContext = New-Object System.Xml.XmlDocument
$startDiscoveryRoot = $StartDiscoveryContext.CreateElement("StartDiscoveryContext")
$startDiscoveryRoot.SetAttribute("xmlns", "http://schemas.solarwinds.com/2012/Orion/Core")
$startDiscoveryRoot.SetAttribute("xmlns:i", "http://www.w3.org/2001/XMLSchema-instance")

$nameElement = $StartDiscoveryContext.CreateElement("Name")
$nameElement.InnerText = "$discoveryName $([DateTime]::Now)"
$startDiscoveryRoot.AppendChild($nameElement)

$engineIdElement = $StartDiscoveryContext.CreateElement("EngineId")
$engineIdElement.InnerText = "$EngineID"
$startDiscoveryRoot.AppendChild($engineIdElement)

$timeoutElement = $StartDiscoveryContext.CreateElement("JobTimeoutSeconds")
$timeoutElement.InnerText = "3600"
$startDiscoveryRoot.AppendChild($timeoutElement)

$pluginConfigurations = $StartDiscoveryContext.CreateElement("PluginConfigurations")
$pluginConfiguration = $StartDiscoveryContext.CreateElement("PluginConfiguration")
$pluginConfigurationItem1 = $StartDiscoveryContext.CreateElement("PluginConfigurationItem")
$pluginConfigurationItem1.InnerXml = $CorePluginConfiguration.OuterXml
$pluginConfiguration.AppendChild($pluginConfigurationItem1)

$pluginConfigurationItem2 = $StartDiscoveryContext.CreateElement("PluginConfigurationItem")
$pluginConfigurationItem2.InnerXml = $InterfacesPluginConfiguration.OuterXml
$pluginConfiguration.AppendChild($pluginConfigurationItem2)

$pluginConfigurations.AppendChild($pluginConfiguration)
$startDiscoveryRoot.AppendChild($pluginConfigurations)
$StartDiscoveryContext.AppendChild($startDiscoveryRoot)

$DiscoveryProfileID = (Invoke-SwisVerb $swis Orion.Discovery StartDiscovery @($StartDiscoveryContext.OuterXml)).InnerText

Write-Host "Discovery started. Profile ID: $DiscoveryProfileID"

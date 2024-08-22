<#------------- FUNCTIONS -------------#>
Function Convert-CidrToSubnetMask {
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

<#------------- ACTUAL SCRIPT -------------#>
clear-host

$now = Get-Date -Format "yyyyMMdd_HHmm"
$script = $MyInvocation.MyCommand
if($script.path){ $dir = Split-Path $script.path }
else { $dir = [Environment]::GetFolderPath("Desktop") }
$Logfile = "$dir\$($script.name)_$now.log"

Start-Transcript -Path $Logfile -Append -IncludeInvocationHeader

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

# Prompt for the server and connection type
while(!$swistest) {
    $hostname = Read-Host -Prompt "What server should we connect to?" 
    $connectionType = Read-Host -Prompt "Should we use the current powershell credentials [Trusted], or specify credentials [Explicit]?" 
    $swis = Set-SwisConnection $hostname $connectionType
    $swistest = get-swisdata $swis "SELECT TOP 1 servername FROM Orion.Websites"
}
$swistest = $null

"Connected to $hostname Successfully using $connectionType credentials"

# Import addresses from csv files
$pathtocsv = "C:\Scripts\Discovery\SampleImport.csv"

# Filter subnets
$subnets = Get-Content $pathtocsv | Select-String '^[\s|\S]+[/]+\d+' | ConvertFrom-Csv -Header subnets

$discoveryName = 'Scripted Discovery'
$autoImport = 'true'
$query = @"
SELECT id
FROM Orion.Credential
where credentialowner='Orion' and credentialtype = 'SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV3'
"@
$creds = Get-SwisData $swis $query

# Might need to change this for your environment
$EngineID = 1
$DeleteProfileAfterDiscoveryCompletes = "false"

# build the raw XML first
$header = "<CorePluginConfigurationContext xmlns='http://schemas.solarwinds.com/2012/Orion/Core' xmlns:i='http://www.w3.org/2001/XMLSchema-instance'>"
$subnetlist = "<Subnets>"

foreach ($subnet in $subnets.subnets) {
    
    $address = ($subnet -split '/')[0]
    $cidr = ($subnet -split '/')[1]
    $mask = Convert-CidrToSubnetMask $cidr
    $subnetlist += "<AddressSubnet><SubnetIP>$($address)</SubnetIP><SubnetMask>$mask</SubnetMask></AddressSubnet>"
}
$subnetlist += "</Subnets>"

$order = 0
$credentials = "<Credentials>"
foreach ($row in $creds) {
    $order ++
    $credentials += "<SharedCredentialInfo><CredentialID>$($row)</CredentialID><Order>$order</Order></SharedCredentialInfo>"
}
$credentials += "</Credentials>"

$footer = @"
<WmiRetriesCount>1</WmiRetriesCount>
<WmiRetryIntervalMiliseconds>1000</WmiRetryIntervalMiliseconds>
</CorePluginConfigurationContext>
"@

$CorePluginConfigurationContext = ([xml]($header + $subnetlist + $credentials + $footer)).DocumentElement
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
#        <a:string>Virtual</a:string>
        <a:string>Physical</a:string>
    </AutoImportVirtualTypes>
    <AutoImportVlanPortTypes>
        <a:string>Trunk</a:string>
        <a:string>Access</a:string>
 #       <a:string>Unknown</a:string>
    </AutoImportVlanPortTypes>
    <UseDefaults>true</UseDefaults>
</InterfacesDiscoveryPluginContext>
").DocumentElement

$InterfacesPluginConfiguration = Invoke-SwisVerb $swis Orion.NPM.Interfaces CreateInterfacesPluginConfiguration @($InterfacesPluginConfigurationContext)

$StartDiscoveryContext = ([xml]"
<StartDiscoveryContext xmlns='http://schemas.solarwinds.com/2012/Orion/Core' xmlns:i='http://www.w3.org/2001/XMLSchema-instance'>
    <Name>$discoveryName $([DateTime]::Now)</Name>
    <EngineId>$EngineID</EngineId>
    <JobTimeoutSeconds>5400</JobTimeoutSeconds>
    <SearchTimeoutMiliseconds>2000</SearchTimeoutMiliseconds>
    <SnmpTimeoutMiliseconds>2000</SnmpTimeoutMiliseconds>
    <SnmpRetries>1</SnmpRetries>
    <RepeatIntervalMiliseconds>1500</RepeatIntervalMiliseconds>
    <SnmpPort>161</SnmpPort>
    <HopCount>0</HopCount>
    <PreferredSnmpVersion>SNMP2c</PreferredSnmpVersion>
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
").DocumentElement


$DiscoveryProfileID = (Invoke-SwisVerb $swis Orion.Discovery StartDiscovery @($StartDiscoveryContext)).InnerText

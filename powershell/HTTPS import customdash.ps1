# credit to https://thwack.solarwinds.com/content-exchange/the-solarwinds-platform/m/scripts/4267 for the method 
# Adding security settings
#Set-ExecutionPolicy Unrestricted -Force

# Clearing all previous errors (if any)
$error.Clear()

cls

# Safe checking certificate settings
# This is required, if there is a self signed certificate or it is outdated
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback=@"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }
[ServerCertificateValidationCallback]::Ignore();

############
#
# Script Parameters - Start
#

$OrionServer = "localhost"
$OrionPort = "17774"

$url = "https://$($OrionServer):$OrionPort/SolarWinds/InformationService/v3/Json/Invoke/Orion.Dashboards.Instances/Import"

$useSavedCredentials = $false

#
# Option for saving encrypted password to XML
#
# First, encrypt the password using command: 
# GET-CREDENTIAL –Credential $login | EXPORT-CLIXML -path C:\Scripts\credentials.xml
#
# Next, you can import XML using command: 
# $credObject = IMPORT-CLIXML C:\Scripts\credentials.xml
#

[string]$userName = 'testAccount'
[string]$userPassword = '_P@$$w0rD123'
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

#
# Script Parameters - End
#
############

# Clearing up
$dashboard = $null
$dashboardFile = $null
$output = $null
$body = $null
$header = $null

# Checking if script should ask for credentials
if($useSavedCredentials -ne $true) {$credObject = $null; $credObject = GET-CREDENTIAL –Credential YourUserLogin}

# Defining new Browser Form for choosing JSON file
Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    InitialDirectory = "$PSScriptRoot";
    Filter = "JSON|*.json"
    }

# Running the Browser Form
$null = $FileBrowser.ShowDialog()

# Saving JSON location
$dashboardFile = $FileBrowser.FileName

# Importing JSON file
$dashboard = Get-Content -Path $dashboardFile

# Removing unsupported XML part (Dashboard needs to be in pure JSON)
$dashboard = $dashboard.Replace('<Return xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.InformationService.Contract">','')
$dashboard = $dashboard.Replace('</Return>','')

# Preparing body for REST API
$body = [PSCustomObject]@{
    "definition" = "$dashboard"
} | ConvertTo-Json -Compress

# Preparing header for REST API
$header = @{
"Accept"="application/json"
"Content-Type"="application/json"
} 

# Sending request
Write-Host "Importing dashboard file '$dashboardFile' to '$OrionServer'..."
$output = Invoke-WebRequest -Uri $url -UseBasicParsing -Method 'POST' -Credential $credObject -Headers $header -Body $body

# Count number of errors
$errorsCounter = 0
$error | ForEach {$errorsCounter += 1}

# Checking for potential errors
if($errorsCounter -gt 0) {

    Write-Host "------"
    Write-Host "Something went wrong. Please check PowerShell errors."
    Write-Host "------"

}

# Displaying output
Else {
    
    Write-Host "------"
    Write-Host "Note: Status Code 200 and Content as 'null' is correct and it means that REST API finished successfully."
    Write-Host "------"
    Write-Host "HTTPS Status Code:" $output.StatusCode
    Write-Host "HTTPS Status Description:" $output.StatusDescription
    Write-Host "HTTPS Content:" $output.Content
    Write-Host "------"
}

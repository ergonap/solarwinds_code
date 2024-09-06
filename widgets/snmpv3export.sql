--This script was found on thwack. This can be put into a report or a widget and will list ALL SNMP v3 credentials and relevant keys. 
-- hopefully this is never needed, but in the case that it is....
SELECT top 50 N.IPAddress
, N.Caption as Device
, N.SNMPVersion as Version 
, NS.SettingValue as CredsID 
, C.Name as CredsName 
, N.SNMPv3Credentials.UserName
, N.SNMPv3Credentials.PrivacyMethod
, N.SNMPv3Credentials.PrivacyKey
, N.SNMPv3Credentials.AuthenticationMethod
, N.SNMPv3Credentials.AuthenticationKey
, N.SNMPv3Credentials.RWPrivacyMethod
, N.SNMPv3Credentials.RWPrivacyKey
, N.SNMPv3Credentials.RWAuthenticationMethod
, N.SNMPv3Credentials.RWAuthenticationKey 
FROM Orion.Nodes N 
LEFT JOIN Orion.NodeSettings NS on N.NodeID=NS.NodeID and NS.SettingName='ROSNMPCredentialID' 
LEFT JOIN Orion.Credential C on NS.SettingValue=C.ID WHERE (N.SNMPVersion = 3) 

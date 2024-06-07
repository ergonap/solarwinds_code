--I added some simple steps to format OutBps and InBps into MB/GB as an example, modify operational status, and have search for when it's desired

SELECT TOP 1000 ObjectSubType 
, TypeName
, TypeDescription
, Speed/100000000 as [Speed_GB]
, MTU
, CASE 
WHEN AdminStatus = 1 THEN 'no_shut'
WHEN AdminStatus = 2 THEN 'shut'
ELSE 'unknown'
END AS AdminStatus
,LastChange
, PhysicalAddress as [MAC]
, CASE
WHEN OperStatus = 1 THEN 'Up'
When OperStatus = 2 THEN 'Down'
Else 'Error'
END as OperStatus
, FullName
, CASE
WHEN Outbps / 100000 < 1000 THEN CONCAT((Outbps / 100000), ' MB')
WHEN Outbps / 100000 >= 1000 THEN CONCAT((Outbps / 100000000), ' GB')
ELSE NULL
END as Out_packets
, CASE
WHEN Inbps/ 100000 < 1000 THEN CONCAT((Inbps / 100000), ' MB')
WHEN Inbps / 100000 >= 1000 THEN CONCAT((Inbps/ 100000000), ' GB')
ELSE NULL
END as In_packets
, LastSync, IfName, CustomBandwidth, CustomPollerLastStatisticsPoll, PollInterval, NextPoll, RediscoveryInterval, NextRediscovery, StatCollection, UnPluggable, InterfaceSpeed, InterfaceCaption as [Interface], InterfaceType, InterfaceSubType, MAC, InterfaceName, InterfaceTypeName, AdminStatusLED, OperStatusLED, InterfaceAlias, InterfaceIndex, InterfaceLastChange, InterfaceMTU, InterfaceTypeDescription, OrionIdPrefix, OrionIdColumn, SkippedPollingCycles, MinutesSinceLastSync, InterfaceResponding, Description, DetailsUrl as [_linkfor_IF], i.Node.Caption as [Node], i.Node.DetailsUrl as [_linkfor_Node]
--,i.CustomProperties.Alert_Enable
FROM Orion.NPM.Interfaces as i

-- BELOW IS FOR SEARCH, UNCOMMON IF YOU WANT TO SEARCH ON Node/Interface/Admin Status
-- WHERE i.Node.Caption like '%${Search_String}%'
--OR i.Caption like '%${Search_String}%'
--or AdminStatus like '%${Search_String}%'

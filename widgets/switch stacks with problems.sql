SELECT TOP 1000 Displayname
, DataRingRedundant as DataRing_Active
, StatusDescription
, ONS.Nodes.IP_Address
, DataRingSatsuDescription as DataRing_Status
, PowerRingStatusDescription as PowerRing_Status
, RingFailure
, Membercount as Switch_Count
, ONS.Nodes.DetailsURL as _linkFor_DisplayName
FROM Orion.NPM.Switchstack ONS
WHERE DataRingRedundant = 'False' OR PowerRingStatusDescription != 'Up'
ORDER BY RingFailure, PowerRingStatusDescription DESC

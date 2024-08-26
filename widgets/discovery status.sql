SELECT e.Servername as "PollingEngine"
, Frequency
, LastRun
, STatus
, NotImportedNodescount as NewNodes
, IsAutoImport
, ChangeNodescount
, RunTimeInSeconds
FROM Orion.DiscoveryProfiles ODP
INNER JOIN Orion.Engines e on ODP.EngineID = e.EngineID

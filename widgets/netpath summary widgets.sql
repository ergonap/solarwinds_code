-- this will link to EVERY individual netpath, if there are 2 probes for one path each is listed individually and sorted by PROBE NAME for this purpose
SELECT [SA].ProbeName AS [Source]
     , [SA].ServiceName AS [Destination]
     , [SA].DetailsUrl AS [_LinkFor_Source]
     , CONCAT('/Orion/images/StatusIcons/Small-', [SI].IconPostfix, '.gif') AS [_IconFor_Source] -- This is the status for the most recent poll only
     , ROUND([Tests].MinLatency, 2) AS [Min Latency (ms)]
     , ROUND([Tests].AvgLatency, 2) AS [Avg Latency (ms)]
     , ROUND([Tests].MaxLatency, 2) AS [Max Latency (ms)]
     , CONCAT(ROUND([Tests].MinLatency, 2), ' / ', ROUND([Tests].AvgLatency, 2), ' / ', ROUND([Tests].MaxLatency, 2) ) AS [Min/Avg/Max Latency (ms)]
     , ROUND([Tests].MinPacketLoss, 2) AS [Min Packet Loss (%)]
     , ROUND([Tests].AvgPacketLoss, 2) AS [Avg Packet Loss (%)]
     , ROUND([Tests].MaxPacketLoss, 2) AS [Max Packet Loss (%)]
     , CONCAT(ROUND([Tests].MinPacketLoss, 2), ' / ', ROUND([Tests].AvgPacketLoss, 2), ' / ', ROUND([Tests].MaxPacketLoss, 2) ) AS [Min/Avg/Max Packet Loss (%)]
FROM Orion.NetPath.ServiceAssignments AS [SA]
INNER JOIN Orion.StatusInfo AS [SI]
   ON [SA].Status = [SI].StatusID
INNER JOIN (
    SELECT EndpointServiceID
         , ProbeID
         , MIN(Rtt) AS MinLatency
         , AVG(Rtt) AS AvgLatency
         , MAX(Rtt) AS MaxLatency
         , MIN(PacketLoss) AS MinPacketLoss
         , AVG(PacketLoss) AS AvgPacketLoss
         , MAX(PacketLoss) AS MaxPacketLoss
    FROM Orion.NetPath.Tests
    WHERE ExecutedAt >= GETUTCDATE() - 1 -- ExecutedAt is stored in UTC, so we use 'GETUTCDATE() - 1' to get last 24 hours only
    GROUP BY EndpointServiceID, ProbeID
) AS [Tests]
ON  [Tests].ProbeID = [SA].ProbeID
AND [Tests].EndpointServiceID = [SA].EndpointServiceID
WHERE --[SA].ServiceName = 'Office 365' -- This is the NetPath Service Name as displayed on your NetPath summary page
[SA].Enabled = 'True'
ORDER BY [SA].ProbeName

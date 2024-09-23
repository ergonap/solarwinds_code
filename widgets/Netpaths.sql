SELECT DATETRUNC('MINUTE', ont.ExecutedAt) as finishtime
  , ons.ServiceName as Path
  , ons.ProbeName as Node
  , ROUND(ont.LostPackets*1.0/ont.SentPackets,2)*100 as PL_ratio 
  , ont.Packetloss
  , ons.DetailsUrl as _linkFor_Path
FROM Orion.Netpath.Tests ont
INNER JOIN Orion.Netpath.ServiceAsssignments ons ON ont.EndpointServiceID = ons.EndpointServiceID

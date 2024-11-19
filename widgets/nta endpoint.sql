--This will grab whenever NTA traffic for a specific hostname is found and alert, so long as it was in the last ~15 minutes or so. This can immediately be converted into an alert if you just grab anything from the WHERE field, but can otherwise be used as a dashbaord widget
SELECT TOP 10 Caption
, Nodes.FlowsByHostname.DestinationHostname
, Nodes.FlowsByHostname.TimeStamp
FROM Orion.Nodes as Nodes
WHERE Nodes.FlowsByHostname.DestinationHostname LIKE '%HOSTNAME%'  --change HOSTNAME To whatever you want
AND Nodes.FlowsByHostname.TimeStamp >= AddMinute(-17,DateTrunc('minute', GetUtcDate())) 
AND Nodes.FlowsByHostname.TimeStamp <= AddMinute(-2,DateTrunc('minute', GetUtcDate()))

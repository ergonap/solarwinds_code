-- this is an improvement on solarwinds diagnostics for nosiest traps

--this is the top part of the query
SELECT n.caption
, e.NodeID, COUNT(e.LogEntryID) as total
, n.Vendor, n.MachineType
, n.IP_Address
, n.DetailsUrl as [_Linkfor_caption]
--message will add the MESSAGE itself, this can be noisy
 -- , e.Message
FROM Orion.OLM.LogEntry as e
INNER JOIN Orion.OLM.LogEntryType as t on t.LogEntryTypeID = e.LogEntryTypeID
INNER JOIN Orion.Nodes as n on n.NodeID = e.NodeID
where t.Type = 'Traps'
group by e.NodeID
order by total desc

-- this is the searchable part of the query

SELECT n.caption
, e.NodeID, COUNT(e.LogEntryID) as total
, n.Vendor,
 n.MachineType
, n.IP_Address
, n.DetailsUrl as [_Linkfor_caption]
FROM Orion.OLM.LogEntry as e
INNER JOIN Orion.OLM.LogEntryType as t on t.LogEntryTypeID = e.LogEntryTypeID
INNER JOIN Orion.Nodes as n on n.NodeID = e.NodeID
where t.Type = 'Traps' AND 
(n.caption LIKE '%${SEARCH_STRING}%'  
OR n.MachineType LIKE '%${SEARCH_STRING}%' 
OR n.IP_Address LIKE '%${SEARCH_STRING}%'  
-- optional search by MESSAGE
 -- OR e.Message LIKE '%${SEARCH_STRING}%' 
OR n.Vendor LIKE '%${SEARCH_STRING}%'
 )
group by e.NodeID
order by total desc

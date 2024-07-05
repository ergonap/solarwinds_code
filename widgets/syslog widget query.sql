--this is a modification improvement on the syslog by count per node query

--main query, added linkfor to identify nodes
SELECT n.caption as caption
, e.NodeID, COUNT(e.LogEntryID) as total
, n.Vendor, n.MachineType, n.IP_Address
, n.DetailsUrl as [_Linkfor_caption]
, e.Message
FROM Orion.OLM.LogEntry as e
INNER JOIN Orion.OLM.LogEntryType as t on t.LogEntryTypeID = e.LogEntryTypeID
INNER JOIN Orion.Nodes as n on n.NodeID = e.NodeID

where t.Type = 'Syslog'
group by e.NodeID
order by total desc


-- search query below here to search for anything as identified for filtering
SELECT n.caption as caption
    , e.NodeID, COUNT(e.LogEntryID) as total
    , n.Vendor, n.MachineType, n.IP_Address
    , n.DetailsUrl as [_Linkfor_caption]
FROM Orion.OLM.LogEntry as e
INNER JOIN Orion.OLM.LogEntryType as t on t.LogEntryTypeID = e.LogEntryTypeID
INNER JOIN Orion.Nodes as n on n.NodeID = e.NodeID
WHERE t.Type = 'Syslog' AND
(n.caption LIKE '%${SEARCH_STRING}%'  
OR n.MachineType LIKE '%${SEARCH_STRING}%' 
OR e.Message LIKE '%${SEARCH_STRING}%'
OR n.IP_Address LIKE '%${SEARCH_STRING}%'  
OR n.Vendor LIKE '%${SEARCH_STRING}%'  )
GROUP BY e.NodeID, n.caption, n.Vendor, n.MachineType, n.IP_Address, n.DetailsUrl

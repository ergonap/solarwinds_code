-- This is a modification of MESVERRUM's Custom Property to add a Department Custom property. I specifically commented out the changes, as they are small. 
SELECT DISTINCT 
    ac.Name AS [Alert Name],
    '/Orion/NetPerfMon/ActiveAlertDetails.aspx?NetObject=AAT:' + ToString(ao.AlertObjectID) AS [_linkfor_Alert Name],  
    COUNT(ah.message) AS [Alert Count 30 days], 
    today.[Alert count] AS [Alert Count 24 hours], 
    CASE 
        WHEN EntityCaption = RelatedNodeCaption THEN entitycaption
        ELSE CONCAT(RelatedNodeCaption, ' - ', entitycaption)
    END AS [Trigger Object], 
    EntityDetailsUrl AS [_linkfor_Trigger Object], 
    tolocal(MAX(ah.TimeStamp)) AS [Most Recent Trigger],
    cp.Department AS [Department] -- Added Department CP 
FROM 
    Orion.AlertHistory ah 
JOIN 
    Orion.AlertObjects ao ON ao.alertobjectid = ah.alertobjectid 
JOIN 
    Orion.AlertConfigurations ac ON ac.alertid = ao.alertid 
JOIN
    Orion.Nodes n ON n.NodeID = ao.RelatedNodeID -- Joining with Nodes 
LEFT JOIN 
    Orion.NodesCustomProperties cp ON cp.NodeID = n.NodeID -- Join with NodesCustomProperties 
LEFT JOIN 
    (SELECT DISTINCT 
         ac.Name AS AlertName,
         '/Orion/NetPerfMon/ActiveAlertDetails.aspx?NetObject=AAT:' + ToString(ao.AlertObjectID) AS [_linkfor_Name],  
         COUNT(ah.message) AS [Alert Count], 
         EntityCaption AS [Trigger Object], 
         EntityDetailsUrl AS [_linkfor_Trigger Object], 
         RelatedNodeCaption AS [Parent Node], 
         RelatedNodeDetailsUrl AS [_linkfor_Parent Node], 
         tolocal(MAX(ah.TimeStamp)) AS [Most Recent Trigger]
     FROM 
         Orion.AlertHistory ah 
     JOIN 
         Orion.AlertObjects ao ON ao.alertobjectid = ah.alertobjectid 
     JOIN 
         Orion.AlertConfigurations ac ON ac.alertid = ao.alertid 
     WHERE  
         hourdiff(ah.timestamp, GETUTCDATE()) < 24 
         AND ah.timestamp < getutcdate() 
         AND ah.eventType = 0
     GROUP BY 
         name, [Trigger Object], [Parent Node]) today ON today.[_linkfor_Name] = '/Orion/NetPerfMon/ActiveAlertDetails.aspx?NetObject=AAT:' + ToString(ao.AlertObjectID) 
WHERE  
    daydiff(ah.timestamp, GETUTCDATE()) < 30 
    AND ah.timestamp < getutcdate() 
    AND ah.eventType = 0
GROUP BY 
    name, [Trigger Object], [Parent Node], cp.Department -- add Department
ORDER BY 
    [Alert Count 30 days] DESC

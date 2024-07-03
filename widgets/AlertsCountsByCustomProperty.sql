--this mostly is an improvement on Mesverrum's query to incorporate a custom property in the ALERT to make this much easier to sort out. This will specifically query an ALERT's CUSTOM PROPERTY. Not a Node's. 
SELECT DISTINCT 
    ac.Name AS [Alert Name],
    '/Orion/NetPerfMon/ActiveAlertDetails.aspx?NetObject=AAT:' + ToString(AlertObjectID) AS [_linkfor_Alert Name],  
    --,ah.Message 
    COUNT(ah.message) AS [Alert Count 30 days], 
    today.[Alert count] AS [Alert Count 24 hours], 
    CASE 
        WHEN EntityCaption = RelatedNodeCaption THEN entitycaption
        ELSE CONCAT(RelatedNodeCaption, ' - ', entitycaption)
    END AS [Trigger Object], 
    EntityDetailsUrl AS [_linkfor_Trigger Object], 
    tolocal(MAX(ah.TimeStamp)) AS [Most Recent Trigger],
    ac.CustomProperties.ResponsibleTeam -- Accessing ResponsibleTeam directly from AlertConfigurations
FROM 
    Orion.AlertHistory ah 
JOIN 
    Orion.AlertObjects ao ON ao.alertobjectid = ah.alertobjectid 
JOIN 
    Orion.AlertConfigurations ac ON ac.alertid = ao.alertid 
LEFT JOIN 
    (SELECT DISTINCT 
         ac.Name AS AlertName,
         '/Orion/NetPerfMon/ActiveAlertDetails.aspx?NetObject=AAT:' + ToString(AlertObjectID) AS [_linkfor_Name],  
         --,ah.Message 
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
         name, [Trigger Object], [Parent Node]) today ON today.[_linkfor_Name] = '/Orion/NetPerfMon/ActiveAlertDetails.aspx?NetObject=AAT:' + ToString(AlertObjectID) 
WHERE  
    daydiff(ah.timestamp, GETUTCDATE()) < 30 
    AND ah.timestamp < getutcdate() 
    AND ah.eventType = 0
GROUP BY 
    name, [Trigger Object], [Parent Node], ac.CustomProperties.ResponsibleTeam -- Adding ResponsibleTeam to the group by clause
ORDER BY 
    [Alert Count 30 days] DESC

SELECT TriggeredDateTime
,OAA.AlertObjects.Node.Caption as [Node] --find nodes
,OAA.AlertObjects.Node.CPULoad --change this to any relevant node metric
,OAA.AlertObjects.Node.DetailsUrl as [_LinkFor_Node] --add hover information and link
,'Link to Alert' as [Link]
,'https://YOURSERVERNAME/Orion/View.aspx?NetObject=AAT:' + TOSTRING(OAA.AlertObjects.AlertObjectID) AS [_LinkFor_Link] 
--point above to YOUR SERVER NAME OR IP
FROM Orion.AlertActive OAA 
WHERE TriggeredMessage LIKE 'High CPU Utilization with Top 10 Processes' --ALERT DESCRIPTION

--so this custom query will let you list nodes and an applicable filtered alert. This way you can get node status + node alert status
--all in one go

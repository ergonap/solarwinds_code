-- from https://thwack.solarwinds.com/content-exchange/the-orion-platform/m/custom-queries/4172 

-- Application List TOP 30
-- Search by Nodename, IP, Application Name
SELECT TOP 50 
 
TOUPPER(SUBSTRING (a.Node.Caption,1, CASE WHEN CHARINDEX('.',a.Node.Caption,1) <=4 THEN LENGTH(a.Node.Caption) ELSE (CHARINDEX('.',a.Node.Caption,1)-1)  END)) AS [Node Name] 
,a.Node.DetailsUrl AS [_LinkFor_Node Name]
,'/Orion/images/StatusIcons/Small-' + a.Node.StatusIcon AS [_IconFor_Node Name]

,a.Node.IP_Address as IP_Address
,a.Node.DetailsUrl AS [_LinkFor_IP_Address]
,'/NetPerfMon/Images/Vendors/' + a.Node.VendorIcon as [_IconFor_IP_Address]

,a.Name AS [Application Name]
,a.DetailsUrl AS [_LinkFor_Application Name]
,'/Orion/images/StatusIcons/Small-' + a.StatusDescription + '.gif' AS [_IconFor_Application Name]

,a.Template.Name AS [Template Name]
, '/Orion/images/nodemgmt_art/icons/icon_edit.gif' AS [_IconFor_Template Name] 
, CONCAT('/Orion/APM/Admin/Edit/EditTemplate.aspx?id=', TOSTRING(a.ApplicationTemplateID)) AS [_LinkFor_Template Name]

,'Edit' AS [Application]
, '/Orion/images/nodemgmt_art/icons/icon_edit.gif' AS [_IconFor_Application] 
, CONCAT('/Orion/APM/Admin/Edit/EditApplication.aspx?id=', TOSTRING(a.ApplicationID)) AS [_LinkFor_Application]

,'Edit' As [Node]
, '/Orion/images/nodemgmt_art/icons/icon_edit.gif' AS [_IconFor_Node] 
, CONCAT('/Orion/Nodes/NodeProperties.aspx?Nodes=', TOSTRING(a.Node.NodeID)) AS [_LinkFor_Node]

FROM Orion.APM.Application As a
-- Remove Comment lines below and paste into search section of custom query.
--WHERE a.Node.Caption LIKE '%${SEARCH_STRING}%'
--OR a.Node.IP_Address LIKE  '%${SEARCH_STRING}%'
--OR a.DisplayName     LIKE  '%${SEARCH_STRING}%'

ORDER BY a.Node.Caption,a.Name

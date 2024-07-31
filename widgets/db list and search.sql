SELECT OAS.Node.Caption as [Node] -- node name  
, OAS.Node.DetailsUrl as [_LinkFor_Node] -- mouse hover for node  
, OAS.Databases.DisplayName as [DB] -- DB name  
,OAS.Databases.DetailsUrl as [_LinkFor_DB] -- mouse hover for DB info  
, DisplayName as [Application] --application name  
, DetailsURL as [_LinkFor_Application] --mouse hover for application name  
FROM Orion.APM.SqlServerApplication OAS   
-- OAS (Orion.APM.SqlServerApplication) created to link   
Order By Node Asc  


SELECT OAS.Node.Caption as [Node]  
, OAS.Node.DetailsUrl as [_LinkFor_Node]  
, OAS.Databases.DisplayName as [DB]  
,OAS.Databases.DetailsUrl as [_LinkFor_DB]  
, DisplayName as [Application]  
, DetailsURL as [_LinkFor_Application]  
-- anything that matches a WHERE as  '${SEARCH_STRING}'  will filter  
FROM Orion.APM.SqlServerApplication OAS  
WHERE (DisplayName Like  '${SEARCH_STRING}'   
OR OAS.Node.Caption Like  '${SEARCH_STRING}'  
OR OAS.Databases.DisplayName Like  '${SEARCH_STRING}')  
Order By Displayname Asc  

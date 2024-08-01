--I find 1000 is usually good unless someone has an exceptionally large number of sites within appinsight for IIS
SELECT TOP 1000 Name
,  ServerAutoStart
, PhysicalPath
,   DetailsUrl as _linkFor_Name
, AverageResponseTime
, CurrentHttpBindingsUrls
, CurrentHttpsBindingsUrls
FROM Orion.APM.IIS.Site


--search version below 
SELECT TOP 1000 Name
,  ServerAutoStart
, PhysicalPath
,   DetailsUrl as _linkFor_Name
, AverageResponseTime
, CurrentHttpBindingsUrls
, CurrentHttpsBindingsUrls
FROM Orion.APM.IIS.Site
WHERE Name like '%${SEARCH_STRING}%' OR CurrentHttpsBindingsUrls like '%${SEARCH_STRING}%' or CurrentHttpBindingsUrls LIKE '%${SEARCH_STRING}%'

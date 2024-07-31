
SELECT FullName AS [Node]  
,'/Orion/images/StatusIcons/Small-' + StatusIcon AS [_IconFor_Node] --this gives nodes a status icon  
,v.Node.DetailsURL as [_LinkFor_Node] --this lets us show node information on hover from [Node]  
,ROUND(VolumeSize/1073741824,2) as Vol_GB --volume storage deals in 1024, this divides by GB  
,ROUND(VolumeSpaceAvailable/1073741824,2)  AS GB_Free  
,Caption AS [Volume] --this shows caption and the detailsURL info  
,DetailsURL as [_LinkFor_Volume] --this lets us show volume information on hover from [Volume]  
,v.Node.IP  
,ROUND(VolumePercentAvailable,2) as Avail_Percent  
,ROUND(VolumePercentUsed,2) as [UsedPercent]  
,CASE  
     WHEN v.VolumePercentUsed > v.ForecastCapacity.CriticalThreshold THEN '/Orion/images/StatusIcons/Small-Critical.gif'  
    WHEN v.VolumePercentUsed > v.ForecastCapacity.WarningThreshold THEN '/Orion/images/StatusIcons/Small-Warning.gif'  
    ELSE '/Orion/images/StatusIcons/Small-Up.gif'  
    END AS [_IconFor_UsedPercent]  
--incorporate some volume forecasting  
,ROUND(VolumeSpaceUsed/1073741824,2) as GB_Used  
--uncomment the following line below via removing the -- to then customize and add a custom property of your choosing  
--,v.Node.CustomProperties.Device_Class as Application  
FROM Orion.Volumes as V  
Where Caption LIKE '%\%' AND (VolumePercentUsed > 80 AND VolumeSpaceAvailable < 5368709120)  
ORDER BY VolumePercentUsed ASC  

Search query:

SELECT FullName AS [Node]  
,'/Orion/images/StatusIcons/Small-' + StatusIcon AS [_IconFor_Node]  
,v.Node.DetailsURL as [_LinkFor_Node]  
,ROUND(VolumeSize/1073741824,2) as Vol_GB  
,ROUND(VolumeSpaceAvailable/1073741824,2)  AS GB_Free  
,Caption AS [Volume]  
,DetailsURL as [_LinkFor_Volume]  
,v.Node.IP  
,ROUND(VolumePercentAvailable,2) as Avail_Percent  
,ROUND(VolumePercentUsed,2) as [UsedPercent]  
,CASE  
     WHEN v.VolumePercentUsed > v.ForecastCapacity.CriticalThreshold THEN '/Orion/images/StatusIcons/Small-Critical.gif'  
    WHEN v.VolumePercentUsed > v.ForecastCapacity.WarningThreshold THEN '/Orion/images/StatusIcons/Small-Warning.gif'  
    ELSE '/Orion/images/StatusIcons/Small-Up.gif'  
    END AS [_IconFor_UsedPercent]  
,ROUND(VolumeSpaceUsed/1073741824,2) as GB_Used  
,v.Node.CustomProperties.Device_Class as Application  
FROM Orion.Volumes as V  
-- the first WHERE adds the search query below  
WHERE (Caption LIKE '%${SEARCH_STRING}%' OR v.Node.Caption LIKE '%${SEARCH_STRING}%') AND (Caption LIKE '%\%' AND (VolumePercentUsed > 80 AND VolumeSpaceAvailable < 5368709120))  
--replace above version with below version if you have a custom property you want to filter, you can change Device_Class to be any custom property you want to search  
--WHERE (Caption LIKE '%${SEARCH_STRING}%' OR v.Node.Caption LIKE '%${SEARCH_STRING}%' OR v.Node.CustomProperties.Device_Class LIKE '%${SEARCH_STRING}%') AND (Caption LIKE '%\%' AND (VolumePercentUsed > 80 AND VolumeSpaceAvailable < 5368709120))  
ORDER BY VolumePercentUsed ASC  
 

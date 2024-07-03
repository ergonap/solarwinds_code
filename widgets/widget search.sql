select case when v.ViewGroupName is not null then (v.ViewGroupName+' - '+v.ViewTitle) else v.viewtitle end as View, v.ViewID 
, r.ResourceID, r.ResourceName, r.ResourceTitle 
, '/Orion/SummaryView.aspx?ViewID='+tostring(v.viewid) as [_linkfor_View] 
, '/Orion/DetachResource.aspx?ViewID='+tostring(v.viewid)+'&ResourceID='+tostring(r.resourceid)+'&NetObject=' as [_linkfor_ResourceTitle] 
from orion.views v 
join orion.Resources r on r.viewid=v.ViewID 
--join orion.ResourceProperties rp on r.ResourceID=rp.ResourceID 
 
-- where r.resourcetitle like '%${SEARCH_STRING}%' 
 
order by v.viewid


--Search version below:--------------------------------------------------

select case when v.ViewGroupName is not null then (v.ViewGroupName+' - '+v.ViewTitle) else v.viewtitle end as View, v.ViewID 
, r.ResourceID, r.ResourceName, r.ResourceTitle 
, '/Orion/SummaryView.aspx?ViewID='+tostring(v.viewid) as [_linkfor_View] 
, '/Orion/DetachResource.aspx?ViewID='+tostring(v.viewid)+'&ResourceID='+tostring(r.resourceid)+'&NetObject=' as [_linkfor_ResourceTitle] 
from orion.views v 
join orion.Resources r on r.viewid=v.ViewID 
join orion.ResourceProperties rp on r.ResourceID=rp.ResourceID 
 
where r.resourcetitle like '%${SEARCH_STRING}%' 
 
order by v.viewid

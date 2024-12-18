--this data is designed to be in dashboards ore reports to handle Aruba switches which tend to have unique ways to identify stacks. It joins the Node Caption from the table and the IP from the Nodes table to help identify stacked devices.
SELECT orn.Caption, EntPhysicalIndex/100000 as StackMember, Position as S2500Position, orn.IPAddress, Serial, EntityName, n.EntityType,  FirmwareRevision, SoftwareRevision, Model, LastDiscovery
FROM NCM.EntityPhysical n
JOIN Orion.Nodes orn ON orn.NodeID = n.Node.CoreNodeID
WHERE EntityDescription LIKE '6300%' OR EntityDescription LIKE '%3810%' OR EntityDescription LIKE '%2500%'
ORDER BY Caption ASC

SELECT o.OrionNode.Caption as Caption
,o.OrionNode.IP_Address
,o.OrionNode.DetailsUrl as [_Linkfor_caption]
,l.Message
FROM 
    Orion.OLM.Nodes o
JOIN 
    Orion.OLM.LogEntry l ON l.NodeID = o.NodeID

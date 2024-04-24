---- GROUPS ----

SELECT [Groups].DisplayName AS [Name]
      , [Groups].DetailsUrl AS [_LinkFor_Name]
      , CONCAT (
            '/Orion/StatusIcon.ashx?entity='
            , [Groups].InstanceType
            , '&status='
            , [Groups].Status
            , '&size=small'
            ) AS [_IconFor_Name]
      , [Groups].Description
      , [GroupDefinitions].DisplayName AS [Dynamic Query]
      , '/Orion/images/Icon.DynamicQuery.gif' AS [_IconFor_Dynamic Query]
      , CONCAT (
            '/Orion/Admin/Containers/EditDynamicQuery.aspx?name='
            , [GroupDefinitions].Name
            , '&def='
            , [GroupDefinitions].Definition
            , '&sid=cm'
            , [Groups].ContainerID
            ) AS [_LinkFor_Dynamic Query]
FROM Orion.Container AS [Groups]
INNER JOIN Orion.ContainerMemberDefinition AS [GroupDefinitions]
      ON [Groups].ContainerID = [GroupDefinitions].ContainerID
            AND [GroupDefinitions].Expression LIKE '%.CustomProperties.%'
WHERE [Groups].Name NOT LIKE 'MAPS-%'
      AND [Groups].IsDeleted = 'FALSE'



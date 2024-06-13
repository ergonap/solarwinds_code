SELECT Name
     , CONCAT( '/Orion/StatusIcon.ashx?entity=Orion.Groups&id=',ContainerId,'&status=',Status,'&size=small' ) AS _IconFor_Name
     , Description
     , DetailsUrl AS _LinkFor_Name
FROM Orion.Container
WHERE Owner = 'Core'
  AND IsDeleted = 'False'
ORDER BY Name

-- SEARCH IS SEPARATE BELOW --  
SELECT Name

     , CONCAT( '/Orion/StatusIcon.ashx?entity=Orion.Groups&id=',ContainerId,'&status=',Status,'&size=small' ) AS _IconFor_Name

     , Description

     , DetailsUrl AS _LinkFor_Name

FROM Orion.Container
WHERE Owner = 'Core'
  AND IsDeleted = 'False'
  AND ( Name LIKE '%${SEARCH_STRING}%'
     OR Description LIKE '%${SEARCH_STRING}%' )
ORDER BY Name

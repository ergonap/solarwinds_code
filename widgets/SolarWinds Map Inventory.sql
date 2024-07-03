--map inventory from https://thwack.solarwinds.com/content-exchange/the-orion-platform/m/custom-queries/4125 
SELECT

[P].AccountID AS [Map Creator]
, [P].DisplayName AS [Map Name]
, '/ui/maps/viewer/' + [P].ProjectID AS [_LinkFor_Map Name]
, [P].EntityCount AS [Entities]
, ToLocal([P].CreateDateTime) AS [Created]
, ToLocal([P].UpdateDateTime) AS [Last Updated]

FROM Orion.Maps.Projects [P]

--WHERE ([P].AccountID LIKE '%${SEARCH_STRING}%' OR [P].DisplayName LIKE '%${SEARCH_STRING}%')

ORDER BY [Last Updated] DESC

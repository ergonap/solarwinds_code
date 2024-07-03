$hostname = 'localhost'

if (!$creds) {
    $creds = Get-Credential  # display a window asking for credentials

}
$swis = Connect-Swis -Credential $creds -Hostname $hostname

# CREATING A NEW GROUP
# Creating a new group with initial Cisco and Windows devices.
#
$group = get-swisdata $swis @"
select distinct n.city
from orion.nodesCustomProperties n
left join orion.Container c on c.name = n.city
where c.name is null and n.city not in ('')
order by n.city
"@
$city = get-swisdata $swis "
select n.city
from Orion.NodesCustomProperties n
Where n.city IS NOT NULL
group by n.city
order by n.city
"
foreach ($city in $group)
    {
            $members = @(
            @{ Name = $city; Definition = "filter:/Orion.Nodes[CustomProperties.City='$city']"}
            )
$groupId = (Invoke-SwisVerb $swis "Orion.Container" "CreateContainer" @(
    # group name
    "$city",
    # owner, must be 'Core'
    "Core",
    # refresh frequency
    60,
    # Status rollup mode:
    # 0 = Mixed status shows warning
    # 1 = Show worst status
    # 2 = Show best status
    0,
    # group description
    "",
    # polling enabled/disabled = true/false (in lowercase)
    "true",
    # group members
    ([xml]@(
       "<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>",
       [string]($members |% {
        "<MemberDefinitionInfo><Name>$($_.Name)</Name><Definition>$($_.Definition)</Definition></MemberDefinitionInfo>"
         }
       ),
       "</ArrayOfMemberDefinitionInfo>"
    )).DocumentElement
  )).InnerText
     }

-- this is a simple example of using case to identify syslogs vs traps, and then filter for BGP syslogs and traps accordingly. 
SELECT TOP 1000 
CASE
when LE.LogEntryTypeID = 2 then 'syslog'
when LE.LogEntryTypeID = 3 then 'trap'
END as Traptype, Message, LogEntryLevelID, NodeID, MessageSourceID, DateTime, MessageDateTime, Level, LevelKey
FROM Orion.OLM.LogEntry LE
WHERE Message like '%bgp%'

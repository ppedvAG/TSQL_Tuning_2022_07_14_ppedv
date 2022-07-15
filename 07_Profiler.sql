--Profiler: Live mitverfolgen was auf der Datenbank passiert
--Tools -> SQL Server Profiler

--> Name: Dateiname
--> Template: Tuning
--> Save to File: .trc File speichern
--> Enable file rollover: File vergr��ern, falls es zu gro� wird
--> Enable trace stop time: 30min Maximaldauer

--> Events: SP:StmtStarting, SP:StmtStopping, SQL:BatchCompleted
--> Column Filters: Database LIKE <Name> (wenn nicht sichtbar, Show all Columns aktivieren)

USE Demo;
SELECT * FROM KundenUmsatz2; -- beide Abfragen sind jetzt im Profiler sichtbar

--Tuning Advisor
--Tools -> Database Engine Tuning Advisor

--braucht ein .trc File (vom Profiler)
--Datenbank f�r Workload ausw�hlen (Demo im Testsystem, tempdb in der Realit�t)
--Datenbank ausw�hlen (bei uns Demo)

--Indexes ausw�hlen + filtered Indexes + Columnstore Indexes oder Partition
--Start Analysis

--Ergebnisse ausw�hlen, Rechtsklick -> Apply recommendation
--Action -> Apply recommendations
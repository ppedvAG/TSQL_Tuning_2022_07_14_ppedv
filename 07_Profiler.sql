--Profiler: Live mitverfolgen was auf der Datenbank passiert
--Tools -> SQL Server Profiler

--> Name: Dateiname
--> Template: Tuning
--> Save to File: .trc File speichern
--> Enable file rollover: File vergrößern, falls es zu groß wird
--> Enable trace stop time: 30min Maximaldauer

--> Events: SP:StmtStarting, SP:StmtStopping, SQL:BatchCompleted
--> Column Filters: Database LIKE <Name> (wenn nicht sichtbar, Show all Columns aktivieren)

USE Demo;
SELECT * FROM KundenUmsatz2; -- beide Abfragen sind jetzt im Profiler sichtbar

--Tuning Advisor
--Tools -> Database Engine Tuning Advisor

--braucht ein .trc File (vom Profiler)
--Datenbank für Workload auswählen (Demo im Testsystem, tempdb in der Realität)
--Datenbank auswählen (bei uns Demo)

--Indexes auswählen + filtered Indexes + Columnstore Indexes oder Partition
--Start Analysis

--Ergebnisse auswählen, Rechtsklick -> Apply recommendation
--Action -> Apply recommendations
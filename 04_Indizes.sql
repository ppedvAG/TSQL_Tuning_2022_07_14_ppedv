USE Demo;

/*
Heap: Tabelle in unsortierter Form

Non-Clustered Index (NCIX):
Baumstruktur (von oben nach unten suchen)
Maximal 1000 Stück pro Tabelle
Sollte verwendet werden auf Spalten die oft gesucht werden

Clustered Index (CIX):
Baumstruktur
Maximal 1 mal pro Tabelle
Sollte verwendet werden auf der Spalte die ein "Identifier" ist
Wird immer automatisch sortiert
Nachteil: bei Insert, Update, Delete wird immer automatisch -> bei Tabellen mit hohem IO eher vermeiden

Table Scan: ganze Tabelle durchsuchen
Index Scan: ganzen Index durchsuchen
Index Seek: bestimmte Daten suchen (beste)
*/

--Clustered Index
--USE Northwind;
SELECT * FROM Orders WHERE OrderID = 10248; --Clustered Index Seek
SELECT * FROM Customers; --Clustered Index Scan (weil kein WHERE)
INSERT INTO Customers (CustomerID, CompanyName) VALUES ('PPEDV', 'ppedv AG'); --Clustered Index Insert

SET STATISTICS time, io ON;

SELECT * 
INTO KundenUmsatz2 
FROM KundenUmsatz;

ALTER TABLE KundenUmsatz2
ADD ID int identity

SELECT * FROM KundenUmsatz2 WHERE ID = 2; --Customer mit ID 2 nicht oben in der Tabelle
--Ohne Clustered Index: CPU-Zeit = 204 ms, verstrichene Zeit = 62 ms, logische Lesevorgänge: 42166
--Mit Clustered Index: CPU-Zeit = 0 ms, verstrichene Zeit = 39 ms, logische Lesevorgänge: 3

SELECT * FROM KundenUmsatz2; --ID Spalte ist jetzt sortiert

SELECT *
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('KundenUmsatz2'), NULL, NULL, 'DETAILED'); --Informationen zu allen Indizes einer Tabelle

SELECT OBJECT_NAME(object_id) AS Tabelle, *
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED'); --Alle Indizes auf der Datenbank


SELECT * FROM KundenUmsatz2 WHERE freight > 50; --IX Seek
--Ohne Index: CPU-Zeit = 704 ms, verstrichene Zeit = 6182 ms, logische Lesevorgänge: 42240
--Mit NCIX: CPU-Zeit = 594 ms, verstrichene Zeit = 6177 ms, logische Lesevorgänge: 21451

SELECT ID FROM KundenUmsatz2 WHERE ID = 100; --Seek

SELECT ID, CustomerID FROM KundenUmsatz2 WHERE ID = 100; --Seek mit Lookup auf Tabelle

SELECT ID, CustomerID FROM KundenUmsatz2 WHERE ID = 100; --Bei Index jetzt CustomerID inkludiert -> nurnoch Seek

SELECT birthdate FROM KundenUmsatz2 WHERE freight > 50; --birthdate im Index nicht dabei -> Table Scan

SELECT freight, birthdate FROM KundenUmsatz2 WHERE freight > 50; --Table Scan da Datenmenge nach WHERE zu groß -> Server hat entschieden das Table Scan effizienter ist als Seek + Lookup

SELECT freight, birthdate FROM KundenUmsatz2 WHERE freight > 1000; --Seek + Lookup da kleine Datenmenge

SELECT FirstName, LastName FROM KundenUmsatz2 WHERE ID = 10000; --Gefilterter Index -> Nur bestimmte Spalten die im SELECT angegeben werden

SELECT FirstName, LastName, birthdate FROM KundenUmsatz2 WHERE ID > 50000; --Zu viele Daten für einen Lookup -> Table Scan, Birthdate zum Index hinzufügen um Index Seek zu ermöglichen

--Zusammengesetzter Index (NCIX_ID_EmployeeID)
SELECT * FROM KundenUmsatz2 WHERE ID > 40 AND EmployeeID < 3; --Index mit mehreren Schlüsseln

SELECT * FROM KundenUmsatz2 WHERE ID > 40; --Table Scan statt Index Scan -> EmployeeID im Index hat höhere Priorität, daher kann ich nicht nur nach ID filtern

SELECT * FROM KundenUmsatz2 WHERE EmployeeID < 3; --Funktioniert, da EmployeeID an erster Stelle

SELECT * FROM KundenUmsatz2 WHERE ID > 100 AND CustomerID LIKE 'A%'; --CustomerID als Schlüssel hinzugefügt, trotzdem Table Scan, weil EmployeeID immer noch Hauptschlüssel

--Indizierte View
SELECT Country, COUNT(*) FROM KundenUmsatz2 GROUP BY Country;
GO

CREATE VIEW ixDemo
AS
SELECT Country, COUNT(*) as Anzahl
FROM KundenUmsatz2
GROUP BY Country;
GO

SELECT * FROM ixDemo; --Table Scan
GO

ALTER VIEW ixDemo WITH SCHEMABINDING --WITH SCHEMABINDING: Verhindert Änderung der Tabellen hinter der View, Fehlermeldung bei Änderung der Originalen Tabelle
AS
SELECT Country, COUNT_BIG(*) as Anzahl
FROM dbo.KundenUmsatz2 --dbo davor schreiben, weil WITH SCHEMABINDING
GROUP BY Country;
GO

CREATE UNIQUE CLUSTERED INDEX CIX_Country ON ixDemo (Country);

SELECT * FROM ixDemo; --Index Scan

SELECT * FROM ixDemo WHERE Country = 'Austria'; --Index Seek

--ColumnStore Index
--Speichert eine Spalte als "eigene Tabelle"
--Kann dann sehr effizient genau eine Spalte durchsuchen

SELECT ID FROM KundenUmsatz2; --kein Index, Table Scan
--CPU-Zeit = 406 ms, verstrichene Zeit = 3192 ms, logische Lesevorgänge: 42162

SELECT ID FROM KundenUmsatz2; --normaler Index, Index Scan
--CPU-Zeit = 234 ms, verstrichene Zeit = 3229 ms, logische Lesevorgänge: 2474

SELECT ID FROM KundenUmsatz2; --ColumnStore Index (Non-Clustered)
--CPU-Zeit = 94 ms, verstrichene Zeit = 3217 ms, logische Lesevorgänge: 0

SELECT ID FROM KundenUmsatz2; --ColumnStore und Normaler Index
--Datenbank wählt aus welcher Index für die Aufgabe effizienter ist
--Datenbank hat ColumnStore ausgewählt

--Index für bestimmte Abfrage erstellen
select lastname, year(orderdate), month(orderdate), sum(unitprice*quantity)
from KundenUmsatz2
where shipcountry = 'USA' 
group by lastname, year(orderdate), month(orderdate)
order by 1,2,3

--Indizes warten
--Indizes werden über Zeit durch Insert, Update, Delete outdated
--Indizes aktualisieren, 2 Möglichkeiten
--Reorganize: Index neu sortieren ohne Neuaufbau
--Rebuild: Von Grund auf neu aufbauen

--Index mit Filter (WHERE)

CREATE NONCLUSTERED INDEX NCIX_UK ON KundenUmsatz2 (Freight) --Key Columns
INCLUDE (City, LastName) --Included Columns
WHERE Country = 'UK'; --Index erstellen mit Bedingung (wird nur angewandt wenn diese Bedingung auch im WHERE vom SELECT verwendet wird)

SELECT City, LastName FROM KundenUmsatz2; --Ohne WHERE: Table Scan

SELECT City, LastName FROM KundenUmsatz2 WHERE Country = 'UK'; --Index Scan
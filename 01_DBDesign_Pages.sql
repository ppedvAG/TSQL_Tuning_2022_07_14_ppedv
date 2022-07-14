/*
Normalerweise:
1. Jede Zelle hat einen Wert
2. Jede Zeile hat einen PK -> (eindeutige) Identifikation der Datensätze
3. Keine Beziehnungen zwischen nicht PK-Spalten

3 Schritte um Redundanz zu verringern

PK --> Beziehung --> FK

Kundentabelle -> 1 Mio. DS

Bestellungstabelle -> 2 Mio. DS

Kundentabelle --> Beziehung --> Bestellungen (1 zu n)
*/

/*
	8192 Byte gesamt
	132 Byte Headerinformationen
	8060 Byte Daten

	Datensätze müssen hinein passen
	Leerer Raum kann übrig bleiben
	1:1 in RAM geladen
*/

CREATE DATABASE Demo;

USE Demo;

CREATE TABLE T1 (id int identity, spx char(4100)); --sehr ineffizient

INSERT INTO T1
SELECT 'XY'
GO 20000 --GO <Zahl>: Befehl X-Mal wiederholen

SELECT COUNT(*) FROM T1;

--Wie groß ist die Tabelle?
--4100 * 20000 = 80MB, hat aber 160MB stattdessen

--Seiten/Blockinfo zu einer Tabelle
dbcc showcontig('T1');

--ObjectID von Objekt holen (Tabelle, Prozedur, ...)
SELECT OBJECT_ID('T1');

--DB_ID(), FileID: 0, IndexID: -1, PartitionID: 0, Mode: LIMITED/DETAILED
SELECT OBJECT_NAME(object_id), * FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED');

--use Northwind;
--select * from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Customers';
--CustomerID ist ein nchar -> könnte char sein (5 Byte Ersparnis pro Datensatz)

--Statistiken einschalten (Verbrauchte Zeit und Lesevorgänge)
SET STATISTICS time, io ON;

SELECT * FROM t1; 
--20000 Lesevorgänge, 250ms CPU-Zeit, 1378ms Gesamtzeit
--Lesevorgänge möglichst reduzieren, danach Gesamtzeit, danach CPU-Zeit

SELECT * FROM T1 WHERE ID = 20;
--20000 Lesevorgänge, 47ms CPU-Zeit, 50ms Gesamtzeit
--Durch ID weniger Output

SELECT TOP 1 * FROM T1 WHERE ID = 20;
--20 Lesevorgänge, 0/0
--Beim ersten gefundenen Datensatz direkt abbrechen

--Seiten reduzieren
--Bessere Datentypen oder Redesign

--1 Mio. * 2DS/Seite --> 500000 Seiten --> 4GB
--1 Mio. * 50DS/Seite --> 12500 --> 110MB
--Machbar durch Trennung der Datensätze in mehrere Tabellen

SET STATISTICS io, time OFF;

CREATE TABLE T2 (id int identity, sp1 varchar(4100)); --VARCHAR statt CHAR für besser Seitenoptimierung

INSERT INTO T2
SELECT 'XY'
GO 20000

DBCC showcontig('T2'); 
--50 Seiten statt 20000, 93.87% Seitendichte statt 50.37%
--Datensätze sind zu klein um Seite komplett auszufüllen (700 Datensätze Grenze erreicht)

--DROP TABLE T3;
CREATE TABLE T3 (id int identity, sp1 nvarchar(4000));

INSERT INTO T3
SELECT 'XY'
GO 20000

DBCC showcontig('T3');
--55 Seiten statt 50, 94.32% Seitendichte statt 93.87%
--Datensätze zu klein wiedermal

--Northwind
--CustomerID = nchar(5) --> könnte char sein
--char(50): 50B (fixe Länge, User muss 50 Zeichen eingeben)
--varchar(50): 4B
--nchar(50): 2 * 50B -> 100B (weil Unicode, 8B -> 16B)
--nvarchar(50): 2 * 4B -> 8B
--text -> deprecated seit 2005

--float -> 4B bei kurzen Zahlen, 8B bei langen Zahlen
--decimal(X, Y) -> Bytes Variabel (je weniger Platz, desto weniger Byte)

USE Northwind;
DBCC showcontig('Customers');

SET STATISTICS time, io ON;

DBCC showcontig('Orders'); --98.19%

SELECT * FROM Orders WHERE YEAR(OrderDate) = 1997; --143ms

SELECT * FROM Orders WHERE OrderDate BETWEEN '19970101' AND '19971231'; --110ms

SELECT * FROM Orders WHERE OrderDate >= '19970101' AND OrderDate <= '19971231'; --Dauert etwas länger 150ms-200ms

--BETWEEN am schnellsten, YEAR ist auch okay
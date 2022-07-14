USE Demo;

CREATE PARTITION FUNCTION pfZahl(int)
AS
RANGE LEFT FOR VALUES (100, 200); --Ranges festlegen (0-100, 101-200, 201-Unendlich)

SELECT $partition.pfZahl(200); --Schauen ob die Funktion korrekt arbeitet

-- 3 Datengruppen anlegen (bis100, bis200, rest) + Files (b100, b200, r)

CREATE PARTITION SCHEME schZahl
AS
PARTITION pfZahl TO (bis100, bis200, rest)
-------- 100 -> bis100 --------- 200 -> bis 200 ---------- > 200 -> rest ----------

CREATE TABLE pTable (id int identity, partitionNumber int, spx char(4100)) ON schZahl(partitionNumber)
--PartitionNumber muss existieren als Feld um Datensätze auf Partition zu legen
--mit ON Partitionsschema(nummer) festlegen, wie die Tabelle partitioniert werden soll

DECLARE @i int = 0;
WHILE @i < 20000
BEGIN
	INSERT INTO pTable VALUES (@i, 'XY');
	SET @i += 1;
END

SET STATISTICS time, io ON;

SELECT * FROM pTable WHERE partitionNumber = 120; --0ms/0ms sehr schnell da mittlere Partition (100 Werte)

SELECT * FROM pTable WHERE id = 120; --20000 Seiten müssen durchsucht werden, 47ms/42ms

SELECT * FROM pTable WHERE partitionNumber = 1500; --20000 Seiten müssen durchsucht werden 47ms/39ms

--Neue Grenze einbauen bei 5000

ALTER PARTITION SCHEME schZahl NEXT USED bis5000;

--Partitionsinformationen über Tabelle anzeigen
SELECT
$partition.pfZahl(partitionNumber),
COUNT(*) AS Anzahl,
MIN(partitionNumber) AS KleinerDS,
MAX(partitionNumber) AS GroessterDS
FROM pTable
GROUP BY $partition.pfZahl(partitionNumber);

ALTER PARTITION FUNCTION pfZahl() SPLIT RANGE(5000); --Füge einen Split hinzu zwischen den nächsten beiden FileGruppen ohne Teilung dazwischen

ALTER PARTITION FUNCTION pfZahl() MERGE RANGE(100); --Zwei Partitionen zusammenfügen bei einer Range (Hier 100 entfernen)

CREATE TABLE archiv (id int identity, partitionNumber int, spx char(4100)) ON bis200; --Archiv Tabelle erstellen

ALTER TABLE pTable SWITCH PARTITION 1 TO archiv; --Partition von pTable verschieben ins Archiv

SELECT * FROM archiv; --0 - 200

SELECT * FROM pTable; --200 - Ende
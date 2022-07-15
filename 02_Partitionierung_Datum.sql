CREATE PARTITION FUNCTION fDatum(datetime)
AS
RANGE LEFT FOR VALUES ('20190101', '20200101', '20210101');

CREATE PARTITION SCHEME schDatum
AS
PARTITION fDatum TO ('bis2019', 'bis2020', 'bis2021', 'ab2021');

create table rechnungen (id int identity, rechnungsdatum datetime, betrag float) ON schDatum(rechnungsdatum);

DECLARE @i int = 0;
WHILE @i < 3000
BEGIN
	INSERT INTO rechnungen VALUES
	(DATEADD(DAY, FLOOR(RAND()*1460), '20180101'), RAND() * 1000);
	SET @i += 1;
END

--Datensätze aus der Tabelle in die Partitionsfunktion geben, um zu prüfen welche Datensätze wo sein würden
SELECT
$partition.fDatum(rechnungsdatum),
COUNT(*) AS Anzahl,
MIN(rechnungsdatum) AS KleinerDS,
MAX(rechnungsdatum) AS GroessterDS
FROM rechnungen
GROUP BY $partition.fDatum(rechnungsdatum);

--Tatsächliche Partitionsdaten einsehen
SELECT OBJECT_NAME(object_id), *
FROM sys.dm_db_partition_stats
-- WHERE OBJECT_NAME(object_id) = 'Kundenumsatz'; --optional

-------------------------------------------------------------------------------------------------------------------

CREATE PARTITION FUNCTION [f_OrderDate](datetime) 
AS 
RANGE LEFT FOR VALUES (N'2019-01-01T00:00:00', N'2020-01-01T00:00:00', N'2021-01-01T00:00:00')


CREATE PARTITION SCHEME [sch_OrderDate] 
AS 
PARTITION [f_OrderDate] TO ([bis2019], [bis2020], [bis2021], [ab2021])

CREATE CLUSTERED INDEX [ClusteredIndex_on_sch_OrderDate_637934257922141476] ON [dbo].[KundenUmsatz] ([OrderDate])
WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, DATA_COMPRESSION = PAGE ON PARTITIONS (1 TO 4)) ON [sch_OrderDate]([OrderDate])

DROP INDEX [ClusteredIndex_on_sch_OrderDate_637934257922141476] ON [dbo].[KundenUmsatz]
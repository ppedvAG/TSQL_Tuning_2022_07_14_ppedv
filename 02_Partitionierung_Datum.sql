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

SELECT
$partition.fDatum(rechnungsdatum),
COUNT(*) AS Anzahl,
MIN(rechnungsdatum) AS KleinerDS,
MAX(rechnungsdatum) AS GroessterDS
FROM rechnungen
GROUP BY $partition.fDatum(rechnungsdatum);
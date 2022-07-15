--MAXDOP: Mehr CPUs wenn sinnvoll
--MAXimum Degree Of Parallelism

--ab einem Kostenschwellwert werden alle CPUs verwendet
--Standard: 5

--MAXDOP setzbar auf Server, DB, Query Ebene
--Query > DB > Server

--Parallelisierung im Plan sichtbar anhand zwei Gelber nach links zeigender Pfeile
--Am Ende des Plans -> Mauszeiger über letztes Element -> Degree of Parallelism

USE Demo;

SET STATISTICS io, time ON;

SELECT * FROM KundenUmsatz2; --Keine Parallelisierung
--CPU-Zeit = 1515 ms, verstrichene Zeit = 12283 ms, logische Lesevorgänge: 42162

SELECT * FROM KundenUmsatz2 OPTION (MAXDOP 8);
--CPU-Zeit = 1453 ms, verstrichene Zeit = 12034 ms, logische Lesevorgänge: 42162

--Keine Veränderung da keine Parallelisierung

SELECT Country, SUM(freight) FROM KundenUmsatz2 GROUP BY Country; --> Parallelisiert da Kosten von 31, MAXDOP 8
--CPU-Zeit = 218 ms, verstrichene Zeit = 90 ms, logische Lesevorgänge: 42162

SELECT Country, SUM(freight) FROM KundenUmsatz2 GROUP BY Country OPTION (MAXDOP 1); --> Keine Parallelisierung, verwende maximal einen CPU-Kern
--CPU-Zeit = 172 ms, verstrichene Zeit = 205 ms, logische Lesevorgänge: 42162
-->Doppelt so lange wie mit MAXDOP 8

SELECT Country, SUM(freight) FROM KundenUmsatz2 GROUP BY Country OPTION (MAXDOP 4);
--CPU-Zeit = 234 ms, verstrichene Zeit = 91 ms, logische Lesevorgänge: 42162
--Kein wirklicher Unterschied zwischen 4 und 8

--Abfrage zu kurz für wirklichen Unterschied

SELECT *, YEAR(OrderDate), CONCAT_WS(' ', FirstName, LastName)
FROM KundenUmsatz2
WHERE Country IN(SELECT Country FROM KundenUmsatz2 WHERE Country LIKE 'A%'); --MAXDOP 8
--CPU-Zeit = 1109 ms, verstrichene Zeit = 1355 ms, logische Lesevorgänge: 84324 (2 Selects)

SELECT *, YEAR(OrderDate), CONCAT_WS(' ', FirstName, LastName)
FROM KundenUmsatz2
WHERE Country IN(SELECT Country FROM KundenUmsatz2 WHERE Country LIKE 'A%')
OPTION (MAXDOP 1);
--CPU-Zeit = 640 ms, verstrichene Zeit = 1501 ms, logische Lesevorgänge: 84324

SELECT *, YEAR(OrderDate), CONCAT_WS(' ', FirstName, LastName)
FROM KundenUmsatz2
WHERE Country IN(SELECT Country FROM KundenUmsatz2 WHERE Country LIKE 'A%')
OPTION (MAXDOP 4);
--CPU-Zeit = 827 ms, verstrichene Zeit = 1626 ms, logische Lesevorgänge: 84324
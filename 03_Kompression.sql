--Kompression
--für Client komplett transparent (bei SELECT wird dekomprimiert, User sieht nix)
--Tabellen -> Zeilenkompression oder Seitenkompression
-- 40-60% Platzersparnis

SET STATISTICS time, io ON;

SELECT * FROM Kundenumsatz;
--7813ms CPU, 60s Gesamt

--Kompression:
--Row: 322MB -> 180MB (45%)
--Page: 322MB -> 85MB (75%)

--Row Compression:
SELECT * FROM Kundenumsatz;
--9203ms CPU, 50s Gesamt
--CPU +2 Sekunden, Gesamt -12 Sekunden

--Page Compression
SELECT * FROM Kundenumsatz;
--14750ms CPU, 67s Gesamtzeit
--CPU +5 Sekunden, Gesamt +17 Sekunden

--Bestimmte Partition komprimieren (hier Partition 1), WITH(DATA_COMPRESSION = NONE/ROW/PAGE)
ALTER TABLE pTable REBUILD PARTITION = 1 WITH(DATA_COMPRESSION = ROW);
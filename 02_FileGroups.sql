/*
	Dateigruppen:
	[PRIMARY]: Hauptgruppe, enthält Systemdatenbanken, kann nicht entfernt werden (.mdf)
	Nebengruppen: Datenbankobjekte können auch auf Nebengruppen abgelegt werden (.ndf)
*/

CREATE TABLE XYZ (id int) --Primärgruppe;

CREATE TABLE XYZ (id int) ON [PRIMARY]; --Auf Primärgruppe legen, nur Sinnvoll wenn die Primärgruppe nicht die Standardgruppe ist

CREATE TABLE XYZ (id int) ON [AKTIV]; --Tabelle auf andere Gruppe legen

ALTER DATABASE Demo ADD FILEGROUP [AKTIV]; --Filegruppe erstellen, braucht noch ein File

ALTER DATABASE Demo ADD FILE  --File erstellen: Name, FileName (Pfad mit Dateiname), Initialgröße, Wachstum
(
	NAME='DemoAktiv', 
	FILENAME='C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\DemoAktivData.ndf', 
	SIZE=8192KB, 
	FILEGROWTH=64MB
)
TO FILEGROUP [AKTIV];

--Wie bewegt man eine Tabelle auf eine andere Dateigruppe?
--Tabelle auf anderer Seite erstellen, danach Daten bewegen

CREATE TABLE XYZneu (id int) ON [PRIMARY]; --Neuen Table erstellen

INSERT INTO XYZneu 
SELECT * FROM XYZ; --Alle Daten bewegen mittels INSERT INTO -> SELECT

CREATE TABLE Umsatz2021 --Testtabellen erstellen
(
	Datum date,
	Umsatz decimal(5, 2)
);

DECLARE @i int = 0; --Testtabellen befüllen
WHILE @i < 50000
BEGIN
	INSERT INTO Umsatz2021 VALUES
	(DATEADD(DAY, FLOOR(RAND()*365), '20210101'), RAND() * 1000);
	SET @i += 1;
END

CREATE VIEW UmsatzGesamt --Umsätze kombinieren in View
AS
SELECT * FROM Umsatz2019
UNION ALL
SELECT * FROM Umsatz2020
UNION ALL
SELECT * FROM Umsatz2021

SELECT * FROM UmsatzGesamt WHERE YEAR(Datum) = 2019; --Greift alle 3 Tabellen an obwohl nur in einer das entsprechende Jahr enthalten sein kann

ALTER TABLE Umsatz2019 ADD CONSTRAINT CHK_Year2019 CHECK (YEAR(Datum) = 2019); --Check Constraints hinzufügen
ALTER TABLE Umsatz2020 ADD CONSTRAINT CHK_Year2020 CHECK (YEAR(Datum) = 2020);
ALTER TABLE Umsatz2021 ADD CONSTRAINT CHK_Year2021 CHECK (YEAR(Datum) = 2021);

ALTER TABLE Umsatz2019 ADD ID int identity primary key --IDs im nachhinein hinzufügen
ALTER TABLE Umsatz2020 ADD ID int identity primary key
ALTER TABLE Umsatz2021 ADD ID int identity primary key

SELECT * FROM UmsatzGesamt WHERE YEAR(Datum) = 2019; --Greift nurnoch eine Tabelle an (Umsatz2019)
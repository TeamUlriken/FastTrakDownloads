EXEC AddSchema 'Rapporteket'
GO

IF NOT OBJECT_ID('Rapporteket.Variable') IS NULL DROP TABLE Rapporteket.Variable
GO

CREATE TABLE Rapporteket.Variable( 
  ItemId INT NOT NULL REFERENCES dbo.MetaItem( ItemId ) PRIMARY KEY,
  VarLabel VARCHAR(64) NOT NULL )
GO

INSERT INTO Rapporteket.Variable VALUES( 6299, 'DiagnoseAddison' )
INSERT INTO Rapporteket.Variable VALUES( 6089, 'AddisonDiagnoseår' )
INSERT INTO Rapporteket.Variable VALUES( 6090, 'AddisonAutoimmun' )
INSERT INTO Rapporteket.Variable VALUES( 3981, 'Antistoff21OH' )
INSERT INTO Rapporteket.Variable VALUES( 8296, 'AddisonKortUtlevert' )
INSERT INTO Rapporteket.Variable VALUES( 8297, 'AddisonSprøyte' )
INSERT INTO Rapporteket.Variable VALUES( 7990, 'AddisonKriserSisteÅr' )
INSERT INTO Rapporteket.Variable VALUES( 7992, 'KortisonDoseøkning' )
INSERT INTO Rapporteket.Variable VALUES( 3397, 'Koronarsykdom' )
INSERT INTO Rapporteket.Variable VALUES( 7510, 'Osteoporose' )
INSERT INTO Rapporteket.Variable VALUES( 3310, 'BMI' )
INSERT INTO Rapporteket.Variable VALUES( 3230, 'SysBlodtrykk' )
INSERT INTO Rapporteket.Variable VALUES( 3231, 'DiaBlodtrykk' )
INSERT INTO Rapporteket.Variable VALUES( 5670, 'Salthunger' )
INSERT INTO Rapporteket.Variable VALUES( 6607, 'DiagnoseAPSType' )
-- APS1 og APS2 er på samme variabel
INSERT INTO Rapporteket.Variable VALUES( 6321, 'DiagnoseHypopara' )
INSERT INTO Rapporteket.Variable VALUES( 6312, 'DiagnoseHypOtyreose' )
INSERT INTO Rapporteket.Variable VALUES( 6313, 'DiagnoseHypERtyreose' )
-- Hypogonadisme
INSERT INTO Rapporteket.Variable VALUES( 3410, 'DiagnoseCøliaki' )
INSERT INTO Rapporteket.Variable VALUES( 3411, 'DiagnoseVitiligo' )
INSERT INTO Rapporteket.Variable VALUES( 6320, 'DiagnoseAlopeci' )
INSERT INTO Rapporteket.Variable VALUES( 6322, 'DiagnoseKandidiasis' )
INSERT INTO Rapporteket.Variable VALUES( 6317, 'DiagnoseVitaminB12Mangel' )
INSERT INTO Rapporteket.Variable VALUES( 8543, 'DiagnoseHypofysitt' )
INSERT INTO Rapporteket.Variable VALUES( 6633, 'FamilieAutoimmunitet' )
INSERT INTO Rapporteket.Variable VALUES( 6636, 'FamilieAddison' )
INSERT INTO Rapporteket.Variable VALUES( 6808, 'FamilieAPS1' )
GO

IF NOT OBJECT_ID('Rapporteket.Pasienter') IS NULL DROP VIEW Rapporteket.Pasienter
GO

CREATE VIEW Rapporteket.Pasienter AS
  SELECT p.PersonId,p.GenderId,DATEPART(yy,p.DOB) AS BornYear,p.FylkeNr,p.DeceasedInd AS IsDead,CONVERT(DATE,p.DeceasedDate) as DeathDate
  FROM dbo.Person p JOIN dbo.StudCase sc ON sc.PersonId=p.PersonId
  JOIN Study s ON s.StudyId=sc.StudyId 
  JOIN StudyGroup sg ON sg.StudyId=sc.StudyId AND sg.GroupId = sc.GroupId AND sg.GroupActive=1
  WHERE s.StudName = 'ROAS'
GO


IF NOT OBJECT_ID('Rapporteket.Skjemadata') IS NULL DROP VIEW Rapporteket.Skjemadata
GO

CREATE VIEW Rapporteket.Skjemadata AS
SELECT cp.RowId,ce.PersonId,v.ItemId, v.VarLabel,CONVERT(Date,ce.EventTime) AS [Date],cp.Quantity AS NumValue,REPLACE(mia.OptionText,'*','') AS TxtValue
FROM dbo.ClinDataPoint cp 
JOIN dbo.ClinEvent ce ON ce.EventId = cp.EventId 
JOIN Rapporteket.Pasienter p ON p.PersonId=ce.PersonId
JOIN Rapporteket.Variable v ON v.ItemId=cp.ItemId
LEFT OUTER JOIN dbo.MetaItemAnswer mia ON mia.ItemId = cp.ItemId AND mia.OrderNumber = cp.EnumVal
WHERE cp.Quantity <> -1 
GO

SELECT * FROM Rapporteket.Pasienter

SELECT * FROM Rapporteket.Skjemadata ORDER BY PersonId


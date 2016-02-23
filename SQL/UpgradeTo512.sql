EXEC AddSCHEMA 'KB'
GO

SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo512;
PRINT 'Starting upgrade to 512'

DELETE FROM DbUpgradeLog WHERE DbVer > 511;
GO
EXEC DbCheckVersion 511;           
EXECUTE DbStartUpgrade 512;
GO

ALTER VIEW [NDV].[EnkeltRegneark] AS
SELECT v.PersonId, v.DOB, v.FullName, DATEDIFF(year, v.DOB, GETDATE()) AS Alder, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_TYPE')) AS NDV_TYPE, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_CONSENT')) AS NDV_CONSENT, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'SYSBP')) AS SYSBT, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'DIABP')) AS DIABT, 
    dbo.GetLastLab(v.PersonId, 'HBA1C') AS [Lab.HbA1c], 
    dbo.GetLastLab(v.PersonId, 'LDL') AS [Lab.LDL], 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_DIAGNOSE_YYYY')) AS NDV_DIAGNOSE_YYY,
    ( SELECT COUNT(*) FROM OngoingTreatment WHERE PersonId=v.PersonId AND ( ATC LIKE 'C0[2789]%' 
    OR StartReason IN ( 'Høyt blodtrykk','Hypertensjon','Blodtrykk' ))) AS [DrugList.BpDrugs],
    
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_SMOKING')) AS V3227, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'ALKOHOL_PER_UKE')) AS V3986, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_HYPOGLYCEMIA')) AS V3351, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'DM_HYPOGLYC_MONTH')) AS V3220, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'GLUC_SELFMON')) AS V5715, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_KETOACIDOSIS')) AS V3352, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_BPDRUGS')) AS V4079,
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_FOOT_SENS')) AS V4636, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_FOOT_PULSE')) AS V4637, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_EYESIGHT')) AS V3404, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_FOOT_ULCER')) AS V3218, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_AMPUTATION')) AS V3414, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_NEPHROPATHY')) AS V3415, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_RETINOPATHY')) AS V4087, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_CHD')) AS V3397, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_STROKE')) AS V3398, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_ARTERIAL_SURGERY')) AS V3417
FROM
 dbo.ViewActiveCaseListStub AS v JOIN dbo.Study AS s ON s.StudyId = v.StudyId AND s.StudyName = 'NDV'
GO

IF NOT OBJECT_ID('KB.ViewNorGEPPoly') IS NULL DROP VIEW KB.ViewNorGEPPoly
GO

IF NOT OBJECT_ID('KB.ViewDistinctDrugs') IS NULL DROP VIEW KB.ViewDistinctDrugs
GO

IF NOT OBJECT_ID('KB.ViewNorGEPInteractions') IS NULL DROP VIEW KB.ViewNorGEPInteractions
GO

IF NOT OBJECT_ID('KB.InteractionNorGEP') IS NULL DROP TABLE KB.InteractionNorGEP
GO

IF NOT OBJECT_ID('KB.NorGEP') IS NULL DROP TABLE KB.NorGEP
GO
 
IF NOT OBJECT_ID('GBD.GetCaseListNorGEP') IS NULL DROP PROCEDURE GBD.GetCaseListNorGEP
GO

CREATE TABLE KB.InteractionNorGEP( Id INT NOT NULL, NgId INT NOT NULL,IntId INT NOT NULL ) 
GO

ALTER TABLE KB.InteractionNorGEP ADD CONSTRAINT PK_InteractionNorGEP PRIMARY KEY(Id)
GO

TRUNCATE TABLE KB.InteractionNorGEP
GO

INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(1,22,433); 
-- INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(2,23,377); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(3,23,381); 
-- INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(4,24,377); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(5,24,379); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(6,24,380); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(7,25,418); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(8,26,2533); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(9,27,755); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(10,28,1332); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(11,29,2305); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(12,30,1470); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(13,30,1081); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(14,30,1082); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(15,30,1444); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(16,30,1116); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(17,31,334); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(18,31,800); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(19,32,2273); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(20,32,2275); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(21,33,831); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(22,33,832);
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(23,34,1024); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(24,34,1059); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(25,34,986); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(26,34,1022); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(27,35,1425); 
INSERT INTO KB.InteractionNorGEP (Id,NgId,IntId) VALUES(28,35,1456); 
GO 

ALTER TABLE KB.InteractionNorGEP ADD AlertClass AS ( 'DRUID#'+CONVERT(VARCHAR,IntId) )
GO

CREATE TABLE KB.NorGEP ( Id INT NOT NULL, ATC VARCHAR(7), MaxDose DECIMAL (12,2), AgeLow INT, AgeHigh INT, Warning VARCHAR(MAX) NOT NULL )
GO

ALTER TABLE KB.NorGEP ADD CONSTRAINT PK_NorGEP PRIMARY KEY(Id)
GO

INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES(  1, 'N06AA09', 'Antikolinerge effekter. Fare for forstyrret kognitiv funksjon.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES(  2, 'N06AA12', 'Antikolinerge effekter. Fare for forstyrret kognitiv funksjon.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES(  3, 'N06AA04', 'Antikolinerge effekter. Fare for forstyrret kognitiv funksjon.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES(  4, 'N06AA06', 'Antikolinerge effekter og ekstrapyramidale effekter.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES(  5, 'N05AA01', 'Antikolinerge effekter og ekstrapyramidale effekter.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES(  6, 'N05AF03', 'Antikolinerge effekter og ekstrapyramidale effekter.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES(  7, 'N05AA02', 'Antikolinerge effekter og ekstrapyramidale effekter.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES(  8, 'N05AB04', 'Antikolinerge effekter og ekstrapyramidale effekter. Ofte forskrevet mot svimmelhet.  Ingen dokumentert effekt hos eldre.' )

INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES(  9, 'N05BA01', 'Lang halveringstid.  Også aktive metabolitter med T1/2 > 50 timer.  Fare for akkumulasjon i kroppen, muskelsvakhet.  Økt fare for fall og brudd.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES( 10, 'N05CD02', 'Lang halveringstid.  Også aktive metabolitter med T1/2 > 50 timer.  Fare for akkumulasjon i kroppen, muskelsvakhet.  Økt fare for fall og brudd.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES( 11, 'N05CD03', 'Lang halveringstid.  Også aktive metabolitter med T1/2 > 50 timer.  Fare for akkumulasjon i kroppen, muskelsvakhet.  Økt fare for fall og brudd.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning, MaxDose ) VALUES( 12, 'N05BA03', 'Fare for muskelsvakhet og fare for fall og brudd.', 30.0 )
INSERT INTO KB.NorGEP( Id,ATC,Warning, MaxDose ) VALUES( 13, 'N05CF01', 'Fare for muskelsvakhet og fare for fall og brudd.', 7.5 ) 
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES( 14, 'M03BA02', 'Antikolinerge effekter. Fare for tilvenning.' )

INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES( 15, 'N02AC54', 'Toksisk, smal terapeutisk bredde.  Bedre alternativer finnes.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES( 16, 'R03DA04', 'Fare for hjerterytmeforstyrrelser.  Ikke dokumentert effekt på KOLS.  Bedre behandlingsalternativer finnes.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES( 17, 'C07AA07', 'Fare for rytmeforstyrrelser (Torsade de pointes).  Brukes med forsiktighet.  Bedre alternativer finnes hvis indikasjonen er betablokade.' )

INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES( 18, 'R06AB02', 'Antikolinerge effekter. Forlenget sedasjon.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES( 19, 'R06AD02', 'Antikolinerge effekter. Forlenget sedasjon.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES( 20, 'N05BB01', 'Antikolinerge effekter. Forlenget sedasjon.' )
INSERT INTO KB.NorGEP( Id,ATC,Warning ) VALUES( 21, 'R06AD01', 'Antikolinerge effekter. Forlenget sedasjon.' )

INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 22, 'Økt risiko for gastrointestinal blødning.' )
INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 23, 'Økt risiko for gastrointestinal blødning.' )
INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 24, 'Økt risiko for gastrointestinal blødning.' )
INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 25, 'Økt risiko for gastrointestinal blødning, også pga. SSRIs direkte blodplatehemning.' )

INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 26, 'Økt risko for medikamentelt utløst nyresvikt.' )
INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 27, 'Redusert effekt av diuretika.' )
INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 28, 'Økt risiko for gastrointestinal blødning og væskeretensjon.' )
INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 29, 'Økt risiko for gastrointestinal blødning, også pga. SSRIs direkte blodplatehemning.' )
INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 30, 'Økt risiko for bivirkninger av statiner, inklusive rabdomyolyse pga. hemning av statinmetabolismen.' )
INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 31, 'Fare for hyperkalemi.' )
INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 32, 'Økt risiko for økt TCA-effekt pga hemmet metabolisme av TCA.' )
INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 33, 'Økt risiko for AV-blokk og myokarddepresjon.' )
INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 34, 'Økt risiko for bivirkninger av statiner, inklusive rabdomyolyse pga. hemning av statinmetabolismen.' )
INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 35, 'Redusert metabolisme av karbamazepin, økt fare for bivirkninger av karbamazepin.' )
INSERT INTO KB.NorGEP( Id,Warning ) VALUES( 36, 'Økt risiko for muskelsvakhet, fall og brudd, og forstyrret kognitiv funksjon.' )
GO

UPDATE KB.NorGEP SET AgeHigh = 120
GO

UPDATE KB.NorGEP SET AgeLow = 70 WHERE Id <=21
GO

CREATE VIEW KB.ViewNorGEPInteractions
AS
  SELECT p.StudyId,p.PersonId,p.DOB,p.FullName,p.GroupName,ng.NgId,ng.IntId,a.AlertLevel,a.AlertHeader,i.InfoText,n.Warning 
  FROM dbo.Alert a 
  JOIN KB.InteractionNorGEP ng ON ng.AlertClass=a.AlertClass
  JOIN KB.NorGEP n ON n.Id=ng.NgId
  JOIN dbo.KbInteraction i ON i.IntId=ng.IntId
  JOIN dbo.ViewActiveCaseListStub p on p.PersonId=a.PersonId and p.StudyId=a.StudyId
  WHERE AlertLevel > 0
GO

CREATE VIEW KB.ViewDistinctDrugs
AS
  SELECT DISTINCT PersonId,ATC FROM DrugTreatment WHERE ( ( StopAt IS NULL) OR ( StopAt > getdate() ) )
GO

GRANT SELECT ON KB.ViewDistinctDrugs TO public
GO

CREATE VIEW KB.ViewNorGEPPoly
AS
  SELECT PersonId,count(*) as DrugCount FROM KB.ViewDistinctDrugs 
  WHERE (CHARINDEX('N06A',ATC ) = 1 OR CHARINDEX('N05BA',ATC ) = 1 OR CHARINDEX('N05',ATC ) = 1 OR CHARINDEX('N02A',ATC ) = 1)
  GROUP BY PersonId
  HAVING count(*) > 2
GO

GRANT SELECT ON KB.ViewNorGEPPoly TO public
GO

CREATE PROCEDURE GBD.GetCaseListNorGEP( @StudyId INT ) AS
BEGIN
 
  SELECT DISTINCT dt.PersonId,p.DOB,p.FullName,a.GroupName,dt.DrugName + ': ' + ng.Warning + ' (NorGEP ' + CONVERT(VARCHAR,ng.Id) + ')' AS InfoText,ng.Id  
  FROM DrugTreatment dt JOIN KB.NorGEP ng ON dt.ATC=ng.ATC 
    JOIN ViewActiveCaseListStub a ON a.PersonId=dt.PersonId AND StudyId=@StudyId
    JOIN Person p ON p.PersonId=a.PersonId   
  WHERE  ( ( dt.StopAt IS NULL ) OR ( dt.StopAt > getdate() ) ) 
    AND ( ( ng.MaxDose IS NULL ) OR ( ng.MaxDose < dt.Dose24HDD ) OR ( dt.Dose24hDD IS NULL ) )
    AND ( ( p.DOB < getdate()-365.25*AgeLow ) AND ( p.DOB > getdate()-365.24*AgeHigh ) )                                                                 

  UNION
  
  SELECT PersonId,DOB,FullName,GroupName, AlertHeader + ': ' + Warning + ' (NorGEP ' + CONVERT(VARCHAR,NgId) + ')' AS InfoText, ngId
  FROM KB.ViewNorGEPInteractions WHERE StudyId=@StudyId
  
  UNION
  
  SELECT a.PersonId, a.DOB, a.FullName, a.GroupName, n.Warning + '(NorGEP 36, n=' + CONVERT(VARCHAR,v.DrugCount) + ')' as InfoText,36 as Id FROM KB.ViewNorGEPPoly v 
  JOIN ViewActiveCaseListStub a ON a.PersonId=v.PersonId AND a.StudyId=@StudyId    
  JOIN KB.NorGEP n ON n.Id=36
  
  ORDER BY ng.Id
  
END
GO

GRANT EXECUTE ON GBD.GetCaseListNorGEP TO public
GO

DELETE FROM DbProcList WHERE ProcId IN (1000,1001)
GO

INSERT INTO DbProcList (ProcId,ListId,ProcName,ProcDesc,ProcParams,StudyName) VALUES(1000,'CASE','GBD.GetCaseListNorGEP','Forsiktighetsregler: NorGEP',':StudyId','GBD' )
GO
INSERT INTO DbProcList (ProcId,ListId,ProcName,ProcDesc,ProcParams,StudyName) VALUES(1001,'CASE','GBD.GetCaseListNorGEP','Medisinbruk: NorGEP',':StudyId','GBD' )
GO

IF OBJECT_ID('dbo.MetaThreadType') IS NULL 
BEGIN
  CREATE TABLE dbo.MetaThreadType ( V INT NOT NULL, DN VARCHAR(32) NOT NULL, ThreadNames VARCHAR(MAX), FixedThreads BIT, NewThreadName VARCHAR(32) )
  ALTER TABLE dbo.MetaThreadType ADD CONSTRAINT PK_MetaThreadType PRIMARY KEY (V)
  INSERT INTO dbo.MetaThreadType (V,DN,ThreadNames, FixedThreads ) VALUES( 1, 'Lateralitet', 'Venstre;Høyre;', 1 )   
  INSERT INTO dbo.MetaThreadType (V,DN,FixedThreads,NewThreadName) VALUES( 2, 'Fotsår', 0, 'Nytt fotsår' ) 
  INSERT INTO dbo.MetaThreadType (V,DN,FixedThreads,NewThreadName) VALUES( 3, 'Intrakranielle aneurysmer', 0, 'Nytt aneurysme' )
END
GO

IF dbo.DbColumnExists( 'dbo.MetaForm', 'ThreadTypeId' ) = 0
BEGIN
  ALTER TABLE dbo.MetaForm ADD ThreadTypeId INT
  ALTER TABLE dbo.MetaForm ADD CONSTRAINT FK_MetaForm_MetaThreadType FOREIGN KEY ( ThreadTypeId ) REFERENCES dbo.MetaThreadType( V ) 
END 
GO

IF dbo.DbColumnExists( 'dbo.MetaItem', 'ThreadTypeId' ) = 0
BEGIN
  ALTER TABLE dbo.MetaItem ADD ThreadTypeId INT
  ALTER TABLE dbo.MetaItem ADD CONSTRAINT FK_MetaItem_MetaThreadType FOREIGN KEY ( ThreadTypeId ) REFERENCES dbo.MetaThreadType( V ) 
END 
GO

EXECUTE DbFinalizeUpgrade 512;

COMMIT TRANSACTION UpgradeTo512;
GO
  


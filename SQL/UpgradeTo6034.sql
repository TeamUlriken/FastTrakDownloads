BEGIN TRANSACTION UpgradeTo6034
PRINT 'Starting upgrade to 6034'

DELETE FROM DbUpgradeLog WHERE DbVer > 6033;

EXEC DbCheckVersion 6033;
EXECUTE DbStartUpgrade 6034;
GO

IF NOT OBJECT_ID('RunAtMidnight') IS NULL
  DROP PROCEDURE dbo.RunAtMidnight
GO

IF NOT OBJECT_ID('RemoveProc') IS NULL
 DROP PROCEDURE dbo.RemoveProc
GO

IF NOT EXISTS ( SELECT * FROM sysindexes WHERE name = 'I_ClinDrugIndication_ProbTreat' )
  CREATE UNIQUE INDEX I_ClinDrugIndication_ProbTreat ON dbo.ClinDrugIndication (ProbId, TreatId)
GO

-- Rename FK constraint from Alert to Person, and cascade deletes.
 
IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_Alert_Person' ) 
  ALTER TABLE dbo.Alert DROP CONSTRAINT FK_Alert_Person
GO
 
IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_Alert_PersonId' ) 
  ALTER TABLE dbo.Alert DROP CONSTRAINT FK_Alert_PersonId
GO

ALTER TABLE dbo.Alert WITH CHECK ADD CONSTRAINT FK_Alert_PersonId FOREIGN KEY (PersonId)
  REFERENCES dbo.Person (PersonId)
  ON DELETE CASCADE 
  ON UPDATE NO ACTION
GO

-- Rename FK constraint from CaseLog to Person, and cascade deletes

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_CaseLog_Person' ) 
  ALTER TABLE dbo.CaseLog DROP CONSTRAINT FK_CaseLog_Person
GO

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_CaseLog_PersonId' ) 
  ALTER TABLE dbo.CaseLog DROP CONSTRAINT FK_CaseLog_PersonId
GO

ALTER TABLE dbo.CaseLog WITH CHECK ADD CONSTRAINT FK_CaseLog_PersonId FOREIGN KEY (PersonId)
  REFERENCES dbo.Person (PersonId)
  ON DELETE CASCADE 
  ON UPDATE NO ACTION
GO

-- Rename FK constraint from ClinLog to ClinDatapoint, and cascade deletes

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_ClinLog_ClinObservation' )
  ALTER TABLE dbo.ClinLog DROP CONSTRAINT FK_ClinLog_ClinObservation
GO 

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_ClinLog_RowId' )
  ALTER TABLE dbo.ClinLog DROP CONSTRAINT FK_ClinLog_RowId
GO 

ALTER TABLE dbo.ClinLog WITH CHECK ADD CONSTRAINT FK_ClinLog_RowId FOREIGN KEY (RowId)
  REFERENCES dbo.ClinDataPoint (RowId)
  ON DELETE CASCADE 
  ON UPDATE NO ACTION
GO

-- Rename FK constraint from ClinRelation to Person, and cascade deletes

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_ClinRelation_Person' )
  ALTER TABLE dbo.ClinRelation DROP CONSTRAINT FK_ClinRelation_Person
GO 

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_ClinRelation_PersonId' )
  ALTER TABLE dbo.ClinRelation DROP CONSTRAINT FK_ClinRelation_PersonId
GO 

ALTER TABLE dbo.ClinRelation WITH CHECK ADD CONSTRAINT FK_ClinRelation_PersonId FOREIGN KEY (PersonId)
  REFERENCES dbo.Person (PersonId)
  ON DELETE CASCADE 
  ON UPDATE NO ACTION
GO

-- Add PK_TextItems
ALTER TABLE TextItems ALTER COLUMN TextId INT NOT NULL
GO

IF NOT EXISTS( SELECT * FROM sysobjects WHERE name = 'PK_TextItems' )
  ALTER TABLE dbo.TextItems ADD CONSTRAINT PK_TextItems PRIMARY KEY (TextId)
GO 

IF NOT OBJECT_ID('GBD.GetCaseListDiedHere') IS NULL
  DROP PROCEDURE GBD.GetCaseListDiedHere
GO

IF NOT OBJECT_ID('AddDiabetesPatientsToNdv') IS NULL
  DROP PROCEDURE dbo.AddDiabetesPatientsToNdv
GO

IF EXISTS( SELECT * FROM sys.synonyms  WHERE name='PatientWard' )
  DROP SYNONYM PatientWard
GO

EXECUTE dbo.DbFinalizeUpgrade 6034;
GO

COMMIT TRANSACTION UpgradeTo6034;
GO

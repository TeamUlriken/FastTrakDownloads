SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6057
PRINT 'Starting upgrade to 6057'

-- Purpose of this update:
--   Count usage of populations, to better understand which ones are useful.
--   Add primary key to ColumnCaption table

EXECUTE DbCheckVersion 6056;
EXECUTE DbStartUpgrade 6057;
GO

IF NOT OBJECT_ID( 'dbo.PopulationLog') IS NULL
    DROP TABLE dbo.PopulationLog
GO

CREATE TABLE dbo.PopulationLog ( 
  LogId INT IDENTITY (1,1) NOT NULL, StudyId INT, 
  ProcId INT, ProcDesc VARCHAR( 64 ), MsElapsed DECIMAL(9,2), 
  CreatedAt DATETIME NOT NULL DEFAULT GETDATE(), CreatedBy INT NOT NULL DEFAULT USER_ID() )
GO

ALTER TABLE dbo.PopulationLog ADD CONSTRAINT PK_PopulationLog PRIMARY KEY (LogId)
GO

ALTER TABLE dbo.PopulationLog ADD CONSTRAINT FK_PopulationLog_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.UserList(UserId)
GO

ALTER TABLE dbo.PopulationLog ADD CONSTRAINT FK_PopulationLog_StudyId FOREIGN KEY (StudyId) REFERENCES dbo.Study(StudyId)
GO

IF NOT OBJECT_ID( 'dbo.AddPopulationLog') IS NULL
  DROP PROCEDURE dbo.AddPopulationLog
GO

CREATE PROCEDURE dbo.AddPopulationLog ( @StudyId INT, @ProcId INT, @ProcDesc VARCHAR(64), @MsElapsed DECIMAL(9,2) )
AS
BEGIN
  INSERT INTO dbo.PopulationLog( StudyId, ProcId, ProcDesc, MsElapsed ) 
  VALUES ( @StudyId, @ProcId, @ProcDesc, @MsElapsed );
END;
GO

GRANT EXECUTE ON dbo.AddPopulationLog TO [public] AS [dbo]
GO

GRANT UPDATE ON Report.ColumnCaption TO [superuser] AS [dbo]
GO

ALTER TABLE Report.ColumnCaption ALTER COLUMN CaptionId INT NOT NULL
GO

ALTER TABLE Report.ColumnCaption ADD CONSTRAINT PK_Report_ColumnCaption PRIMARY KEY(CaptionId)
GO

IF NOT EXISTS( SELECT id from sysindexes where name = 'I_ClinEvent_StudyPersonEvent' )
  CREATE UNIQUE INDEX I_ClinEvent_StudyPersonEvent ON dbo.ClinEvent( StudyId,PersonId,EventNum )
GO

IF EXISTS ( SELECT id from sysindexes where name = 'I_ClinEvent_StudyPerson' )
  DROP INDEX ClinEvent.I_ClinEvent_StudyPerson
GO

IF NOT OBJECT_ID('AddFormItem') IS NULL 
  DROP PROCEDURE dbo.AddFormItem
GO

EXECUTE dbo.DbFinalizeUpgrade 6057;
GO

COMMIT TRANSACTION UpgradeTo6057;
GO

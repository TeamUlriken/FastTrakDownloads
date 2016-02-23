SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6009
PRINT 'Starting upgrade to 6009'

DELETE FROM DbUpgradeLog WHERE DbVer > 6008;

EXEC DbCheckVersion 6008;
EXECUTE DbStartUpgrade 6009;
GO

ALTER TABLE LabCode ALTER COLUMN VarName VARCHAR(32)
GO

IF dbo.DbColumnExists('LabCode','LabClassId') = 0 
  ALTER TABLE LabCode ADD LabClassId INT NULL
GO

IF dbo.DbColumnExists('LabCode','Validated') = 1 
  ALTER TABLE LabCode DROP COLUMN Validated
GO

IF dbo.DbColumnExists('LabCode','LCVersion') = 1 
  ALTER TABLE LabCode DROP COLUMN LCVersion
GO

IF dbo.DbColumnExists('LabCode','FriendlyName') = 1 
  ALTER TABLE LabCode DROP COLUMN FriendlyName
GO

IF dbo.DbColumnExists('LabCode','FurstId') = 1 
  ALTER TABLE LabCode DROP COLUMN FurstId
GO

IF NOT OBJECT_ID('FK_LabCode_LabClassId') IS NULL 
 ALTER TABLE dbo.LabCode DROP CONSTRAINT FK_LabCode_LabClassId
GO
 
ALTER TABLE dbo.LabCode ADD CONSTRAINT FK_LabCode_LabClassId FOREIGN KEY ( LabClassId ) REFERENCES
  dbo.LabClass ( LabClassId )
GO

IF NOT OBJECT_ID('UpdateLabClassId') IS NULL DROP PROCEDURE UpdateLabClassId
GO

CREATE PROCEDURE dbo.UpdateLabClassId( @LabCodeId INT, @LabClassId INT )
AS
BEGIN
  IF @LabClassId = 0 SET @LabClassId=NULL;
  UPDATE LabCode SET LabClassId=NULLIF(@LabClassId,0) WHERE LabCodeId=@LabCodeId;
  -- Copy fields
  UPDATE LabCode SET VarName=( SELECT VarName FROM dbo.LabClass WHERE LabClassId=LabCode.LabClassId )
    WHERE LabCodeId=@LabCodeId;
  UPDATE LabCode SET LoincCode=( SELECT LoincCode FROM dbo.LabClass WHERE LabClassId=LabCode.LabClassId )
    WHERE LabCodeId=@LabCodeId;
END
GO

ALTER VIEW Report.LabTestOverview (LabCodeId, LabName, FriendlyName, FurstId, LabCount, MinResult, MaxResult, AvgResult) 
AS
SELECT
    lc.LabCodeId,lc.LabName,cl.FriendlyName,cl.FurstId, count(*) as LabCount, 
      min(ld.NumResult),max(ld.NumResult),avg(ld.NumResult)                                           
  FROM LabCode lc 
  JOIN LabData ld ON ld.LabCodeId=lc.LabCodeId
  LEFT OUTER JOIN LabClass cl ON cl.LabClassId=lc.LabClassId
  GROUP BY
    lc.LabCodeId,lc.LabName,cl.FriendlyName,cl.FurstId
GO

ALTER VIEW Report.LabClassOverview (FriendlyName, FurstId, LoincCode, LabCount) 
AS
SELECT ISNULL(cl.FriendlyName,'Uklassifiserte prøver') as FriendlyName,cl.FurstId,cl.Loinc as LoincCode, count(*) as LabCount                                           
  FROM LabCode lc 
  JOIN LabData ld ON ld.LabCodeId=lc.LabCodeId
  LEFT OUTER JOIN LabClass cl ON cl.LabClassId=lc.LabClassId
  GROUP BY cl.FriendlyName,cl.FurstId,cl.Loinc
GO

GRANT EXECUTE ON dbo.UpdateLabClassId TO [public] AS [dbo]
GO

EXECUTE DbFinalizeUpgrade 6009;
GO

COMMIT TRANSACTION UpgradeTo6009;
GO

SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6007
PRINT 'Starting upgrade to 6007'

DELETE FROM DbUpgradeLog WHERE DbVer > 6006;

EXEC DbCheckVersion 6006;
EXECUTE DbStartUpgrade 6007;
GO

IF NOT OBJECT_ID('FK_LabCode_LabClassId') IS NULL
  ALTER TABLE LabCode DROP CONSTRAINT FK_LabCode_LabClassId
GO

IF NOT OBJECT_ID('LabClass') IS NULL
  DROP TABLE dbo.LabClass
GO

CREATE TABLE dbo.LabClass (
    LabClassId Int NOT NULL,
    FriendlyName VarChar(128) NOT NULL,
    VarName VarChar(64),
    IncludeRegEx VarChar(MAX) NOT NULL,
    ExcludeRegEx VarChar(MAX),
    Loinc VarChar(8),
    FurstId Int, 
    ItemId Int,
    UnitStr VarChar(24),
    MinValid Decimal(12, 2),
    MaxValid Decimal(12, 2),
    LastUpdate DateTime NOT NULL,
    CONSTRAINT PK_LabClass PRIMARY KEY CLUSTERED (
      LabClassId
    )
)
GO

CREATE UNIQUE INDEX IDX_LabClass_VarName ON dbo.LabClass( VarName)
GO

EXECUTE DbFinalizeUpgrade 6007;
GO

COMMIT TRANSACTION UpgradeTo6007;
GO

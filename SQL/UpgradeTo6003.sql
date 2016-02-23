SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6003
PRINT 'Starting upgrade to 6003'

DELETE FROM DbUpgradeLog WHERE DbVer > 6002;

EXEC DbCheckVersion 6002;
EXECUTE DbStartUpgrade 6003;
GO

DELETE FROM MetaFormItem WHERE 1=1
DELETE From MetaFormPage WHERE 1=1
GO

IF dbo.DbIndexExists( 'MetaFormPage', 'IDX_MetaFormPage_FormId_PageNumber' ) = 1
  DROP INDEX MetaFormPage.IDX_MetaFormPage_FormId_PageNumber
GO

IF dbo.DbIndexExists( 'MetaFormPage', 'I_MetaFormPage_FormId_PageNumber' ) = 1
  DROP INDEX MetaFormPage.I_MetaFormPage_FormId_PageNumber
GO

IF dbo.DbIndexExists( 'MetaFormPage', 'I_MetaFormPage_FormId' ) = 1
  DROP INDEX MetaFormPage.I_MetaFormPage_FormId
GO

CREATE UNIQUE INDEX I_MetaFormPage_FormId_PageNumber ON MetaFormPage( FormId, PageNumber );
GO

EXECUTE DbFinalizeUpgrade 6003;
GO

COMMIT TRANSACTION UpgradeTo6003;
GO



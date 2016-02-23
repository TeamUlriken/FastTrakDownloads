SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6004
PRINT 'Starting upgrade to 6004'

DELETE FROM DbUpgradeLog WHERE DbVer > 6003;

EXEC DbCheckVersion 6003;
EXECUTE DbStartUpgrade 6004;
GO

IF dbo.DbIndexExists( 'MetaFormPage', 'IDX_MetaFormPage_FormId_PageNumber' ) = 1
  DROP INDEX MetaFormPage.IDX_MetaFormPage_FormId_PageNumber
GO

IF dbo.DbIndexExists( 'MetaFormPage', 'I_MetaFormPage_FormId' ) = 1
  DROP INDEX MetaFormPage.I_MetaFormPage_FormId
GO

IF dbo.DbIndexExists( 'MetaFormPage', 'I_MetaFormPage_FormId_PageNumber' ) = 1
  DROP INDEX MetaFormPage.I_MetaFormPage_FormId_PageNumber
GO

CREATE INDEX I_MetaFormPage_FormId_PageNumber ON MetaFormPage( FormId, PageNumber );
GO

IF dbo.DbIndexExists( 'MetaFormItem', 'I_MetaFormItem_FormItem' ) = 1
  DROP INDEX MetaFormItem.I_MetaFormItem_FormItem
GO

CREATE INDEX I_MetaFormItem_FormItem
 ON dbo.MetaFormItem(FormId, ItemId)
GO

GRANT EXECUTE ON dbo.ReportClinFormAuditTrail TO [public] AS [dbo]
GO

EXECUTE DbFinalizeUpgrade 6004;
GO

COMMIT TRANSACTION UpgradeTo6004;
GO



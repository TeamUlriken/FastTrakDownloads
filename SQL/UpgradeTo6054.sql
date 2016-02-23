SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6054
PRINT 'Starting upgrade to 6054'

-- Purpose of this update:
--   Add labels for combination of form/variable for easier export to SPSS or Excel
--   Needed in V-REX study, VOSSBAR study, FettVest study etc.

DELETE FROM DbUpgradeLog
WHERE  DbVer > 6053;

EXEC DbCheckVersion 6053;
EXECUTE DbStartUpgrade 6054;
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'Label' ) = 0
  ALTER TABLE dbo.MetaFormItem ADD Label VARCHAR(32)
GO

-- These are just examples, real data will be downloaded from metadata server

UPDATE dbo.MetaFormItem SET Label='EQ5D_MOB_1Y' WHERE FormId=779 AND ItemId=8653
UPDATE dbo.MetaFormItem SET Label='EQ5D_SEL_1Y' WHERE FormId=779 AND ItemId=8654
UPDATE dbo.MetaFormItem SET Label='EQ5D_ACT_1Y' WHERE FormId=779 AND ItemId=8655
UPDATE dbo.MetaFormItem SET Label='EQ5D_PAI_1Y' WHERE FormId=779 AND ItemId=8656
UPDATE dbo.MetaFormItem SET Label='EQ5D_ANX_1Y' WHERE FormId=779 AND ItemId=8657
GO

UPDATE dbo.MetaFormItem SET Label='EQ5D_MOB_INC' WHERE FormId=756 AND ItemId=8653
UPDATE dbo.MetaFormItem SET Label='EQ5D_SEL_INC' WHERE FormId=756 AND ItemId=8654
UPDATE dbo.MetaFormItem SET Label='EQ5D_ACT_INC' WHERE FormId=756 AND ItemId=8655
UPDATE dbo.MetaFormItem SET Label='EQ5D_PAI_INC' WHERE FormId=756 AND ItemId=8656
UPDATE dbo.MetaFormItem SET Label='EQ5D_ANX_INC' WHERE FormId=756 AND ItemId=8657
GO

ALTER PROCEDURE dbo.LoadClinForm( @ClinFormId INT ) AS
BEGIN
  SELECT e.EventNum, cf.FormId, e.EventId, e.EventTime, mf.FormTitle, mf.FormName,
      cf.ClinFormId, cf.FormStatus, cf.FormComplete, cf.Comment, cf.CachedText,
      mfs.StatusDesc, cf.CreatedAt, cf.SignedAt,
      up1.Signature AS CreatedBySign, cf.CreatedBy, ul1.ProfId AS CreatedByProfId,
      up2.Signature AS SignedBySign, cf.SignedBy, ul2.ProfId AS SignedByProfId
  FROM dbo.ClinEvent e
    JOIN dbo.ClinForm cf on cf.EventId=e.EventId
    JOIN dbo.MetaFormStatus mfs ON mfs.FormStatus=cf.FormStatus
    LEFT OUTER JOIN dbo.MetaForm mf on mf.FormId=cf.FormId
    LEFT OUTER JOIN dbo.UserList ul1 ON ul1.UserId=cf.CreatedBy
    LEFT OUTER JOIN dbo.Person up1 ON up1.PersonId=ul1.PersonId
    LEFT OUTER JOIN dbo.UserList ul2 ON ul2.UserId=cf.SignedBy
    LEFT OUTER JOIN dbo.Person up2 ON up2.PersonId=ul2.PersonId
    WHERE ClinFormId=@ClinFormId;
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6054;
GO

COMMIT TRANSACTION UpgradeTo6054;
GO

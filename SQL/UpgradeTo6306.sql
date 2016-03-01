SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6306
GO

PRINT 'Overall purpose: Workaround for SQL OLE DB Provider bug (picking wrong schema).'

--  CREATE procedure CRF.GetClinFormList to replace CRF.GetClinForms.
--  DROP procedure CRF.GetClinFormList.
--  CREATE synonym CRF.GetClinForms for CRF.GetClinFormList.
--  ALTER procedure dbo.GetClinForms to use procedures in CRF schema.

EXECUTE dbo.DbStartUpgrade 6305, 6306;
GO

-- -----------------------------------------------------------------------------
-- END Start sequence. Copy statements above this to subsequent upgrade scripts.
-- -----------------------------------------------------------------------------

PRINT '--  CREATE procedure CRF.GetClinFormList to replace CRF.GetClinForms.'

IF NOT OBJECT_ID('CRF.GetClinFormList','P' ) IS NULL 
  DROP PROCEDURE CRF.GetClinFormList 
GO

CREATE PROCEDURE CRF.GetClinFormList( @StudyId INT, @PersonId INT, @IncludeArchived BIT ) AS
BEGIN
  -- Log reads
  INSERT INTO dbo.CaseLog (PersonId,LogType,LogText)
  VALUES( @PersonId,'LESE','Journal lest av ' + USER_NAME() );
  --- Get forms
  SELECT ce.EventNum,cf.FormId,ce.EventId,ce.EventTime,mf.FormTitle,mf.FormName,
    cf.ClinFormId,cf.FormStatus,cf.FormComplete,cf.Comment,cf.CachedText,
    mfs.StatusDesc,cf.CreatedAt,cf.SignedAt, cf.Archived,
    up1.Signature AS CreatedBySign, ul1.ProfId AS CreatedByProfId, cf.CreatedBy,
    up2.Signature AS SignedBySign, ul2.ProfId AS SignedByProfId, cf.SignedBy
  FROM dbo.ClinEvent ce
    JOIN dbo.ClinForm cf on cf.EventId=ce.EventId AND ( cf.DeletedAt IS NULL )
    JOIN dbo.MetaFormStatus mfs ON mfs.FormStatus=cf.FormStatus
    JOIN dbo.MetaForm mf on mf.FormId=cf.FormId
    JOIN dbo.MetaStudyForm msf ON msf.FormId=cf.FormId AND msf.StudyId = @StudyId
    LEFT JOIN dbo.UserList ul1 ON ul1.UserId=cf.CreatedBy
    LEFT JOIN dbo.UserList ul2 ON ul2.UserId=cf.SignedBy
    LEFT JOIN dbo.Person up1 ON up1.PersonId=ul1.PersonId
    LEFT JOIN dbo.Person up2 ON up2.PersonId=ul2.PersonId
  WHERE ( ce.PersonId = @PersonId ) AND ( ( cf.Archived = 0 ) OR ( @IncludeArchived = 1 ) );
END
GO

PRINT '--  DROP procedure CRF.GetClinFormList.'

IF NOT OBJECT_ID('CRF.GetClinForms', 'P') IS NULL
  DROP PROCEDURE CRF.GetClinForms
GO

IF NOT OBJECT_ID('CRF.GetClinForms', 'SN') IS NULL
  DROP SYNONYM CRF.GetClinForms
GO

PRINT '--  CREATE synonym CRF.GetClinForms for CRF.GetClinFormList.'

CREATE SYNONYM CRF.GetClinForms FOR CRF.GetClinFormList;
GO

GRANT EXECUTE ON CRF.GetClinFormList TO [public] AS [dbo];
GRANT EXECUTE ON CRF.GetClinForms TO [public] AS [dbo];
GO

PRINT '--  ALTER procedure dbo.GetClinForms to use procedures in CRF schema.'
GO

ALTER PROCEDURE dbo.GetClinForms (@StudyId INT, @PersonId INT, @ClinFormId INT = NULL) AS
BEGIN
  SET NOCOUNT ON;
  IF @ClinFormId IS NULL
    EXEC CRF.GetClinFormList @StudyId, @PersonId, 1
  ELSE
    EXEC CRF.GetClinForm @ClinFormId
END
GO

-- -----------------------------------------------------------------------------
-- Finalization sequence (copy to subsequent upgrade scripts)
-- -----------------------------------------------------------------------------

EXECUTE dbo.DbFinalizeUpgrade 6306;
GO

COMMIT TRANSACTION UpgradeTo6306;
GO
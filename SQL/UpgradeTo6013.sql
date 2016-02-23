SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6013
PRINT 'Starting upgrade to 6013'

DELETE FROM DbUpgradeLog WHERE DbVer > 6012;

EXEC DbCheckVersion 6012;
EXECUTE DbStartUpgrade 6013;
GO

IF NOT OBJECT_ID('CRF.GetClinData') IS NULL DROP PROCEDURE CRF.GetClinData
GO

CREATE PROCEDURE CRF.GetClinData( @StudyId INT, @PersonId INT ) AS
BEGIN
    SELECT 
      co.RowId,e.EventId,e.EventNum,e.EventTime,mi.ItemId,mi.VarName,co.Quantity,co.DTVal,
      co.EnumVal,co.TextVal,co.Locked,co.ChangeCount
    FROM dbo.ClinDataPoint co
      JOIN dbo.ClinEvent e ON e.EventId=co.EventId 
      JOIN dbo.MetaItem mi ON mi.ItemId=co.ItemId
    WHERE e.PersonId=@PersonId
    ORDER BY e.EventNum,e.EventId;
END
GO

GRANT EXECUTE ON CRF.GetClinData TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('CRF.ClinData') IS NULL DROP VIEW CRF.ClinData
GO

CREATE VIEW CRF.ClinData AS
    SELECT 
      co.RowId,e.StudyId,e.PersonId,e.EventId,e.EventNum,e.EventTime,co.ItemId,mi.VarName,co.Quantity,co.DTVal,
      co.EnumVal,co.TextVal,co.Locked,co.ChangeCount
    FROM dbo.ClinDataPoint co
      JOIN dbo.ClinEvent e ON e.EventId=co.EventId 
      JOIN dbo.MetaItem mi ON mi.ItemId=co.ItemId
GO

IF NOT OBJECT_ID('CRF.DeleteClinForm') IS NULL DROP PROCEDURE CRF.DeleteClinForm
GO

CREATE PROCEDURE CRF.DeleteClinForm( @ClinFormId INT ) AS
BEGIN
  DECLARE @FormId INT;
  DECLARE @EventId INT;  
  DECLARE @EventNum INT; 
  -- Find relevant form info                                                  
  SELECT @FormId = cf.FormId, @EventId=cf.EventId, @EventNum = ce.EventNum 
    FROM dbo.ClinForm cf JOIN dbo.ClinEvent ce ON ce.EventId=cf.EventId 
    WHERE ClinFormId=@ClinFormId;         
  -- Delete 
  DELETE FROM dbo.ClinDatapoint WHERE TouchId IN (SELECT TouchId FROM dbo.ClinTouch WHERE EventId = @EventId AND FormId=@FormId)
  DELETE FROM dbo.ClinFormLog WHERE ClinFormId=@ClinFormId;
  DELETE FROM dbo.ClinForm WHERE ClinFormId=@ClinFormId;
END
GO

GRANT EXECUTE ON CRF.DeleteClinForm TO [Journalansvarlig] AS [dbo]
GO

IF NOT OBJECT_ID('CRF.UpdateClinForm' ) IS NULL
  DROP PROCEDURE CRF.UpdateClinForm
GO

CREATE PROCEDURE CRF.UpdateClinForm( @ClinFormId INT, @FormComment VARCHAR(MAX), @FormStatus CHAR(1), @FormComplete TINYINT )
AS
BEGIN
  DECLARE @StudyId INT;
  DECLARE @PersonId INT;
  DECLARE @EventId INT;
  DECLARE @OldFormStatus CHAR(1);
  DECLARE @OldFormComplete TINYINT;
  SELECT @OldFormStatus = FormStatus, @OldFormComplete = FormComplete, @EventId=EventId
  FROM dbo.ClinForm WHERE ClinFormId=@ClinFormId;
  IF ( @OldFormStatus = 'L' ) 
    RAISERROR ('Skjemaet signert og kan ikke endre status', 16, 1 )
  ELSE
  BEGIN
    -- Update form properties
    UPDATE dbo.ClinForm 
    SET FormComplete=@FormComplete,FormStatus=@FormStatus,Comment=@FormComment 
    WHERE ClinFormId=@ClinFormId;
    -- Sign for if status is locked
    IF @FormStatus='L' UPDATE dbo.ClinForm SET SignedAt=getdate(),SignedBy=user_id() WHERE ClinFormId=@ClinFormId; 
    SELECT @StudyId=StudyId,@PersonId=PersonId FROM dbo.ClinEvent WHERE EventId=@EventId;
    -- Find study and person, needed to update StudCase
    UPDATE dbo.StudCase SET LastWrite = getdate() WHERE StudyId=@StudyId AND PersonId=@PersonId;
  END;
END
GO

GRANT EXECUTE ON CRF.UpdateClinForm TO [public] AS [dbo]
GO

EXECUTE DbFinalizeUpgrade 6013;
GO

COMMIT TRANSACTION UpgradeTo6013;
GO


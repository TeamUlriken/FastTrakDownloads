BEGIN TRANSACTION UpgradeTo6041
PRINT 'Starting upgrade to 6041'

-- Purpose of this update
-- To sign all unsigned variables on a form using ItemId instead of TouchId (better for 5.x application with v6xxx database).
-- When using application v6, the individual datapoints are also signed directly when they are saved with CRF.AddClinDatapoint.
-- Unsigning a form 

DELETE FROM DbUpgradeLog WHERE DbVer > 6040;

EXEC DbCheckVersion 6040;
EXECUTE DbStartUpgrade 6041;
GO

IF NOT OBJECT_ID('CRF.UpdateClinFormSignItems') IS NULL DROP PROCEDURE CRF.UpdateClinFormSignItems
GO

CREATE PROCEDURE CRF.UpdateClinFormSignItems( @ClinFormId INT )
AS
BEGIN
  DECLARE @EventId INT;
  DECLARE @FormId INT;
  SELECT @EventId = EventId, @FormId=FormId FROM dbo.ClinForm WHERE ClinFormId=@ClinFormId;
  SELECT ItemId INTO #itemList FROM dbo.MetaFormItem WHERE FormId=@FormId;
  -- Sign regular items
  UPDATE dbo.ClinDatapoint SET LockedAt=GETDATE(),LockedBy=USER_ID(),Locked=1
  WHERE EventId=@EventId AND LockedBy IS NULL AND ItemId IN (SELECT ItemId FROM #itemList );
  -- Sign threaded items
  UPDATE dbo.ClinThreadData SET LockedAt=GETDATE(),LockedBy=USER_ID(),Locked=1
  WHERE EventId=@EventId AND LockedBy IS NULL AND ItemId IN (SELECT ItemId from #itemList);
END
GO

-- Only allow execute of UpdateClinFormSignItems inside other procedures?

GRANT EXECUTE ON CRF.UpdateClinFormSignItems TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('CRF.UpdateClinFormUnsignItems' ) IS NULL DROP PROCEDURE CRF.UpdateClinFormUnsignItems
GO

CREATE PROCEDURE CRF.UpdateClinFormUnsignItems( @ClinFormId INT )
AS
BEGIN
  DECLARE @EventId INT; 
  DECLARE @FormId INT;
  SELECT @EventId = EventId, @FormId=FormId FROM dbo.ClinForm WHERE ClinFormId=@ClinFormId;
  -- Find items on this form, but not on other signed forms  
  SELECT ItemId INTO #itemList 
  FROM dbo.MetaFormItem WHERE FormId=@FormId
  EXCEPT
    SELECT ItemId FROM dbo.MetaFormItem mfi
    JOIN dbo.ClinForm cf ON cf.FormId=mfi.FormId
    WHERE cf.EventId = @EventId AND cf.FormStatus='L'
    AND cf.ClinFormId <> @ClinFormId;          
  -- Unsign regular items
  UPDATE dbo.ClinDatapoint SET Locked=0, LockedAt=NULL, LockedBy=NULL
  WHERE EventId = @EventId AND Locked<>0 AND ItemId IN ( SELECT ItemId FROM #itemList );
  -- Unsign threaded items
  UPDATE dbo.ClinThreadData SET Locked=0, LockedAt=NULL,LockedBy=NULL
  WHERE EventId=@EventId AND Locked<>0 AND ItemId IN (SELECT ItemId from #itemList);
END
GO

-- Only allow execute of UpdateClinFormUnsignItems inside other procedures?

GRANT EXECUTE ON CRF.UpdateClinFormUnsignItems TO [public] AS [dbo]
GO

ALTER PROCEDURE dbo.UpdateFormSignClinId( @ClinFormId INT ) AS
BEGIN
  -- Procedure has a non-conventional name. It is used in v5, can be removed for v6.
  DECLARE @MsgText VARCHAR(512);
  UPDATE dbo.ClinForm SET SignedAt=GETDATE(),SignedBy=USER_ID(),FormStatus='L'
    WHERE ClinFormId=@ClinFormId AND (SignedBy IS NULL );
  IF @@ROWCOUNT=0
  BEGIN
    SET @MsgText = dbo.GetTextItem( 'UpdateFormSignClinId','Failed' );
    RAISERROR (@MsgText,16,1 );
    RETURN -1;
  END
  ELSE
    EXEC CRF.UpdateClinFormSignItems @ClinFormId;              
END
GO

ALTER PROCEDURE CRF.UpdateClinForm( @ClinFormId INT, @FormComment VARCHAR(MAX), @FormStatus CHAR(1), @FormComplete TINYINT )
AS
BEGIN
  DECLARE @StudyId INT;
  DECLARE @PersonId INT;
  DECLARE @OldFormStatus CHAR(1);
  -- Find some existing details about the form and the patient
  SELECT @PersonId=ce.PersonId, @OldFormStatus = cf.FormStatus 
  FROM dbo.ClinForm cf 
  JOIN dbo.ClinEvent ce ON ce.EventId=cf.EventId 
  WHERE ClinFormId=@ClinFormId;
  -- Make sure it is unlocked
  IF ( @OldFormStatus = 'L' ) 
    RAISERROR ('This form is already signed, updates are not allowed.', 16, 1 )
  ELSE
  BEGIN
    -- Update form properties
    UPDATE dbo.ClinForm SET FormComplete=@FormComplete,FormStatus=@FormStatus,Comment=@FormComment 
    WHERE ClinFormId=@ClinFormId;
    IF @FormStatus='L' 
    BEGIN
      -- Sign all unsigned variables that appear on this event/form
      EXEC CRF.UpdateClinFormSignItems @ClinFormId;
      -- Sign form if status is locked
      UPDATE dbo.ClinForm SET SignedAt=GETDATE(),SignedBy=USER_ID() WHERE ClinFormId=@ClinFormId; 
    END; 
    -- Update StudCase (forms may be shared in more than one study, so write to all studies)
    UPDATE dbo.StudCase SET LastWrite = getdate() WHERE PersonId=@PersonId;
  END;
END
GO

IF NOT OBJECT_ID('dbo.UpdateClinFormUnsign','P') IS NULL DROP PROCEDURE dbo.UpdateClinFormUnsign
GO

IF NOT OBJECT_ID('dbo.UpdateClinFormUnsign','SN') IS NULL DROP SYNONYM dbo.UpdateClinFormUnsign
GO

IF NOT OBJECT_ID('CRF.UpdateClinFormUnsign','P') IS NULL DROP PROCEDURE CRF.UpdateClinFormUnsign
GO

CREATE PROCEDURE CRF.UpdateClinFormUnsign( @ClinFormId INT ) AS
BEGIN
  DECLARE @CanUnsign INT;
  DECLARE @MessageText VARCHAR(MAX);    
  -- Make sure we can unsign this form
  EXEC dbo.CanUnsignForm @ClinFormId, @CanUnsign OUTPUT, @MessageText OUTPUT;
  IF @CanUnsign > 0                                                
  BEGIN                                          
    -- Unsign the form itself 
    UPDATE dbo.ClinForm SET SignedAt=NULL,SignedBy=NULL,FormStatus='I' WHERE ClinFormId=@ClinFormId;
    -- Unsign standard variables
    EXEC CRF.UpdateClinFormUnsignItems @ClinFormId
    RETURN 1;
  END
  ELSE
  BEGIN  
    RAISERROR( @MessageText, 16, 1 )
    RETURN -2;
  END;
END
GO

GRANT EXECUTE ON CRF.UpdateClinFormUnsign TO [public] AS [dbo]
GO

CREATE SYNONYM dbo.UpdateClinFormUnsign FOR CRF.UpdateClinFormUnsign
GO

GRANT EXECUTE ON dbo.UpdateClinFormUnsign TO [public] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6041;
GO

COMMIT TRANSACTION UpgradeTo6041;
GO


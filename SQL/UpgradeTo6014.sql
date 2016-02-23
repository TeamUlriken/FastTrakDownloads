SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6014
PRINT 'Starting upgrade to 6014'

DELETE FROM DbUpgradeLog WHERE DbVer > 6013;

EXEC DbCheckVersion 6013;
EXECUTE DbStartUpgrade 6014;
GO

IF EXISTS ( SELECT id FROM sysobjects WHERE name='T_ClinDatapoint_Update' ) 
  DROP TRIGGER dbo.T_ClinDatapoint_Update
GO

CREATE TRIGGER dbo.T_ClinDatapoint_Update ON dbo.ClinDatapoint
AFTER UPDATE AS 
BEGIN                    
   INSERT INTO dbo.ClinLog( RowId, TouchId, ObsDate, Quantity, DTVal, EnumVal, TextVal )
   SELECT o.RowId,o.TouchId,o.ObsDate,o.Quantity,o.DTVal,o.EnumVal,o.TextVal 
   FROM deleted o
END
GO

IF NOT OBJECT_ID('CRF.AddClinDatapoint') IS NULL DROP PROCEDURE CRF.AddClinDatapoint
GO

CREATE PROCEDURE CRF.AddClinDatapoint ( 
  @TouchId INT, @EventId INT, @ItemId INT, @Quantity decimal(18,4),
  @DTVal DateTime, @EnumVal int, @TextVal VARCHAR(MAX), @Locked INT )
AS
BEGIN
  DECLARE @RowId INT;
  DECLARE @ChangeCount INT;
  DECLARE @OldLocked INT;  
  DECLARE @OldChangeCount INT;
  DECLARE @OldQuantity DECIMAL(18,4);
  DECLARE @OldEnumVal INT;
  DECLARE @OldTextVal VARCHAR(MAX);
  DECLARE @OldDTVal DateTime;    
  
  -- Find the row and load data
  SELECT 
    @RowId=RowId, @OldLocked=Locked, @OldChangeCount=ChangeCount, @OldQuantity=Quantity, 
    @OldEnumVal=EnumVal, @OldDTVal=DTVal, @OldTextVal=TextVal 
    FROM dbo.ClinDatapoint WHERE EventId=@EventId AND ItemId=@ItemId;
  
  IF @RowId IS NULL 
  BEGIN          
    -- Have to create it
    INSERT INTO dbo.ClinDatapoint (TouchId,ItemId,Quantity,DTVal,EnumVal,TextVal,EventId,Locked)
      VALUES (@TouchId,@ItemId,@Quantity,@DTVal,@EnumVal,@TextVal,@EventId,@Locked);
    SET @RowId = SCOPE_IDENTITY();
  END
  ELSE IF @OldLocked > 0
  BEGIN
    RAISERROR( 'Could not save data.  This row is already locked for updates.', 16, 1 );
    RETURN -2;
  END
  ELSE 
  BEGIN                   
    SET @ChangeCount = @OldChangeCount;
    -- Increase update counter if necessary
    IF ( @Quantity <> @OldQuantity ) OR ( @DTVal <> @OldDTVal ) OR ( @EnumVal <> @OldEnumVal ) OR ( @TextVal <> @OldTextVal )
      OR ( @Quantity IS NULL AND NOT @OldQuantity IS NULL ) OR ( @OldQuantity IS NULL AND NOT @Quantity IS NULL )
      OR ( @EnumVal IS NULL AND NOT @OldEnumVal IS NULL ) OR ( @OldEnumVal IS NULL AND NOT @EnumVal IS NULL )
      OR ( @DTVal IS NULL AND NOT @OldDTVal IS NULL ) OR ( @OldDTVal IS NULL AND NOT @DTVal IS NULL )
      OR ( @TextVal IS NULL AND NOT @OldTextVal IS NULL ) OR ( @OldTextVal IS NULL AND NOT @TextVal IS NULL )
        SET @ChangeCount = @ChangeCount + 1;
    IF ( @ChangeCount <> @OldChangeCount )
    BEGIN
      -- Update if changed, trigger will do the logging                                                           
      UPDATE dbo.ClinDatapoint SET 
        Quantity=@Quantity, DTVal=@DTVal, EnumVal=@EnumVal, TextVal=@TextVal,
        ObsDate=GetDate(), TouchId=@TouchId, ChangeCount=@ChangeCount
      WHERE RowId=@RowId;
    END; 
    IF ( @Locked <> @OldLocked ) UPDATE dbo.ClinDatapoint SET Locked=@Locked WHERE RowId=@RowId;
  END;
  SELECT RowId,Locked,ChangeCount FROM dbo.ClinDatapoint WHERE RowId=@RowId;
END
GO

GRANT EXECUTE ON CRF.AddClinDatapoint TO [public] AS [dbo]
GO

IF EXISTS ( SELECT id FROM sysobjects WHERE name='C_ClinLog_Timing' ) 
  ALTER TABLE dbo.ClinLog DROP CONSTRAINT C_ClinLog_Timing
GO

ALTER TABLE dbo.ClinLog WITH CHECK ADD CONSTRAINT C_ClinLog_Timing CHECK ([ChangedAt] >= [ObsDate])
GO

ALTER PROCEDURE dbo.AddClinData ( @TouchId INT, @VarName varchar(24), @Quantity decimal(18,4),
  @DTVal DateTime,@EnumVal int, @TextVal VARCHAR(MAX) )
AS
BEGIN
  DECLARE @OldTouchId INT;
  DECLARE @EventId INT; 
  DECLARE @ItemId INT;
  DECLARE @RowId INT;
  DECLARE @Locked INT;  
  DECLARE @CmpResult INT;
  DECLARE @ChangeCount INT;
  DECLARE @WhatHappened VARCHAR(64);
  SET NOCOUNT ON;
  /* Make sure the TouchId is valid, matches a session, and find the matching EventId */
  SELECT @EventId=EventId FROM ClinTouch t
    JOIN dbo.UserLog u on (u.SessId=t.SessId ) AND ( u.ClosedAt IS NULL ) AND (u.UserId=USER_ID())
    WHERE (t.TouchId=@TouchId) AND (t.CreatedBy=USER_ID())
  IF @EventId IS NULL
  BEGIN
    RAISERROR( 'Invalid SessId, UserId or TouchId.', 16, 1 );
    RETURN -1;
  END
  ELSE 
  BEGIN 
    SELECT @ItemId = ItemId FROM dbo.MetaItem WHERE VarName=@VarName;
    /* We are allowed to update this data */
    SELECT @OldTouchId=TouchId,@RowId=RowId,@Locked=Locked,@ChangeCount=ChangeCount
      FROM dbo.ClinDatapoint WHERE EventId=@EventId AND ItemId=@ItemId;
    IF @RowId IS NULL 
    BEGIN
      /* Data does not exist, must create it */
      INSERT INTO dbo.ClinDatapoint (TouchId,ItemId,Quantity,DTVal,EnumVal,TextVal,EventId)
        VALUES (@TouchId,@ItemId,@Quantity,@DTVal,@EnumVal,@TextVal,@EventId)
      SET @RowId = SCOPE_IDENTITY();
      SET @WhatHappened='Data inserted';
    END
    ELSE IF @Locked <> 0
    BEGIN
      RAISERROR( 'Could not save data.  This row is signed.', 16, 1 );
      RETURN -2;
    END
    ELSE BEGIN                                                                
      SET @CmpResult = dbo.SameData( @RowId,@Quantity,@DTVal,@EnumVal,@TextVal );
      IF @CmpResult=-1 
      BEGIN   
        /* The old data was empty, do not log any changes */
        UPDATE ClinDatapoint SET
          Quantity=@Quantity,DTVal=@DTVal,EnumVal=@EnumVal,TextVal=@TextVal,
          ObsDate=GetDate(),TouchId=@TouchId
        WHERE RowId=@RowId;
        SET @WhatHappened = 'Old data was empty';
      END 
      ELSE IF @CmpResult = 0 
      BEGIN   
        /* Old data was different, update log if different TouchId */
        IF @OldTouchId=@TouchId
          SET @WhatHappened = 'Data changed, Same TouchId'
        ELSE BEGIN  
          SET @ChangeCount = @ChangeCount + 1;
          SET @WhatHappened = 'Data changed, Updated ClinLog with trigger';
        END;
        /* Increment change count and save data*/
        UPDATE dbo.ClinDatapoint SET
          Quantity=@Quantity,DTVal=@DTVal,EnumVal=@EnumVal,TextVal=@TextVal,
          ObsDate=GetDate(),TouchId=@TouchId,ChangeCount=@ChangeCount
        WHERE RowId=@RowId;
      END
      ELSE IF @CmpResult = 1
        SET @WhatHappened = 'Data was unchanged, not saved.'
      ELSE
        SET @WhatHappened = 'Invalid compare result, not saved';
    END;
    SELECT @RowId AS RowId,0 AS Locked,@WhatHappened AS MsgResult;
  END;
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6014;
GO

COMMIT TRANSACTION UpgradeTo6014;
GO


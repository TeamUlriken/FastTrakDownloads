SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

IF NOT EXISTS ( SELECT UserId FROM UserList WHERE UserId=USER_ID() )
  INSERT INTO UserList (UserId) VALUES( USER_ID() )
GO

ALTER AUTHORIZATION ON SCHEMA::GBD TO [dbo] 
ALTER AUTHORIZATION ON SCHEMA::NDV TO [dbo]
GO 

BEGIN TRANSACTION UpgradeTo530;
PRINT 'Starting upgrade to 530'

EXEC DbCheckVersion 521;       
EXECUTE DbStartUpgrade 530;
GO

-- Drop schemabound views, or there will be errors later on

IF NOT OBJECT_ID('QA.InvalidVariablesInClinObservation') IS NULL
  DROP VIEW QA.InvalidVariablesInClinObservation
GO

IF NOT OBJECT_ID('NDV.FormData') IS NULL
  DROP VIEW NDV.FormData
GO

IF NOT OBJECT_ID('dbo.ClinData') IS NULL
  DROP VIEW dbo.ClinData
GO

IF NOT OBJECT_ID('GBD.Tvangsvedtak') IS NULL
  DROP VIEW GBD.Tvangsvedtak
GO

-- Increase size of VarName, must be done before ClinObservation view is created

IF dbo.DbIndexExists( 'MetaItem', 'I_MetaItem_VarName' ) = 1
  DROP INDEX MetaItem.I_MetaItem_VarName
GO

ALTER TABLE MetaItem ALTER COLUMN VarName VARCHAR(64) NOT NULL
GO

CREATE INDEX I_MetaItem_VarName ON MetaItem(VarName)
GO

-- Add ItemId to ClinObservation table and populate it

IF dbo.DbColumnExists( 'ClinObservation', 'ItemId' ) = 0
  ALTER TABLE ClinObservation ADD ItemId INT NULL
GO

UPDATE ClinObservation SET ItemId=( SELECT ItemId FROM MetaItem WHERE VarName=ClinObservation.VarName ) 
  WHERE ItemId IS NULL
GO

-- Now, make sure all observations have matching ItemId

ALTER TABLE ClinObservation ALTER COLUMN ItemId INT NOT NULL
GO

-- Rename table, will create a warning, but no error

EXEC sp_rename 'ClinObservation','ClinDataPoint'
GO

IF dbo.DbColumnExists( 'ClinDatapoint', 'guid' ) = 0
  ALTER TABLE dbo.ClinDatapoint ADD guid uniqueidentifier NOT NULL DEFAULT newid()
GO

-- Make sure only valid variables can be stored by adding foreign key 

ALTER TABLE ClinDatapoint ADD CONSTRAINT FK_ClinDatapoint_MetaItem FOREIGN KEY (ItemId) REFERENCES MetaItem (ItemId)
GO 

-- Make sure there can only be one instance of a datapoint on a single event

CREATE UNIQUE INDEX I_ClinDatapoint_EventItem ON ClinDataPoint(EventId,ItemId)
GO 

-- Make sure it is quick to find items of the same type

CREATE INDEX I_ClinDataPoint_ItemId ON ClinDataPoint(ItemId)
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
      INSERT INTO ClinDatapoint (TouchId,ItemId,Quantity,DTVal,EnumVal,TextVal,EventId)
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
          INSERT INTO dbo.ClinLog( RowId,TouchId,ObsDate,Quantity,DTVal,EnumVal,TextVal )
            SELECT co.RowId,co.TouchId,co.ObsDate,co.Quantity,co.DTVal,co.EnumVal,co.TextVal 
            FROM dbo.ClinDatapoint co WHERE co.RowId=@RowId;
          SET @WhatHappened = 'Data changed, Updated ClinLog';
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

ALTER PROCEDURE dbo.GetClinData( @SessId INT, @PersonId INT ) AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @UserId INT;     
  DECLARE @StudyId INT;
  SELECT @StudyId=StudyId,@UserId=UserId FROM dbo.UserLog WHERE SessId=@SessId AND ClosedAt IS NULL;
  IF ISNULL(@UserId,0) <> USER_ID() 
    RAISERROR( 'The session is already closed or not opened by you!',16,1 )
  ELSE                           
  BEGIN
    SELECT 
      co.RowId,e.EventId,e.EventNum,e.EventTime,mi.VarName,co.Quantity,co.DTVal,
      co.EnumVal,co.TextVal,co.Locked,co.ChangeCount
    FROM dbo.ClinDataPoint co
      JOIN dbo.ClinEvent e ON e.EventId=co.EventId 
      JOIN dbo.MetaItem mi ON mi.ItemId=co.ItemId
    WHERE e.PersonId=@PersonId
    ORDER BY e.EventNum,e.EventId;
  END;
END
GO

CREATE VIEW dbo.ClinObservation WITH SCHEMABINDING AS
SELECT cp.RowId,cp.EventId,cp.ItemId,mi.VarName,cp.ObsDate,cp.Quantity,cp.DTVal,cp.EnumVal,cp.TextVal,cp.Locked,cp.LockedAt,
  cp.LockedBy,cp.TouchId,cp.ChangeCount,ct.FormId,cp.guid FROM
  dbo.ClinDataPoint cp 
  JOIN dbo.MetaItem mi ON mi.ItemId=cp.ItemId
  JOIN dbo.ClinTouch ct ON ct.TouchId=cp.TouchId
GO 

GRANT SELECT ON dbo.ClinObservation TO [public] AS [dbo]
GO

ALTER PROCEDURE dbo.AddFormItem( @FormId INT, @ItemId INT, @VarName VARCHAR(25), @ItemType INT, @OrderNumber INT, @ItemHeader VARCHAR(MAX), @ItemText VARCHAR(MAX) )
AS
BEGIN
  IF NOT EXISTS ( SELECT 1 FROM dbo.MetaItem WHERE ItemId=@ItemId )
    INSERT INTO dbo.MetaItem( ItemId, VarName, ItemType ) VALUES (@ItemId,@VarName,@ItemType);
END
GO

CREATE VIEW GBD.Tvangsvedtak AS
  SELECT ce.StudyId,ce.PersonId,ce.EventTime,cpstart.DTVal AS StartDate,cpstop.DTVal as StopDate,
    ISNULL(cpaction.EnumVal,1) AS StopAction,CONVERT(INT,getdate()-cpstop.DTVal) AS DaysPastDue,
    cf.ClinFormId
  FROM dbo.ClinEvent ce
  JOIN dbo.ClinForm cf ON cf.EventId=ce.EventId AND cf.DeletedAt IS NULL
  JOIN dbo.MetaForm mf ON mf.FormId=cf.FormId AND mf.FormName='TVANGSVEDTAK'
  LEFT OUTER JOIN dbo.ClinDatapoint cpstart ON cpstart.EventId=ce.EventId AND cpstart.ItemId=4496 
  LEFT OUTER JOIN dbo.ClinDatapoint cpstop ON cpstop.EventId=ce.EventId AND cpstop.ItemId=4497 
  LEFT OUTER JOIN dbo.ClinDatapoint cpaction ON cpaction.EventId=ce.EventId AND cpaction.ItemId=6888
GO 

GRANT SELECT ON GBD.Tvangsvedtak TO [public] AS [dbo]
GO

CREATE VIEW NDV.FormData 
AS
SELECT ce.EventTime as dato,p.NationalId as pasientid,co.VarName as navn,ISNULL(CONVERT(VARCHAR,co.DTVal,126),ISNULL(CONVERT(VARCHAR,co.EnumVal),CONVERT(VARCHAR,co.Quantity) ) ) as verdi
  FROM dbo.ClinObservation co 
  JOIN dbo.ClinEvent ce ON ce.EventId=co.EventId
  JOIN dbo.Person p ON p.PersonId=ce.PersonId
  JOIN dbo.StudCase sc ON sc.PersonId=p.PersonId AND sc.MarkedForExport=1
  WHERE (( co.VarName LIKE 'NDV_%' ) OR ( co.VarName IN ('SYSBP','DIABP','WEIGHT','HEIGHT','WAIST','BMI','HBA1C','DIABETESKOMPLIKASJONER')) OR ( co.VarName LIKE 'ATC_%' ));
GO

GRANT SELECT ON NDV.FormData TO [public] AS [dbo]
GO

-- Remove EventVar index and VarName column

DROP INDEX dbo.ClinDataPoint.I_ClinData_EventVar
GO

ALTER TABLE dbo.ClinDataPoint DROP COLUMN VarName
GO

ALTER PROCEDURE dbo.UpdateClinDataEventId( @FormId INT, @OldEventId INT, @NewEventId INT )
AS
BEGIN
  -- Find variable names on this form
  SELECT ItemId INTO #FormItems 
  FROM dbo.MetaFormItem WHERE FormId=@FormId;                                                                       
  -- Make non-greedy by deleting all items found in other forms
  DELETE FROM #FormItems WHERE ItemId IN (SELECT mfi.ItemId FROM dbo.MetaFormItem mfi
  WHERE mfi.FormId IN ( SELECT FormId FROM dbo.ClinForm WHERE EventId=@OldEventId AND FormId <> @FormId));
  -- Move all standard variables
  UPDATE dbo.ClinDatapoint SET EventId = @NewEventId WHERE EventId = @OldEventId
  AND ItemId IN ( SELECT ItemId FROM #FormItems ); 
  -- Move all threaded variables
  UPDATE dbo.ClinThreadData SET EventId = @NewEventId WHERE EventId = @OldEventId
  AND ItemId IN ( SELECT ItemId FROM #FormItems ); 
END
GO

EXECUTE DbFinalizeUpgrade 530;
GO

COMMIT TRANSACTION UpgradeTo530;
GO

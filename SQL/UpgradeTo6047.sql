BEGIN TRANSACTION UpgradeTo6047
PRINT 'Starting upgrade to 6047'

DELETE FROM DbUpgradeLog WHERE DbVer > 6046;

EXECUTE DbCheckVersion 6046;
EXECUTE DbStartUpgrade 6047;
GO

-- Create table for deleted datapoints

CREATE TABLE dbo.ClinDataPointDeleted
  (             
     RowId       INT NOT NULL,
     ItemId      INT NOT NULL,
     EventId     INT NOT NULL,
     TouchId     INT NOT NULL,
     ClinFormId  INT NOT NULL,         
     ObsDate     DATETIME NOT NULL,
     Quantity    DECIMAL(18, 4),
     DTVal       DATETIME,
     EnumVal     INT,
     TextVal     VARCHAR(max),
     Locked      INT NOT NULL,
     LockedAt    DATETIME,
     LockedBy    INT,
     ChangeCount TINYINT NOT NULL,
     DeletedAt   DATETIME NOT NULL,
     DeletedBy   INT NOT NULL,
     RestoredAt  DATETIME NULL,
     RestoredBy  INT NULL,
     guid        UNIQUEIDENTIFIER NOT NULL
     CONSTRAINT PK_ClinDataPointDeleted PRIMARY KEY CLUSTERED ( RowId )
  )
GO

ALTER TABLE dbo.ClinDataPointDeleted
  ADD 
    CONSTRAINT DF_ClinDataPointDeleted_DeletedAt DEFAULT GETDATE() FOR DeletedAt, 
    CONSTRAINT DF_ClinDataPointDeleted_DeletedBy DEFAULT USER_ID() FOR DeletedBy
GO

-- Add foreign keys

ALTER TABLE dbo.ClinDataPointDeleted
  ADD CONSTRAINT FK_ClinDataPointDeleted_ItemId FOREIGN KEY (ItemId) REFERENCES dbo.MetaItem(ItemId)
ALTER TABLE dbo.ClinDataPointDeleted
  ADD CONSTRAINT FK_ClinDataPointgDeleted_EventId FOREIGN KEY (EventId) REFERENCES dbo.ClinEvent(EventId)
ALTER TABLE dbo.ClinDataPointDeleted
  ADD CONSTRAINT FK_ClinDataPointDeleted_TouchId FOREIGN KEY (TouchId) REFERENCES dbo.ClinTouch(TouchId)
ALTER TABLE dbo.ClinDataPointDeleted
  ADD CONSTRAINT FK_ClinDataPointDeleted_ClinFormId FOREIGN KEY (ClinFormId) REFERENCES dbo.ClinForm(ClinFormId)
ALTER TABLE dbo.ClinDataPointDeleted
  ADD CONSTRAINT FK_ClinDataPointDeleted_LockedBy FOREIGN KEY (LockedBy) REFERENCES dbo.UserList(UserId)
ALTER TABLE dbo.ClinDataPointDeleted
  ADD CONSTRAINT FK_ClinDataPointDeleted_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.UserList(UserId)
ALTER TABLE dbo.ClinDataPointDeleted
  ADD CONSTRAINT FK_ClinDataPointDeleted_RestoredBy FOREIGN KEY (RestoredBy) REFERENCES dbo.UserList(UserId)
GO

IF NOT OBJECT_ID('FK_ClinLog_ClinObservation') IS NULL
  ALTER TABLE dbo.ClinLog DROP CONSTRAINT FK_ClinLog_ClinObservation
GO

IF NOT OBJECT_ID('CRF.DeleteClinFormItems') IS NULL
  DROP PROCEDURE CRF.DeleteClinFormItems
GO

CREATE PROCEDURE CRF.DeleteClinFormItems(@ClinFormId INT)
AS
BEGIN
  DECLARE @PersonId INT;  
  DECLARE @EventId INT;
  DECLARE @FormId INT;
  SET XACT_ABORT ON;
  BEGIN TRANSACTION DeleteItems;
  -- Find person and event number for this form
  SELECT @EventId = ce.EventId, @PersonId = ce.PersonId, @FormId = cf.FormId
  FROM   dbo.ClinEvent ce
  JOIN   dbo.ClinForm cf ON cf.EventId = ce.EventId
  WHERE  ClinFormId = @ClinFormId;
  -- Find items unique to this form
  SELECT ItemId INTO #tempItems 
    FROM dbo.MetaFormItem WHERE FormId = @FormId
  EXCEPT
    SELECT mfi.ItemId 
      FROM dbo.ClinEvent ce 
      JOIN dbo.ClinForm cf ON cf.EventId = ce.EventId
      JOIN dbo.MetaFormItem mfi ON mfi.FormId = cf.FormId 
    WHERE  ( ce.EventId=@EventId ) AND ( cf.ClinFormId <> @ClinFormId );
  -- Insert datapoints into deleted table
  INSERT INTO dbo.ClinDatapointDeleted ( RowId,ItemId,EventId,TouchId,ClinFormId,ObsDate,Quantity,DTVal,EnumVal,TextVal,ChangeCount,Locked,LockedAt,LockedBy,guid )
  SELECT RowId,ItemId,EventId,TouchId,@ClinFormId,ObsDate,Quantity,DTVal,EnumVal,TextVal,ChangeCount,Locked,LockedAt,LockedBy,guid 
  FROM dbo.ClinDatapoint WHERE EventId=@EventId AND ItemId IN (SELECT ItemId FROM #tempItems);
  --- Delete datapoints
  DELETE FROM dbo.ClinDatapoint WHERE EventId=@EventId AND ItemId IN (SELECT ItemId FROM #tempItems);
  COMMIT TRANSACTION DeleteItems;
END
GO

GRANT EXECUTE ON CRF.DeleteClinFormItems TO [public] AS [dbo]
GO

ALTER PROCEDURE CRF.DeleteClinForm(@ClinFormId INT)
AS
BEGIN
  -- Mark form as deleted
  UPDATE dbo.ClinForm
  SET    DeletedAt = GETDATE(),DeletedBy = USER_ID()
  WHERE  ( ClinFormId = @ClinFormId ) AND ( SignedBy IS NULL ) AND ( DeletedBy IS NULL );
  -- Check result
  IF @@ROWCOUNT = 0
    BEGIN
      RAISERROR( 'Du kan bare slette usignerte skjema!',16,1 );
      RETURN -1;
    END;
  -- If successful, delete form items
  EXEC CRF.DeleteClinFormItems @ClinFormId;
END
GO

REVOKE EXECUTE ON CRF.DeleteClinForm TO [public] AS [dbo]
GRANT EXECUTE ON CRF.DeleteClinForm TO [Journalansvarlig] AS [dbo]
GO

IF NOT OBJECT_ID('CRF.DeleteMyClinForm') IS NULL
  DROP PROCEDURE CRF.DeleteMyClinForm
GO

CREATE PROCEDURE CRF.DeleteMyClinForm(@ClinFormId INT)
AS
BEGIN
  -- Mark form as deleted
  UPDATE dbo.ClinForm
  SET    DeletedAt = GETDATE(),DeletedBy = USER_ID()
  WHERE  ( ClinFormId = @ClinFormId ) AND ( CreatedBy = USER_ID() ) AND ( SignedBy IS NULL ) AND ( DeletedBy IS NULL );
  -- Check result
  IF @@ROWCOUNT = 0
    BEGIN
      RAISERROR( 'Du kan bare slette dine egne usignerte skjema!',16,1 );
      RETURN -1;
    END;
  -- If successful, delete form items
  EXEC CRF.DeleteClinFormItems @ClinFormId;
END
GO

GRANT EXECUTE ON CRF.DeleteMyClinForm TO [public] AS [dbo]
GO

ALTER PROCEDURE dbo.UndeleteClinForm( @ClinFormId INT )
AS
BEGIN
  DECLARE @EventId INT;
  DECLARE @FormId INT;
  -- Find EventId and FormId t
  SELECT @EventId = EventId, @FormId=FormId FROM dbo.ClinForm WHERE ClinFormId=@ClinFormId;
  -- Add back into ClinForm table
  UPDATE dbo.ClinForm SET DeletedAt = NULL, DeletedBy = NULL WHERE ClinFormId=@ClinFormId;
  -- Move the datapoints
  INSERT INTO dbo.ClinDataPoint (ItemId,EventId,TouchId,ObsDate,Quantity,DTVal,EnumVal,TextVal,ChangeCount,Locked,LockedAt,LockedBy,guid)
    SELECT ItemId,EventId,TouchId,ObsDate,Quantity,DTVal,EnumVal,TextVal,ChangeCount,Locked,LockedAt,LockedBy,guid
    FROM dbo.ClinDataPointDeleted WHERE ( ClinFormId = @ClinFormId ) AND ( RestoredAt IS NULL );
  -- Mark datapoints as restored
  UPDATE dbo.ClinDataPointDeleted SET RestoredAt = GETDATE(), RestoredBy = USER_ID() WHERE ClinFormId=@ClinFormId AND RestoredAt IS NULL;
END;
GO

ALTER PROCEDURE dbo.GetDeletedClinForms( @StudyId INT, @PersonId INT )
AS 
BEGIN
  SELECT cf.ClinFormId, mf.FormTitle, NULL, dbo.ShortTime(ce.EventTime) AS EventTimeText,
    'Slettet: ' + dbo.ShortTime( cf.DeletedAt )+ ' ' + dbo.GetSign( cf.DeletedBy ) AS DeleteText, 
    'Opprettet: ' + dbo.ShortTime(cf.CreatedAt) + ' ' + dbo.GetSign( cf.CreatedBy) AS CreateText 
    FROM dbo.ClinForm cf 
    JOIN dbo.ClinEvent ce ON ce.EventId=cf.EventId
    JOIN dbo.MetaForm mf ON mf.FormId=cf.FormId     
  WHERE ( ce.StudyId=@StudyId ) AND ( ce.PersonId=@PersonId ) AND ( NOT cf.DeletedBy IS NULL )
  ORDER BY cf.DeletedAt DESC
END
GO

ALTER PROCEDURE dbo.DeleteClinForm(@ClinFormId INT)
AS
BEGIN
  IF ( IS_MEMBER('db_owner') = 1 )  OR ( IS_MEMBER('Journalansvarlig') = 1 )
    EXEC CRF.DeleteClinForm @ClinFormId
  ELSE
    EXEC CRF.DeleteMyClinForm @ClinFormId;
END
GO

DROP TRIGGER dbo.T_ClinDatapoint_Update
GO

CREATE TRIGGER dbo.T_ClinDataPoint_Update ON dbo.ClinDataPoint
AFTER UPDATE AS 
BEGIN      
   IF UPDATE(Quantity) OR UPDATE(DTVal) OR UPDATE(EnumVal) OR UPDATE (TextVal)
     INSERT INTO dbo.ClinLog( RowId, TouchId, ObsDate, Quantity, DTVal, EnumVal, TextVal )
     SELECT o.RowId,o.TouchId,o.ObsDate,o.Quantity,o.DTVal,o.EnumVal,o.TextVal 
     FROM deleted o
END
GO

DROP TRIGGER dbo.T_ClinForm_Update
GO

CREATE TRIGGER dbo.T_ClinForm_Update ON dbo.ClinForm
AFTER UPDATE AS 
BEGIN   
   IF UPDATE(Comment) OR UPDATE (SignedAt) OR UPDATE(DeletedAt)                 
     INSERT INTO dbo.ClinFormLog( ClinFormId, Comment, FormStatus, FormComplete, SignedAt, SignedBy )
     SELECT o.ClinFormId, o.Comment, o.FormStatus, o.FormComplete, o.SignedAt, o.SignedBy 
     FROM deleted o;
END
GO

COMMIT TRANSACTION UpgradeTo6047;
GO

EXECUTE dbo.DbFinalizeUpgrade 6047;
GO

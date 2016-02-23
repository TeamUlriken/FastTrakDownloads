BEGIN TRANSACTION UpgradeTo6019
PRINT 'Starting upgrade to 6019'

DELETE FROM DbUpgradeLog WHERE DbVer > 6018;

EXEC DbCheckVersion 6018;
EXECUTE DbStartUpgrade 6019;
GO

IF dbo.DbColumnExists( 'ClinFormLog', 'FormStatus' ) = 0 
  ALTER TABLE ClinFormLog ADD FormStatus CHAR(1)
GO

IF dbo.DbColumnExists( 'ClinFormLog', 'FormComplete') = 0
  ALTER TABLE ClinFormLog ADD FormComplete TINYINT
GO

IF dbo.DbColumnExists( 'ClinFormLog', 'SignedAt') = 0
  ALTER TABLE ClinFormLog ADD SignedAt DateTime
GO

IF dbo.DbColumnExists( 'ClinFormLog', 'SignedBy') = 0
  ALTER TABLE ClinFormLog ADD SignedBy INT
GO

ALTER PROCEDURE dbo.UpdateFormComment( @EventId INT, @FormId INT, @MemoHeight INT, @Comment VARCHAR(MAX) )
AS
BEGIN
  DECLARE @ClinFormId INT;
  DECLARE @FormStatus CHAR(1);
  SELECT @ClinFormId=ClinFormId, @FormStatus=FormStatus 
  FROM dbo.ClinForm WHERE EventId=@EventId AND FormId=@FormId;
  IF @ClinFormId IS NULL 
  BEGIN
    INSERT INTO dbo.ClinForm (EventId,FormId) VALUES(@EventId,@FormId)
    SET @ClinFormId = SCOPE_IDENTITY();
  END;
  IF @FormStatus = 'L'
    RAISERROR( 'Skjemaet er signert, og kan ikke oppdateres', 16, 1 )
  ELSE 
    UPDATE dbo.ClinForm SET Comment=@Comment WHERE ( ClinFormId = @ClinFormId ) AND ( ISNULL(Comment,'') <> ISNULL(@Comment,'') );
END
GO

ALTER PROCEDURE dbo.UpdateFormText ( @EventId INT, @FormId INT, @CachedText VARCHAR(MAX) ) AS
BEGIN
  UPDATE dbo.ClinForm SET CachedText=@CachedText 
  WHERE ( FormId=@FormId ) AND ( EventId=@EventId ) AND ( ISNULL(CachedText,'') <> ISNULL(@CachedText,'') );
END
GO

ALTER PROCEDURE dbo.GetLabData ( @PersonId INT ) AS
BEGIN
  SELECT ld.ResultId, ld.LabDate, ld.LabCodeId, lc.LabName, ld.NumResult, ld.UnitStr, 
    ld.DevResult, ld.TxtResult, ld.ArithmeticComp, ld.Comment, ld.RefInterval
  FROM dbo.LabData ld
  JOIN dbo.LabCode lc on lc.LabCodeId=ld.LabCodeId
  WHERE ld.PersonId=@PersonId
END
GO

IF NOT OBJECT_ID('T_ClinForm_Update') IS NULL DROP TRIGGER dbo.T_ClinForm_Update
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

EXECUTE dbo.DbFinalizeUpgrade 6019;
GO

COMMIT TRANSACTION UpgradeTo6019;
GO


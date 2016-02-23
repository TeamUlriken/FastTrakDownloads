SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6044
PRINT 'Starting upgrade to 6044'

-- Purpose of this update:
--   To allow form privileges to be set per profession
--   The contents of MetaFormProfessionPrivilege is downloaded from Meta

DELETE FROM DbUpgradeLog
WHERE  DbVer > 6043;

EXEC DbCheckVersion 6043;
EXECUTE DbStartUpgrade 6044;
GO

IF OBJECT_ID('UC_MetaProfession_OID9060') IS NULL
  ALTER TABLE dbo.MetaProfession
    ADD CONSTRAINT UC_MetaProfession_OID9060 UNIQUE(OID9060)
GO

IF NOT OBJECT_ID('MetaFormProfessionPrivilege') IS NULL
  DROP TABLE dbo.MetaFormProfessionPrivilege
GO

CREATE TABLE [dbo].[MetaFormProfessionPrivilege]
  (
     [RowId]      [INT] NOT NULL,
     [FormId]     [INT] NOT NULL,
     [ProfType]   [VARCHAR](3) NOT NULL,
     [CanCreate]  [BIT] NOT NULL CONSTRAINT [DF_MetaFormProfessionPrivilege_CanCreate] DEFAULT (1),
     [CanEdit]    [BIT] NOT NULL CONSTRAINT [DF_MetaFormProfessionPrivilege_CanEdit] DEFAULT (1),
     [CanSign]    [BIT] NOT NULL CONSTRAINT [DF_MetaFormProfessionPrivilege_CanSign] DEFAULT (1),
     [CreatedAt]  [DATETIME] NOT NULL CONSTRAINT [DF_MetaFormProfessionPrivilege_CreatedAt] DEFAULT (GETDATE()),
     [CreatedBy]  [INT] NOT NULL CONSTRAINT [DF_MetaFormProfessionPrivilege_CreatedBy] DEFAULT (USER_ID()),
     [Comment]    [VARCHAR](max) NULL,
     [LastUpdate] DATETIME NOT NULL CONSTRAINT [DF_MetaFormProfessionPrivilege_LastUpdate] DEFAULT GETDATE(),
     CONSTRAINT [PK_MetaFormProfessionPrivilege] PRIMARY KEY CLUSTERED([RowId] ASC)
  )
GO

CREATE UNIQUE INDEX IDX_MetaFormProfessionPrivilege
  ON dbo.MetaFormProfessionPrivilege(FormId, ProfType)
GO

ALTER TABLE dbo.MetaFormProfessionPrivilege ADD CONSTRAINT FK_MetaFormProfessionPrivilege_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.UserList(UserId) 
GO

ALTER TABLE dbo.MetaFormProfessionPrivilege ADD CONSTRAINT FK_MetaFormProfessionPrivilege_ProfType FOREIGN KEY (ProfType) REFERENCES dbo.MetaProfession(OID9060)
GO

GRANT UPDATE,INSERT,SELECT ON dbo.MetaFormProfessionPrivilege TO [superuser] AS [dbo]
GO

INSERT INTO dbo.MetaFormProfessionPrivilege
            (RowId,FormId,ProfType,CanCreate,CanEdit,CanSign,Comment)
VALUES      (1,149,'LE',1,1,1,'Lege kan fylle ut epikrise');
INSERT INTO dbo.MetaFormProfessionPrivilege
            (RowId,FormId,ProfType,CanCreate,CanEdit,CanSign,Comment)
VALUES      (2,266,'LE',1,1,1,'Lege kan fylle ut dødsattest');
INSERT INTO dbo.MetaFormProfessionPrivilege
            (RowId,FormId,ProfType,CanCreate,CanEdit,CanSign,Comment)
VALUES      (3,279,'LE',1,1,1,'Lege kan fylle ut notat lege');
INSERT INTO dbo.MetaFormProfessionPrivilege
            (RowId,FormId,ProfType,CanCreate,CanEdit,CanSign,Comment)
VALUES      (4,329,'LE',1,1,1,'Lege kan fylle ut enkelt legenotat');
INSERT INTO dbo.MetaFormProfessionPrivilege
            (RowId,FormId,ProfType,CanCreate,CanEdit,CanSign,Comment)
VALUES      (5,388,'LE',1,1,1,'Lege kan fylle ut EKG-beskrivelse');
INSERT INTO dbo.MetaFormProfessionPrivilege
            (RowId,FormId,ProfType,CanCreate,CanEdit,CanSign,Comment)
VALUES      (6,441,'LE',1,1,1,'Lege kan fylle ut Wells Score');
INSERT INTO dbo.MetaFormProfessionPrivilege
            (RowId,FormId,ProfType,CanCreate,CanEdit,CanSign,Comment)
VALUES      (7,198,'SP',1,1,1,'Sykepleier kan fylle ut notat sykepleier');
GO

UPDATE dbo.MetaFormProfessionPrivilege
SET    LastUpdate = '2000-01-01'
GO

IF NOT OBJECT_ID('NeedsFormPrivilege') IS NULL
  DROP FUNCTION dbo.NeedsFormPrivilege
GO

CREATE FUNCTION dbo.NeedsFormPrivilege(@ClinFormId INT)
RETURNS INT
AS
  BEGIN
    DECLARE @NeedsPrivilege INT;

    SET @NeedsPrivilege = 0;

    SELECT @NeedsPrivilege = 1
    FROM   dbo.ClinForm cf
    JOIN   dbo.MetaFormProfessionPrivilege mf
      ON mf.FormId = cf.FormId
    WHERE  cf.ClinFormId = @ClinFormId;
    RETURN @NeedsPrivilege;
  END
GO

GRANT EXECUTE ON dbo.NeedsFormPrivilege TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('HasSignClinFormPrivilege') IS NULL
  DROP FUNCTION dbo.HasSignClinFormPrivilege
GO

CREATE FUNCTION dbo.HasSignClinFormPrivilege(@ClinFormId INT,@UserId INT = NULL)
RETURNS INT
AS
  BEGIN
    DECLARE @NeedsPrivilegeResult INT;
    DECLARE @HasSignPrivilege INT;

    SET @UserId = ISNULL(@UserId, USER_ID());
    SET @NeedsPrivilegeResult = dbo.NeedsFormPrivilege(@ClinFormId);
    SET @HasSignPrivilege = 0;

    IF @NeedsPrivilegeResult = 0
      RETURN 1;

    SELECT @HasSignPrivilege = CanSign
    FROM   dbo.MetaFormProfessionPrivilege a
    JOIN   dbo.ClinForm b
      ON b.FormId = a.FormId
    JOIN   dbo.MetaProfession d
      ON d.ProfType = a.ProfType
    JOIN   dbo.UserList e
      ON e.ProfId = d.ProfId
    WHERE  e.UserId = @UserId AND b.ClinFormId = @ClinFormId;

    RETURN @HasSignPrivilege;
  END
GO

GRANT EXECUTE ON dbo.HasSignClinFormPrivilege TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('CanSignClinForm') IS NULL
  DROP PROCEDURE dbo.CanSignClinForm
GO

IF NOT OBJECT_ID('CRF.CanSignClinForm') IS NULL
  DROP PROCEDURE CRF.CanSignClinForm
GO

CREATE PROCEDURE CRF.CanSignClinForm(@ClinFormId INT)
AS
  BEGIN
    DECLARE @CanSign INT;
    DECLARE @ErrMsg VARCHAR(512);
    DECLARE @IsSigned INT;

    SET @CanSign = 1;
    SET @IsSigned = 0;

    -- Is it already signed?
    SELECT @IsSigned = 1
    FROM   dbo.ClinForm
    WHERE  ClinFormId = @ClinFormId AND FormStatus = 'L';

    IF @IsSigned = 1
      BEGIN
        SET @CanSign = 0
        SET @ErrMsg = 'Skjema er allerede signert'
      END
    ELSE IF dbo.HasSignClinFormPrivilege(@ClinFormId, NULL) = 0
      BEGIN
        SET @CanSign = 0
        SET @ErrMsg = 'Du har ikke rettigheter til å signere dette skjemaet!'
      END
    ELSE
      BEGIN
        SET @CanSign = 1
        SET @ErrMsg = ''
      END
    SELECT @CanSign AS CanSign,@ErrMsg AS ErrMsg;
  END
GO

GRANT EXECUTE ON CRF.CanSignClinForm TO [public] AS [dbo]
GO

ALTER PROCEDURE CRF.UpdateClinForm(@ClinFormId INT,@FormComment VARCHAR(MAX),@FormStatus CHAR(1),@FormComplete TINYINT)
AS
  BEGIN
    DECLARE @StudyId INT;
    DECLARE @PersonId INT;
    DECLARE @EventId INT;
    DECLARE @OldFormStatus CHAR(1);
    DECLARE @OldFormComplete TINYINT;

    SELECT @OldFormStatus = FormStatus,@OldFormComplete = FormComplete,@EventId = EventId
    FROM   dbo.ClinForm
    WHERE  ClinFormId = @ClinFormId;
    IF ( @OldFormStatus = 'L' )
      BEGIN
        RAISERROR ('Skjemaet er signert og kan ikke endres.',16,1 );
        RETURN -2;
      END
    ELSE
      BEGIN
        IF ( @FormStatus = 'L' )
          BEGIN
            -- Check if form can be signed 
            IF dbo.HasSignClinFormPrivilege(@ClinFormId, NULL) <> 1
              BEGIN
                RAISERROR ('Du har ikke rettigheter til å signere dette skjemaet!',16,1 );
                RETURN -1;
              END
          END;

        -- Update form properties
        UPDATE dbo.ClinForm
        SET    FormComplete = @FormComplete,FormStatus = @FormStatus,Comment = @FormComment
        WHERE  ClinFormId = @ClinFormId;
        -- Sign form if status is locked
        IF @FormStatus = 'L'
          UPDATE dbo.ClinForm
          SET    SignedAt = GETDATE(),SignedBy = USER_ID()
          WHERE  ClinFormId = @ClinFormId;
        SELECT @StudyId = StudyId,@PersonId = PersonId
        FROM   dbo.ClinEvent
        WHERE  EventId = @EventId;
        -- Find study and person, needed to update StudCase
        UPDATE dbo.StudCase
        SET    LastWrite = GETDATE()
        WHERE  StudyId = @StudyId AND PersonId = @PersonId;
      END;
  END
GO

IF NOT OBJECT_ID('CanUnsignClinForm') IS NULL
  DROP PROCEDURE dbo.CanUnsignClinForm
GO

IF NOT OBJECT_ID('CRF.CanUnsignClinForm') IS NULL
  DROP PROCEDURE CRF.CanUnsignClinForm
GO

CREATE PROCEDURE CRF.CanUnsignClinForm( @ClinFormId INT )
AS
  BEGIN
    -- Wraps dbo.CanUnsignForm by returning a dataset
    DECLARE @CanUnsign INT;
    DECLARE @ErrMsg VARCHAR(512);
    SET @CanUnsign = 1;
    EXEC dbo.CanUnsignForm @ClinFormId, @CanUnsign OUTPUT, @ErrMsg OUTPUT;
    SELECT @CanUnsign AS CanUnsign,@ErrMsg AS ErrMsg;
  END
GO

GRANT EXECUTE ON CRF.CanUnsignClinForm TO [public] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6044;
GO

COMMIT TRANSACTION UpgradeTo6044;
GO 

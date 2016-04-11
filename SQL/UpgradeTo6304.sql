SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6304
PRINT 'Starting upgrade to 6304'

-- Purpose of this update:
--  Add table and procedure to support special access logging, required for 6.4.
--  Must be Journalansvarlig or signee of a form to archive it
--  Adding some primary keys for compatibility with SQL Azure 
--  Renamed GbdLegemidde alerts to LMG, which is the new FormName
--  Expand AlertClass and RuleClass to match the size of FormName field
--  Create unique index on Alert for Study, Person and AlertClass.
--  Altered procedure GetNomMatch to search for codes if length of search text is 1.
--  Added table PersonDocumentLog to hold information about changes to NB, CAVE etc.

-- BEGIN start sequence (copy to future upgrade scripts)

DECLARE @RetVal INT;
EXEC @RetVal = dbo.DbStartUpgrade 6303, 6304;
IF @RetVal < 0
  SET NOEXEC ON
ELSE
  SET NOEXEC OFF
GO

IF NOT OBJECT_ID( 'dbo.AddSpecialAccessLog' ) IS NULL DROP PROCEDURE dbo.AddSpecialAccessLog
GO

CREATE INDEX I_CaseLog_LogType ON dbo.CaseLog( LogType )
GO

CREATE PROCEDURE dbo.AddSpecialAccessLog( @PersonId INT, @Justification VARCHAR(MAX) ) AS
BEGIN
  INSERT INTO dbo.CaseLog( PersonId, LogType,LogText )
  VALUES( @PersonId, 'TILGANG', @Justification );
END
GO
  
GRANT EXECUTE ON dbo.AddSpecialAccessLog TO [public] AS [dbo]
GO

ALTER PROCEDURE CRF.UpdateClinFormArchiveStatus( @ClinFormId INT, @ArchiveStatus BIT ) AS
BEGIN
  -- Check if the form is to be signed. If so user has to be Journalansvarlig or the signer of the form.
  -- Also, the form must be signed to allow archiving
  IF (@ArchiveStatus = 1)
  BEGIN
    DECLARE @SignedBy INT;
    DECLARE @IsJournalAnsvarlig INT;
    SET @IsJournalAnsvarlig = 0;

    SELECT @SignedBy = SignedBy
      FROM dbo.ClinForm
     WHERE ClinFormId = @ClinFormId;
     
    IF (@SignedBy IS NULL)
    BEGIN
      RAISERROR( 'Kun signerte skjema kan arkiveres!', 16, 1 );
      RETURN -1;
    END;
    
    SELECT @IsJournalAnsvarlig = 1  
      FROM dbo.ClinForm cf
           JOIN dbo.ClinEvent ce ON ce.EventId = cf.EventId
           JOIN dbo.StudCase sc ON sc.PersonId = cf.PersonId AND sc.StudyId = ce.StudyId
     WHERE cf.ClinFormId = @ClinFormId
       AND sc.Journalansvarlig = USER_ID();

    IF ((@IsJournalAnsvarlig = 0) AND (@SignedBy <> USER_ID()))
    BEGIN
      RAISERROR( 'Du må være journalansvarlig eller ha signert skjemaet for å kunne arkivere det!', 16, 1 );
      RETURN -2;
    END;
  END;
  
  UPDATE dbo.ClinForm SET Archived = @ArchiveStatus 
  WHERE ( ClinFormId = @ClinFormId ) AND ( Archived <> @ArchiveStatus );
END
GO

ALTER TABLE dbo.CaveLog ADD LogId INT IDENTITY(1,1) NOT NULL 
GO
ALTER TABLE dbo.CaveLog ADD CONSTRAINT PK_CaveLog PRIMARY KEY(LogId)
GO
ALTER TABLE Dash.PersonData ADD RowId INT IDENTITY(1,1) NOT NULL
GO
ALTER TABLE Dash.PersonData ADD CONSTRAINT PK_Dash_PersonData PRIMARY KEY(RowId)
GO

GRANT UPDATE ON dbo.MetaForm TO [public] AS [dbo]
GO

UPDATE dbo.MetaForm SET FormName='LMG' WHERE FormName='GbdLegemiddel'
GO

REVOKE UPDATE ON dbo.MetaForm TO [public]
GO

GRANT DELETE ON dbo.Alert TO [public] AS [dbo]
GO

DELETE FROM dbo.Alert WHERE AlertClass = 'GbdLegemidde'
DELETE FROM dbo.Alert WHERE AlertClass LIKE '%!%'
GO

REVOKE DELETE ON dbo.Alert TO [public]
GO

ALTER TABLE dbo.Alert ALTER COLUMN AlertClass VARCHAR(24) NOT NULL
GO

ALTER TABLE dbo.DSSRule ALTER COLUMN RuleClass VARCHAR(24) NOT NULL
GO

CREATE UNIQUE INDEX I_Alert_StudyPersonClass ON dbo.Alert(StudyId,PersonId,AlertClass)
GO

ALTER PROCEDURE dbo.GetNomMatch( @MatchString VARCHAR(32), @ListId INT ) AS
BEGIN
  DECLARE @SearchFor VARCHAR(36);
  DECLARE @SubStr VARCHAR(2);
  SET @SubStr=SUBSTRING(@MatchString,2,1);
  IF ISNUMERIC(@SubStr)=1 OR LEN(@MatchString)=1
  BEGIN
    SET @SearchFor = @MatchString + '%';
    SELECT mi.ItemCode,mi.ItemName
      FROM dbo.MetaNomItem mi
      JOIN dbo.MetaNomListItem ml ON ml.ItemId=mi.ItemId AND ml.ListId=@ListId
    WHERE mi.ItemCode LIKE @SearchFor
    ORDER BY mi.ItemCode
  END
  ELSE 
  BEGIN
    SET @SearchFor = '%' + @MatchString + '%';
    SELECT mi.ItemCode,mi.ItemName,CharIndex(@MatchString,mi.ItemName) as FindPos
      FROM dbo.MetaNomItem mi
      JOIN dbo.MetaNomListItem ml ON ml.ItemId=mi.ItemId AND ml.ListId=@ListId
      WHERE mi.ItemName LIKE @SearchFor
    ORDER by FindPos,mi.ItemCode
  END
END
GO

IF NOT OBJECT_ID('dbo.PersonDocumentLog') IS NULL 
  DROP TABLE dbo.PersonDocumentLog;
GO

CREATE TABLE dbo.PersonDocumentLog (
  LogId int IDENTITY(1,1) NOT NULL,
  PersonId int NOT NULL,
  DocumentId int NOT NULL,
  Content varchar(MAX),
  ChangedAt datetime CONSTRAINT DF_PersonDocumentLog_ChangedAt DEFAULT GETDATE(),
  ChangedBy int CONSTRAINT DF_PersonDocumentLog_ChangedBy DEFAULT USER_ID(),
  CONSTRAINT PK_PersonDocumentLog PRIMARY KEY (LogId) )
GO

IF NOT OBJECT_ID('dbo.T_Person_UpdateDocuments') IS NULL 
  DROP TRIGGER [dbo].[T_Person_UpdateDocuments] ;
GO

CREATE TRIGGER [dbo].[T_Person_UpdateDocuments] ON [dbo].[Person] 
AFTER UPDATE AS 
BEGIN      
  SET NOCOUNT ON;
  IF UPDATE(CAVE)
  BEGIN
    INSERT INTO dbo.PersonDocumentLog (PersonId, DocumentId, Content ) 
      SELECT i.PersonId, 50001, i.CAVE
        FROM deleted d
             JOIN inserted i ON i.PersonId = d.PersonId
       WHERE ISNULL(i.CAVE,'') <> ISNULL(d.CAVE,'');
  END;
  
  IF UPDATE(Reservations)
  BEGIN
    INSERT INTO dbo.PersonDocumentLog (PersonId, DocumentId, Content ) 
      SELECT i.PersonId, 50003, i.Reservations
        FROM deleted d
             JOIN inserted i ON i.PersonId = d.PersonId
       WHERE ISNULL(i.Reservations,'') <> ISNULL(d.Reservations,'');
  END;

  IF UPDATE(NB)
  BEGIN
    INSERT INTO dbo.PersonDocumentLog (PersonId, DocumentId, Content ) 
      SELECT i.PersonId, 50005, i.NB
        FROM deleted d
             JOIN inserted i ON i.PersonId = d.PersonId
       WHERE ISNULL(i.NB,'') <> ISNULL(d.NB,'');
  END;

 IF UPDATE(Allergies) 
  BEGIN
    INSERT INTO dbo.PersonDocumentLog (PersonId, DocumentId, Content ) 
      SELECT i.PersonId, 11036, i.Allergies
        FROM deleted d
             JOIN inserted i ON i.PersonId = d.PersonId
       WHERE ISNULL(i.Allergies,'') <> ISNULL(d.Allergies,'');
  END;

END;
GO

-- Move data from CaveLog to DocumentLog 
GRANT INSERT ON dbo.PersonDocumentLog TO [public] AS [dbo]
GO

INSERT INTO dbo.PersonDocumentLog (PersonId,DocumentId,Content,ChangedAt,ChangedBy)
SELECT PersonId,50001,CAVE,CreatedAt,CreatedBy FROM dbo.CaveLog
GO

REVOKE INSERT ON dbo.PersonDocumentLog TO [public]
GO

DROP TABLE dbo.CaveLog
GO

CREATE VIEW dbo.CaveLog AS SELECT PersonId, Content, ChangedAt AS CreatedAt, ChangedBy AS CreatedBy 
FROM dbo.PersonDocumentLog WHERE DocumentId=50001
GO

GRANT SELECT ON dbo.CaveLog TO [public] AS [dbo]
GO

ALTER PROCEDURE dbo.GetCAVEHistory( @PersonId INT ) AS
BEGIN
  SET NOCOUNT ON;
  SELECT Content,
    CASE pdl.DocumentId 
      WHEN 50001 THEN 'CAVE'
      WHEN 50003 THEN 'Ønsker'
      WHEN 50005 THEN 'NB'
      WHEN 11036 THEN 'Allergi'
    ELSE
      'Annet'
    END AS Section,
    up.Signature,ChangedAt,ChangedBy
  FROM dbo.PersonDocumentLog pdl 
    LEFT OUTER JOIN dbo.UserList ul ON ul.UserId=pdl.ChangedBy
    LEFT OUTER JOIN dbo.Person up on up.PersonId=ul.PersonId
  WHERE pdl.PersonId=@PersonId
  ORDER BY ChangedAt DESC
END
GO

IF USER_ID('Researcher') IS NULL
BEGIN
  CREATE ROLE Researcher
  INSERT INTO dbo.UserRoleInfo (RoleName,RoleCaption,RoleInfo,IsActive,SortOrder) 
  VALUES( 'Researcher','Forsker','Gir tilgang til visse rapporter på tvers av institusjoner',1,18)
END
GO

UPDATE dbo.UserRoleInfo SET RoleCaption = 'Rollestyring' WHERE RoleCaption='Tilgangsstyring'
UPDATE dbo.UserRoleInfo SET RoleCaption = 'Systemoppgradering' WHERE RoleCaption='Oppgradering'
UPDATE dbo.UserRoleInfo SET RoleCaption = 'Databaseeier' WHERE RoleCaption='Systemeier'


EXECUTE dbo.DbFinalizeUpgrade 6304;
GO

COMMIT TRANSACTION UpgradeTo6304;
GO



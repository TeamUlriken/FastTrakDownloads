SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo520;
PRINT 'Starting upgrade to 520'
DELETE FROM DbUpgradeLog WHERE DbVer > 519;

EXEC DbCheckVersion 519;       
EXECUTE DbStartUpgrade 520;
GO

IF EXISTS ( SELECT UserName FROM UserList WHERE UserId = 0 AND UserName = 'public' )
BEGIN
  UPDATE UserList SET UserName = 'Xpublic' WHERE UserId=0
END
GO

IF EXISTS( SELECT UserName FROM UserList WHERE UserId=0 )
BEGIN
  EXEC dbo.UtilNegateUser 0
END
GO

GRANT EXECUTE ON dbo.AddStudyGroup TO [superuser]
GO

EXEC DbLogChange 520,'Security','Granted EXECUTE ON AddStudyGroupTo superuser'
GO

IF IS_MEMBER( 'db_owner' )=1
BEGIN
  EXEC sp_addrolemember db_ddladmin,superuser
  EXEC sp_addrolemember db_securityadmin,superuser
  EXEC sp_addrolemember db_accessadmin,superuser
END
GO

EXEC DbLogChange 520,'Security','Added various roles for superuser'
GO

IF NOT USER_ID('EPRResponsible') IS NULL DROP ROLE [EPRResponsible]
GO

EXEC DbLogChange 520,'Cleanup','Removed role EPRResponsible'
GO

GRANT SELECT ON ViewCaseListStub TO [public] AS [dbo]
GRANT SELECT ON ClinForm TO [public] AS [dbo]
GO

EXEC DbLogChange 520, 'Security','GRANT SELECT on ViewCaseListStub and ClinForm to [public].'
GO

ALTER PROCEDURE dbo.GetStudyAndUser( @StudyName VARCHAR(40) )
AS
BEGIN
 DECLARE @StudyId INT;  
 DECLARE @UserId INT;       
 DECLARE @UserName NVARCHAR(128);  
 DECLARE @RealName NVARCHAR(128);     
 IF ISNULL(USER_ID(),0) = 0
 BEGIN
   RAISERROR( N'Du mangler dessverre en brukerkonto i systemet. Be en superbruker\nom å legge deg til som bruker i applikasjonen!', 16, 1 );
   RETURN -4;
 END;
 SET @RealName = USER_NAME();
 SELECT @UserId=UserId,@UserName=ISNULL(UserName,'(mangler)') FROM UserList WHERE UserId=user_id();
 IF @UserId IS NULL  
 BEGIN
   SET @UserId=USER_ID(); 
   SET @UserName=@RealName;
   INSERT INTO UserList (UserId,UserName) VALUES( @UserId,@UserName )
 END
 ELSE IF (@UserName <> @RealName ) OR ( @UserName IS NULL )
 BEGIN
   RAISERROR( N'Forventet [%s] og virkelig brukernavn [%s] er forskjellig.\nApplikasjonen kan ikke brukes av deg til dette er ordnet.\n\nDu må kontakte Emetra AS telefon 90656922 snarest!', 16, 1, @UserName, @RealName )
   RETURN -1;
 END;
 IF ISNULL(@StudyName,'') = '' 
 BEGIN
   RAISERROR( N'Fagområde er ikke spesifisert!', 16, 1 );
   RETURN -2;
 END;
 SELECT @StudyId=StudyId FROM Study WHERE StudyName=@StudyName;
 IF @StudyId IS NULL BEGIN
   RAISERROR( N'Fagområdet "%s" mangler i denne databasen!\nDette må lisensieres separat fra Emetra AS.', 16, 1, @StudyName );
   RETURN -3;
 END
 SELECT s.StudyId,p.*,mp.*,c.*,sg.*,su.ShowMyGroup,su.CaseList,user_id() as UserId,user_name() AS UserName
   FROM Study s
   LEFT OUTER JOIN UserList ul on ul.UserId=user_id()
   LEFT OUTER JOIN Person p ON p.PersonId=ul.PersonId
   LEFT OUTER JOIN StudyCenter c ON c.CenterId=ul.CenterId
   LEFT OUTER JOIN StudyUser su ON su.UserId=ul.UserId AND su.StudyId=s.StudyId
   LEFT OUTER JOIN StudyGroup sg ON sg.GroupId=su.GroupId AND sg.StudyId=s.StudyId
   LEFT OUTER JOIN MetaProfession mp on mp.ProfId=ul.ProfId
  WHERE s.StudyId=@StudyId
END
GO

EXEC DbLogChange 520,'Tweak','Improved error message in GetStudyAndUser'
GO

IF NOT EXISTS( select * FROM sysobjects WHERE name = 'C_UserList_Zero' ) 
  ALTER TABLE UserList ADD CONSTRAINT C_UserList_Zero CHECK ( UserId <> 0 )
GO

EXEC DbLogChange 520, 'Bugfix','Will no longer let GetStudyAndUser insert UserId=0 into UserList.'
GO

ALTER PROCEDURE dbo.UtilNegateUser( @UserId INT )
AS
BEGIN
  DECLARE @TableSchema NVARCHAR(128);
  DECLARE @TableName NVARCHAR(128);
  DECLARE @ColumnName NVARCHAR(128);
  DECLARE @UserName NVARCHAR(128);
  DECLARE @NegUser int;
  DECLARE @SqlCmd varchar(512);
  SELECT @UserName=UserName FROM UserList WHERE UserId=@UserId;
  IF @UserName=USER_NAME(@UserId)
  BEGIN
    RAISERROR( 'You can not negate a valid user!', 16, 1 )
    RETURN -1;
  END;
  SELECT @NegUser = MIN( UserId ) FROM UserList;
  IF @NegUser > 0 SET @NegUser = 0;
  SET @NegUser = @NegUser - 1;    
  -- Create the negated user
  INSERT INTO UserList (UserId,PersonId,CreatedAt,CreatedBy,CenterId,ProfId,UserName,OldUserId)
    SELECT @NegUser,PersonId,CreatedAt,CreatedBy,CenterId,ProfId,UserName,UserId FROM UserList
    WHERE UserId=@UserId;
  -- Find columns to update
  DECLARE cur_columns CURSOR FOR
    SELECT t.TABLE_SCHEMA,c.TABLE_NAME,c.COLUMN_NAME
    FROM INFORMATION_SCHEMA.columns c
    JOIN INFORMATION_SCHEMA.tables t ON t.TABLE_NAME = c.TABLE_NAME AND t.TABLE_SCHEMA=c.TABLE_SCHEMA
    WHERE c.COLUMN_NAME IN(
      'CreatedBy','SignedBy','PausedBy','PulledBy','StopBy','FormOwner','UpgradedBy','UpdatedBy','StartedBy','RestartBy','ChangedBy','LockedBy', 'UserId', 'ClosedBy', 'HandledBy', 'DeletedBy', 'DisabledBy', 'PrintedBy', 'RequestedBy', 'TakenBy' )
    AND t.TABLE_NAME <>'UserList' AND t.TABLE_TYPE='BASE TABLE';
  OPEN cur_columns;
  -- Update all columns from list
  FETCH NEXT FROM cur_columns INTO @TableSchema,@TableName,@ColumnName;
  WHILE @@FETCH_STATUS = 0
  BEGIN
      SET @SqlCmd = 'UPDATE ' + @TableSchema + '.' + @TableName + ' SET ' + @ColumnName + '=' + CONVERT(VARCHAR,@NegUser) + ' WHERE ' + @ColumnName + '=' + CONVERT(Varchar,@UserId);
      EXECUTE( @SqlCmd );
    FETCH NEXT FROM cur_columns INTO @TableSchema,@TableName,@ColumnName;
  END
  CLOSE cur_columns;
  DEALLOCATE cur_columns;
  DELETE FROM UserList WHERE UserId=@UserId;
END
GO

EXEC DbLogChange 520, 'Bugfix','Will include HandledBy in list of UserList foreign keys in UtilNegateUser.'
GO

ALTER PROCEDURE dbo.UpdateClinFormUnsign( @ClinFormId INT ) AS
BEGIN
  DECLARE @CanUnsign INT;
  DECLARE @EventId INT;
  DECLARE @FormId INT;                                                     
  DECLARE @MessageText VARCHAR(MAX);
  EXEC dbo.CanUnsignForm @ClinFormId, @CanUnsign OUTPUT, @MessageText OUTPUT;
  IF @CanUnsign > 0                                                
  BEGIN              
    -- Unsign form itself
    UPDATE dbo.ClinForm SET SignedAt=NULL, SignedBy=NULL, FormStatus='I' WHERE ClinFormId=@ClinFormId;
    SELECT @EventId = EventId, @FormId = FormId FROM dbo.ClinForm WHERE ClinFormId=@ClinFormId;
    -- Get items on form 
    SELECT mi.ItemId,mi.VarName INTO #FormItems 
    FROM dbo.MetaFormItem mfi 
    JOIN dbo.MetaItem mi ON mi.ItemId=mfi.ItemId 
    WHERE mfi.FormId=@FormId;         
    -- Unsign standard variables
    UPDATE dbo.ClinObservation SET LockedAt=NULL,LockedBy=NULL,Locked=0
    WHERE EventId=@EventId AND VarName IN (SELECT VarName FROM #FormItems);
    -- Unsign threaded variables
    UPDATE dbo.ClinThreadData SET LockedAt=NULL,LockedBy=NULL,Locked=0
    WHERE ItemId IN ( SELECT ItemId FROM #FormItems );
    RETURN;
  END
  ELSE
  BEGIN  
    RAISERROR( @MessageText, 16,1 )
    RETURN -2;
  END;
END
GO

EXEC DbLogChange 520, 'Bugfix','Using variable names from MetaItem/MetaFormItem to decide what to unsign in UpdateClinFormUnsign.'
GO

GRANT EXECUTE ON dbo.MergeVariables TO [superuser] AS [dbo]
GO

IF OBJECT_ID( 'dbo.ClinDatapoint' ) IS NULL 
  EXECUTE dbo.MergeVariables 'VAR5876','DBP_UNSPEC'
GO

EXEC DbLogChange 520, 'Bugfix','Rettet variabelnavn for blodtrykk'
GO


IF dbo.DbColumnExists( 'dbo.KBDrugToProblem', 'DxSystem' ) = 0 
 ALTER TABLE dbo.KBDrugToProblem ADD DxSystem INT
GO

EXEC DbLogChange 520, 'Tweak','Added DxSystem field to KBDrugToProblem, to be able to join in integer field in RuleDrugToProblem later.'
GO

GRANT UPDATE ON dbo.MetaPackType TO public
GO

UPDATE dbo.MetaPackType SET PackDesc = 'Ordinær' WHERE PackType='O'
GO

UPDATE dbo.MetaPackType SET PackDesc = 'Tekstveiledning' WHERE PackType='X'
GO

GRANT UPDATE ON dbo.MetaTreatType TO [public] AS [dbo]
GO

UPDATE dbo.MetaTreatType SET TreatDesc = 'Ukedosering' WHERE TreatType='U'
GO

REVOKE UPDATE ON dbo.MetaPackType TO [public] AS [dbo]
GO

REVOKE UPDATE ON dbo.MetaPackType TO [public] AS [dbo]
GO

EXEC DbLogChange 520, 'Tweak','Changed names for some treatment/dosing schemes.'
GO

ALTER PROCEDURE FEST.FinnRefusjonskoder( @ATC VARCHAR(7) ) AS 
BEGIN
  DECLARE @OID INT;
  DECLARE @AltOID INT;      
  -- Choose alternative OID based on ICPC/ICD10 problem list
  SELECT @OID = OID FROM dbo.MetaNomList l JOIN dbo.UserList ul ON ul.ProbListId = l.ListId AND ul.UserId=USER_ID();
  IF @OID = 7110 SET @AltOid=7435;
  IF @OID = 7170 SET @AltOId=7434;
  -- Find matching codes for ATC
  SELECT rk.V as CodeText, ISNULL(rk.Underterm,rk.DN) as CodeHeader,rk.OID,rg.GruppeNavn,rg.RefRefusjonshjemmel AS OID7427
    INTO #temp
    FROM FEST.Refusjonskode rk 
    JOIN FEST.Refusjonsgruppe rg ON rg.Id = rk.RefRefusjonsgruppe
  WHERE CHARINDEX(rg.ATC,@ATC)=1 
    AND ( rg.Status='A' )
    AND ( ( rk.OID = @OID ) OR ( rk.OID = @AltOid ) )
    AND ( ( rk.GyldigFraDato < getdate() ) AND ( ISNULL(rk.GyldigTilDato,getdate()+1) > getdate() ) ); 
  -- Select codes without duplicates 
  SELECT DISTINCT mr.CodeId,t.CodeText,t.CodeHeader,mr.CodeText as CodeInfo 
    FROM #temp t JOIN dbo.MetaReimbursementCode mr ON mr.OID7427=t.OID7427
    ORDER BY t.CodeText,mr.CodeText 
END
GO

EXEC DbLogChange 520, 'Bugfix','FEST.FinnRefusjonskoder will use ProbListId for current user.'
GO

-----------------------------------------
-- Add default for ProbListId on UserList
-----------------------------------------
 
GRANT EXECUTE ON dbo.UtilDropDefault TO [superuser] AS [dbo]
GO

EXEC dbo.UtilDropDefault 'UserList', 'ProbListId'
GO

ALTER TABLE dbo.UserList ADD CONSTRAINT DF_UserList_ProbListId DEFAULT (4) FOR ProbListId
GO

GRANT UPDATE ON UserList TO [public] AS [dbo]
GO

UPDATE UserList SET ProbListId=4 WHERE ProbListId IS NULL
GO

REVOKE UPDATE ON UserList TO public
GO

EXEC DbLogChange 520, 'Tweak','Using 4 (ICD-10) as default for ProbListId in UserList'
GO

-----------------------------------------
-- Add guid to various tables
-----------------------------------------

GRANT UPDATE ON ClinForm TO [public]
GO

IF dbo.DbColumnExists( 'ClinForm','guid' ) = 0
  ALTER TABLE ClinForm ADD guid UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ClinFormGuid DEFAULT NEWID() ROWGUIDCOL
GO

REVOKE UPDATE ON dbo.ClinForm TO [public] AS [dbo]
GO

EXEC DbLogChange 520, 'Feature','Adding guid column to ClinForm'
GO

GRANT UPDATE ON dbo.ClinObservation TO [public] AS [dbo]
GO

IF dbo.DbColumnExists( 'ClinObservation','guid' ) = 0
  ALTER TABLE ClinObservation ADD guid UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ClinObservationGuid DEFAULT NEWID() ROWGUIDCOL
GO

REVOKE UPDATE ON dbo.ClinObservation TO [public]
GO

EXEC DbLogChange 520, 'Feature','Adding guid column to StudyCenter'
GO

GRANT UPDATE ON dbo.StudyCenter TO [public] AS [dbo]
GO

IF dbo.DbColumnExists( 'StudyCenter','guid' ) = 0
  ALTER TABLE StudyCenter ADD guid UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_StudyCenterGuid DEFAULT NEWID() ROWGUIDCOL
GO

REVOKE UPDATE ON StudyCenter TO [public] AS [dbo]
GO

EXEC DbLogChange 520, 'Feature','Adding guid column to StudyGroup'
GO

GRANT UPDATE ON StudyGroup TO [public] AS [dbo]
GO

IF dbo.DbColumnExists( 'StudyGroup','guid' ) = 0
  ALTER TABLE StudyGroup ADD guid UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_StudyGroupGuid DEFAULT NEWID() ROWGUIDCOL
GO

REVOKE UPDATE ON StudyGroup TO [public] AS [dbo]
GO

EXEC DbLogChange 520, 'Feature','Adding guid column to StudCase'
GO

GRANT UPDATE ON StudCase TO [public] AS [dbo]
GO

IF dbo.DbColumnExists( 'StudCase','guid' ) = 0
  ALTER TABLE StudCase ADD guid UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_StudCaseGuid DEFAULT NEWID() ROWGUIDCOL
GO

REVOKE UPDATE ON StudCase TO [public] AS [dbo]
GO

EXEC DbLogChange 520, 'Feature','Adding guid column to UserLog'
GO

GRANT UPDATE ON UserLog TO [public] AS [dbo]
GO

IF dbo.DbColumnExists( 'UserLog','guid' ) = 0
  ALTER TABLE UserLog ADD guid UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_UserLogGuid DEFAULT NEWID() ROWGUIDCOL
GO

REVOKE UPDATE ON UserLog TO [public] AS [dbo]
GO

EXEC DbLogChange 520, 'Feature','Adding guid column to ClinTouch'
GO

GRANT UPDATE ON ClinTouch TO [public] AS [dbo]
GO

IF dbo.DbColumnExists( 'ClinTouch','guid' ) = 0
  ALTER TABLE ClinTouch ADD guid UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ClinTouchGuid DEFAULT NEWID() ROWGUIDCOL
GO

REVOKE UPDATE ON ClinTouch TO [public] AS [dbo]
GO

IF NOT object_id('GetFirstStudyStatus') IS NULL
  DROP FUNCTION dbo.GetFirstStudyStatus
GO

CREATE FUNCTION dbo.GetFirstStudyStatus( @StudyId INT, @PersonId INT ) RETURNS INT
AS
BEGIN
  DECLARE @RetVal INT;
  SELECT TOP 1 @RetVal = scl.OldStatusId FROM StudCaseLog scl JOIN StudCase sc ON sc.StudCaseId=scl.StudCaseId
  WHERE sc.StudyId=@StudyId AND sc.PersonId=@PersonId AND NOT scl.OldStatusId IS NULL
  ORDER BY ChangedAt;
  RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetFirstStudyStatus TO [public] AS [dbo]
GO

IF NOT object_id('GetFirstStudyGroup') IS NULL
  DROP FUNCTION dbo.GetFirstStudyGroup
GO

CREATE FUNCTION dbo.GetFirstStudyGroup( @StudyId INT, @PersonId INT ) RETURNS INT
AS
BEGIN
  DECLARE @RetVal INT;
  SELECT TOP 1 @RetVal = scl.OldGroupId FROM StudCaseLog scl JOIN StudCase sc ON sc.StudCaseId=scl.StudCaseId
  WHERE sc.StudyId=@StudyId AND sc.PersonId=@PersonId AND NOT scl.OldGroupId IS NULL
  ORDER BY ChangedAt;
  RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetFirstStudyGroup TO [public] AS [dbo]
GO

EXEC DbLogChange 520, 'Feature','Adding functions GetFirstStudyStatus and GetFirstStudyGroup'
GO

ALTER PROCEDURE Dash.AddInitialStatusToStudCaseLog AS
BEGIN
  INSERT INTO dbo.StudCaseLog ( ChangedAt,ChangedBy,StudCaseId,NewStatusId,NewGroupId, NewHandler )
  SELECT sc.CreatedAt,sc.CreatedBy,sc.StudCaseId,sc.FinState,sc.GroupId,USER_ID(sc.Investor) from dbo.StudCase sc
  WHERE NOT EXISTS (SELECT l.StudCaseId FROM dbo.StudCaseLog l WHERE l.StudCaseId = sc.StudCaseId );
  INSERT INTO dbo.StudCaseLog ( ChangedAt,ChangedBy,StudCaseId,NewStatusId,NewGroupId, NewHandler )
  SELECT sc.CreatedAt,sc.CreatedBy,sc.StudCaseId,dbo.GetFirstStudyStatus(sc.StudyId,sc.PersonId),dbo.GetFirstStudyGroup(sc.StudyId,sc.PersonId),sc.CreatedBy from dbo.StudCase sc
  WHERE NOT EXISTS (SELECT l.StudCaseId FROM dbo.StudCaseLog l WHERE l.StudCaseId = sc.StudCaseId AND l.OldStatusId IS NULL AND l.OldGroupId IS NULL )
END
GO

GRANT EXECUTE ON Dash.AddInitialStatusToStudCaseLog TO [public] AS [dbo]
GO

EXEC Dash.AddInitialStatusToStudCaseLog
GO

EXEC DbLogChange 520, 'Bugfix','Adding initial status for StudCaseLog even for StudCase with data already in the table'
GO

ALTER FUNCTION dbo.GetDrugUse( @PersonId INT, @ATC varchar(7), @CalcAt DateTime ) RETURNS INT
AS
BEGIN
  -- Returns 0 if never used, 1 if ongoing, 2 if stopped.
  DECLARE @RetVal INT;
  DECLARE @TreatId INT;
  SELECT @TreatId=MAX(TreatId) FROM DrugTreatment
    WHERE ( PersonId=@PersonId ) AND (ATC LIKE @ATC) AND ( StartAt <= @CalcAt );
  IF @TreatId IS NULL
    SET @RetVal = 0
  ELSE
  BEGIN
    SELECT @TreatId=MAX(TreatId) FROM DrugTreatment WHERE ( PersonId=@PersonId )
      AND ( StartAt <= @CalcAt ) AND ( StopAt IS NULL OR StopAt > @CalcAt ) AND ( ATC LIKE @ATC );
     IF NOT @TreatId IS NULL
       SET @RetVal = 1
     ELSE
       SET @RetVal = 2;
  END;
  RETURN @RetVal;
END
GO

EXEC DbLogChange 520, 'Bugfix','GetDrugUse return incorrect values (not filtered correctly on ATC)'
GO

IF dbo.DbColumnExists( 'MetaStudyForm', 'ParentId' ) = 0
  ALTER TABLE dbo.MetaStudyForm ADD ParentId INT
GO

IF dbo.DbColumnExists( 'MetaStudyForm', 'Repeatable' ) = 0
  ALTER TABLE dbo.MetaStudyForm ADD Repeatable BIT
GO

IF dbo.DbColumnExists( 'MetaStudyForm', 'SurveyStatus' ) = 0
  ALTER TABLE dbo.MetaStudyForm ADD SurveyStatus VARCHAR(6)
GO

IF dbo.DbColumnExists( 'MetaStudyForm', 'FormActive' ) = 0
  ALTER TABLE dbo.MetaStudyForm ADD FormActive AS (charindex('Open',[SurveyStatus]))
GO

EXEC dbo.UtilDropDefault 'MetaForm', 'Repeatable'
GO

ALTER TABLE dbo.MetaForm ADD CONSTRAINT DF_MetaForm_Repeatable DEFAULT 1 FOR Repeatable
GO

ALTER PROCEDURE dbo.AddMetaStudyForm( @StudyId INT, @FormId INT, @FormName varchar(24), @FormTitle varchar(128), @FormXML VARCHAR(MAX), @SurveyStatus VARCHAR(6) )
AS
BEGIN
  EXEC dbo.AddMetaForm @FormId, @FormName, @FormTitle, @FormXML, @SurveyStatus;
  IF NOT EXISTS( SELECT StudyFormId FROM dbo.MetaStudyForm WHERE FormId=@FormId AND StudyId=@StudyId )
    INSERT INTO dbo.MetaStudyForm (StudyId,FormId) VALUES (@StudyId,@FormId );
  UPDATE dbo.MetaStudyForm SET SurveyStatus=@SurveyStatus WHERE StudyId=@StudyId AND FormId=@FormId;
END
GO

EXEC AddSchema 'Meta'
GO

IF dbo.DbColumnExists( 'MetaForm', 'Subtitle') = 0 
  ALTER TABLE MetaForm ADD Subtitle VARCHAR(MAX)
GO

IF NOT OBJECT_ID('Meta.StudyForm') IS NULL DROP VIEW Meta.StudyForm
GO

CREATE VIEW Meta.StudyForm WITH SCHEMABINDING AS
  SELECT msf.StudyId,mf.FormId,mf.FormName,mf.FormTitle,mf.Subtitle,
  mf.CalculateInvalid, mf.RatingScale, mf.Copyright,
  mf.ThreadTypeId, mf.Instructions, 
  ISNULL(msf.Repeatable,mf.Repeatable) as Repeatable,
  ISNULL(msf.SurveyStatus,mf.SurveyStatus) AS SurveyStatus, 
  ISNULL(msf.FormActive,mf.FormActive ) AS FormActive,
  msf.ParentId, msf.CreatedAt,msf.CreatedBy
  FROM dbo.MetaForm mf JOIN dbo.MetaStudyForm msf ON msf.FormId=mf.FormId
GO

GRANT SELECT ON Meta.StudyForm TO public
GO
  
EXEC DbLogChange 520, 'Tweak','Added view Meta.StudyForm for simple access to dbo.MetaStudyForm'
GO

ALTER PROCEDURE dbo.GetMyMetaForms( @StudyId INT, @MyProfession INT = 0 ) AS
BEGIN
  SET NOCOUNT ON;
  IF @MyProfession = 1
  BEGIN                                                
    SELECT msf.FormId,count(cf.FormId) as UsedTimes
    INTO #temp
      FROM Meta.StudyForm msf 
      JOIN dbo.ClinForm cf ON cf.FormId=msf.FormId AND cf.CreatedAt > getdate()-365
      JOIN dbo.UserList ul ON ul.UserId=cf.CreatedBy
      JOIN dbo.UserList me ON me.ProfId=ul.ProfId AND me.UserId=USER_ID()
    WHERE msf.StudyId=@StudyId AND dbo.MetaFormIsUsable( msf.FormId ) = 1
      GROUP BY msf.FormId;
    SELECT TOP 15 msf.* FROM Meta.StudyForm msf JOIN #temp t ON t.FormId=msf.FormId WHERE t.UsedTimes > 3 
    ORDER BY UsedTimes DESC;
  END
  ELSE
  BEGIN
    SELECT msf.*  
      FROM Meta.StudyForm msf
      JOIN dbo.UserList ul ON ul.UserId=USER_ID()
      LEFT OUTER JOIN dbo.MetaFormUser mfu ON mfu.FormId=msf.FormId 
    WHERE 
     msf.StudyId=@StudyId AND dbo.MetaFormIsUsable( msf.FormId ) = 1
     AND ul.ProfId=ISNULL(mfu.ProfId,ul.ProfId)     
  END
END
GO


EXEC DbLogChange 520, 'Tweak','Using Meta.StudyForm view in dbo.GetMyMetaForms'
GO

ALTER PROCEDURE dbo.GetMetaForms( @StudyId INT )
AS
BEGIN
  SELECT * FROM Meta.StudyForm WHERE StudyId=@StudyId
END
GO

EXEC DbLogChange 520, 'Tweak','Using Meta.StudyForm view in dbo.GetMetaForms'
GO

IF NOT OBJECT_ID( 'dbo.LabMapping') IS NULL DROP TABLE dbo.LabMapping
GO

CREATE TABLE dbo.LabMapping ( MapId INT NOT NULL IDENTITY(1,1), OrigCodeId INT NOT NULL, MapToCodeId INT, CreatedAt DateTime NOT NULL, CreatedBy INT NOT NULL )
GO
ALTER TABLE dbo.LabMapping ADD CONSTRAINT PK_LabMapping PRIMARY KEY (MapId)
GO
ALTER TABLE dbo.LabMapping ADD CONSTRAINT FK_LabMapping_User FOREIGN KEY ( CreatedBy ) REFERENCES UserList ( UserId )
GO
ALTER TABLE dbo.LabMapping ADD CONSTRAINT DF_LabMapping_CreatedAt DEFAULT getdate() for CreatedAt
GO
ALTER TABLE dbo.LabMapping ADD CONSTRAINT DF_LabMapping_CreatedBy DEFAULT USER_ID() for CreatedBy
GO

EXEC DbLogChange 520, 'Feature','Added LabMapping table to keep track of mappings done'
GO

ALTER PROCEDURE dbo.UpdateLabSynonym( @OrigCodeId INT, @MapToCodeId INT ) AS
BEGIN
  SET XACT_ABORT ON; 
  UPDATE dbo.LabData SET OrigCodeId=@OrigCodeId WHERE LabCodeId=@OrigCodeId AND OrigCodeId IS NULL;
  UPDATE dbo.LabData SET LabCodeId=@MapToCodeId WHERE LabCodeId=@OrigCodeId OR OrigCodeId=@OrigCodeId;
  UPDATE dbo.LabCode SET SynonymId=@MapToCodeId WHERE LabCodeId=@OrigCodeId;
  INSERT INTO dbo.LabMapping (OrigCodeId,MapToCodeId) VALUES( @OrigCodeId,@MapToCodeId );
END
GO

ALTER PROCEDURE dbo.UpdateLabSynonymUndo( @LabCodeId INT ) AS
BEGIN
  SET XACT_ABORT ON; 
  UPDATE dbo.LabData SET LabCodeId=@LabCodeId WHERE OrigCodeId=@LabCodeId;
  UPDATE dbo.LabCode SET VarName=NULL, SynonymId=NULL WHERE LabCodeId=@LabCodeId;
  INSERT INTO dbo.LabMapping (OrigCodeId,MapToCodeId) VALUES( @LabCodeId,NULL );
END
GO

UPDATE UserList SET UserName = 'public' WHERE UserName='Xpublic';
GO

EXEC DbLogChange 520, 'Feature','Added logging to UpdateLabSynonym and UpdateLabSynonymUndo procedures'
GO

EXEC DbLogChange 520, 'Bugfix','Added XACT_ABORT ON to UpdateLabSynonym and UpdateLabSynonymUndo'
GO

EXECUTE DbFinalizeUpgrade 520;
GO

COMMIT TRANSACTION UpgradeTo520;
GO


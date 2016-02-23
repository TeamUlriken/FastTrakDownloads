SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo519;
PRINT 'Starting upgrade to 519'
DELETE FROM DbUpgradeLog WHERE DbVer > 518;

EXEC DbCheckVersion 518;       
EXECUTE DbStartUpgrade 519;
GO

GRANT EXECUTE ON dbo.UtilDropObject TO [superuser] AS [dbo]
GO

IF NOT OBJECT_ID('DbUpgradeChanges') IS NULL 
  DROP TABLE dbo.DbUpgradeChanges
GO

CREATE TABLE dbo.DbUpgradeChanges ( DbVer INT NOT NULL, OrderNumber INT NOT NULL, ChangeType VARCHAR(12) NOT NULL, Details VARCHAR(MAX) NOT NULL )
GO

ALTER TABLE dbo.DbUpgradeChanges ADD CONSTRAINT PK_DbUpgradeChanges PRIMARY KEY (DbVer,OrderNumber )
GO
 
ALTER TABLE dbo.DbUpgradeChanges ADD CONSTRAINT FK_DbUpgradeChanges_DbVer FOREIGN KEY (DbVer) REFERENCES DbUpgradeLog (DbVer) ON DELETE CASCADE
GO

IF NOT OBJECT_ID('DbLogChange') IS NULL DROP PROCEDURE dbo.DbLogChange
GO

CREATE PROCEDURE dbo.DbLogChange( @DbVer INT, @ChangeType VARCHAR(12), @Details VARCHAR(MAX) )
AS
BEGIN  
  DECLARE @OrderNumber INT;
  SELECT @OrderNumber = ISNULL(MAX(OrderNumber),0) FROM DbUpgradeChanges WHERE DbVer=@DbVer;
  INSERT INTO DbUpgradeChanges ( DbVer,OrderNumber,ChangeType,Details) VALUES( @DbVer,@OrderNumber+1,@ChangeType,@Details )
END
GO

GRANT EXECUTE ON dbo.DbLogChange TO [public] AS [dbo]
GO

EXEC DbLogChange 519,'Feature','Added table DbUpgradeChanges and proedure DbLogChange'
GO

GRANT SELECT,UPDATE ON ClinForm TO [public] AS [dbo]
GO

GRANT SELECT ON ClinEvent TO [public] AS [dbo]
GO

IF dbo.DbColumnExists( 'ClinForm','EventNum' ) = 0
  ALTER TABLE ClinForm ADD EventNum INTEGER
GO

IF dbo.DbColumnExists( 'ClinForm','PersonId' ) = 0
  ALTER TABLE ClinForm ADD PersonId INTEGER
GO

EXEC DbLogChange 519,'Tweak','Added columns EventNum,PersonId to ClinForm, to allow new constraint on EventNum,PersonId,FormId'
GO

UPDATE ClinForm SET EventNum = ( SELECT EventNum FROM ClinEvent WHERE EventId=ClinForm.EventId )
GO

UPDATE ClinForm SET PersonId = ( SELECT PersonId FROM ClinEvent WHERE EventId=ClinForm.EventId )
GO

REVOKE UPDATE ON ClinEvent TO [public] AS [dbo]
GO

EXEC DbLogChange 519,'Tweak','Populated columns EventNum,PersonId in ClinForm'
GO

IF EXISTS( SELECT * FROM sysindexes WHERE name = 'IDX_ClinForm_PersonId_EventNum_FormId' ) 
  DROP INDEX ClinForm.IDX_ClinForm_PersonId_EventNum_FormId
GO
 
ALTER TABLE ClinForm ALTER COLUMN EventNum INTEGER NOT NULL
GO

ALTER TABLE ClinForm ALTER COLUMN PersonId INTEGER NOT NULL
GO

EXEC DbLogChange 519,'Tweak','Added NOT NULL constraints on columns EventNum, PersonId in ClinForm'
GO

GRANT SELECT,DELETE ON ClinFormLog TO [public]
GRANT DELETE ON ClinForm TO [public]
GO

DELETE FROM ClinForm WHERE PersonId=9 AND EventNum IN (56520840,942014) AND FormId=106
DELETE FROM ClinForm WHERE PersonId=12 AND EventNum IN (57246540,954109) AND FormId=324
DELETE FROM ClinFormLog WHERE ClinFormId IN (SELECT ClinFormId FROM ClinForm WHERE PersonId=57 AND EventNum IN (57237960,953966) AND FormId=271 )
DELETE FROM ClinForm WHERE PersonId=57 AND EventNum IN (57237960,953966) AND FormId=271
GO

REVOKE DELETE ON ClinFormLog TO [public] AS [dbo]
REVOKE SELECT,UPDATE,DELETE ON ClinForm TO [public] AS [dbo]
GO

CREATE UNIQUE INDEX IDX_ClinForm_PersonId_EventNum_FormId ON dbo.ClinForm (PersonId,EventNum,FormId )
GO 
 
EXEC DbLogChange 519,'Tweak','Adding unique index IDX_ClinForm_PersonId_EventNum_FormId to ClinForm'
GO

ALTER TABLE dbo.MetaNomItem ALTER COLUMN ItemName VARCHAR(MAX)
GO

EXEC DbLogChange 519,'Tweak','Expanding column ItemName on MetaNomItem to VARCHAR(MAX)'
GO

IF NOT OBJECT_ID('dbo.GetCodeList') IS NULL DROP PROCEDURE dbo.GetCodeList
GO

CREATE PROCEDURE dbo.GetCodeList( @OID INT ) AS
BEGIN
  SELECT i.ItemCode,i.ItemName FROM MetaNomItem i
  JOIN MetaNomListItem li ON li.ItemId=i.ItemId
  JOIN MetaNomList l ON l.ListId=li.ListId
  WHERE l.OID = @OID 
  ORDER BY ItemCode 
END
GO

GRANT EXECUTE ON dbo.GetCodeList TO [public] AS [dbo]
GO

EXEC DbLogChange 519,'Feature','Added procedure GetCodeList, preparation for NOM items'
GO

ALTER PROCEDURE dbo.GetClinForms( @StudyId INT, @PersonId INT, @ClinFormId INT = NULL ) AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO CaseLog (PersonId,LogType,LogText)
  VALUES( @PersonId,'LESE','Journal lest av ' + USER_NAME() );
  SELECT e.EventNum,cf.FormId,e.EventId,e.EventTime,mf.FormTitle,mf.FormName,
      cf.ClinFormId,cf.FormStatus,cf.FormComplete,cf.Comment,cf.CachedText,
      mfs.StatusDesc,cf.CreatedAt,cf.SignedAt,
      up1.Signature as CreatedBySign,ul1.ProfId AS CreatedByProfId, cf.CreatedBy,
      up2.Signature AS SignedBySign,ul2.ProfId as SignedByProfId, cf.SignedBy
  FROM ClinEvent e
    JOIN ClinForm cf on cf.EventId=e.EventId AND ( cf.DeletedAt IS NULL )
    JOIN MetaFormStatus mfs ON mfs.FormStatus=cf.FormStatus
    LEFT OUTER JOIN MetaForm mf on mf.FormId=cf.FormId
    LEFT OUTER JOIN UserList ul1 ON ul1.UserId=cf.CreatedBy
    LEFT OUTER JOIN Person up1 ON up1.PersonId=ul1.PersonId
    LEFT OUTER JOIN UserList ul2 ON ul2.UserId=cf.SignedBy
    LEFT OUTER JOIN Person up2 ON up2.PersonId=ul2.PersonId
    WHERE e.PersonId=@PersonId AND ((@ClinFormId IS NULL) OR (ClinFormId=@ClinFormId))
    AND ( e.StudyId=@StudyId OR cf.FormId IN ( SELECT DISTINCT FormId FROM MetaStudyForm WHERE StudyId = @StudyId )) ;
END
GO

EXEC DbLogChange 519, 'Feature','Altered dbo.GetClinForms to return shared forms.'
GO

ALTER PROCEDURE dbo.GetClinData( @SessId INT, @PersonId INT ) AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @UserId INT;     
  DECLARE @StudyId INT;
  SELECT @StudyId=StudyId,@UserId=UserId FROM UserLog WHERE SessId=@SessId AND ClosedAt IS NULL;
  IF ISNULL(@UserId,0) <> USER_ID() 
    RAISERROR( 'The session is already closed or not opened by you!',16,1 )
  ELSE                           
  BEGIN
    SELECT DISTINCT co.RowId,e.EventId,e.EventNum,e.EventTime,co.VarName,co.Quantity,co.DTVal,
      co.EnumVal,co.Locked,co.ChangeCount,co.TextVal
    FROM ClinObservation co
      JOIN dbo.ClinEvent e ON e.EventId=co.EventId
      JOIN dbo.ClinTouch ct ON ct.TouchId=co.TouchId
      JOIN dbo.ClinForm f ON f.EventId=co.EventId AND f.FormId=ISNULL(ct.FormId,f.FormId) AND f.DeletedAt IS NULL
      AND e.PersonId=@PersonId 
      AND ( e.StudyId=@StudyId OR f.FormId IN ( SELECT DISTINCT FormId FROM MetaStudyForm WHERE StudyId = @StudyId ) ) 
    ORDER BY e.EventNum,e.EventId;
  END;
END
GO

EXEC DbLogChange 519, 'Feature','Altered dbo.GetClinData to return data from shared forms.'
GO

ALTER PROCEDURE dbo.AddClinForm( @SessId INT, @PersonId INT, @FormId INT, @EventTime DateTime )
AS
BEGIN
  DECLARE @StudyId INT;
  DECLARE @EventNum INT;
  DECLARE @EventId INT;
  DECLARE @ClinFormId INT;
  DECLARE @DeletedBy INT;        
  DECLARE @StatusId INT;
  DECLARE @GroupId INT;
  SET @StudyId=dbo.GetStudyId( @SessID )
  IF @StudyId IS NULL                                
  BEGIN
    RAISERROR( 'Ugyldig brukerøkt: %d',16,1,@SessId );
    RETURN -1;
  END
  ELSE BEGIN          
    SET @EventNum=dbo.FnEventTimeToNum( @EventTime );
    SET @ClinFormId = NULL;                                             
    
    -- Find Matching ClinFormId in ANY study
    SELECT @ClinFormId=cf.ClinFormId,@EventId=ce.EventId,@DeletedBy=cf.DeletedBy 
    FROM ClinForm cf JOIN ClinEvent ce ON ce.EventId=cf.EventId 
    WHERE ce.PersonId=@PersonId AND cf.FormId=@FormId AND ce.EventNum=@EventNum;
    
    -- If not found, search for matching EventId in this study                        
    IF @EventId IS NULL
      SELECT @EventId=EventId FROM ClinEvent WHERE StudyId=@StudyId AND PersonId=@PersonId AND EventNum=@EventNum;
      
    IF @EventId IS NULL 
    BEGIN         
      -- No matching ClinFormId and no matching EventId
      SELECT @StatusId=StatusId,@GroupId=GroupId FROM StudCase WHERE StudyId=@StudyId AND PersonId=@PersonId;
      IF ( @StatusId IS NULL ) OR ( @GroupId IS NULL )
      BEGIN
        RAISERROR( 'Status og/eller gruppe mangler', 16, 1 );
        RETURN -2;
      END
      INSERT INTO dbo.ClinEvent (StudyId,PersonId,EventNum,StatusId,GroupId)
        VALUES ( @StudyId,@PersonId,@EventNum,@StatusId,@GroupId);
      SET @EventId=SCOPE_IDENTITY()
      SET @ClinFormId = NULL;
    END;
    IF @ClinFormId IS NULL
    BEGIN
      INSERT INTO ClinForm (EventId,FormId,PersonId,EventNum) VALUES (@EventId,@FormId,@PersonId,@EventNum);
      SET @ClinFormId=SCOPE_IDENTITY();
    END
    ELSE IF NOT @DeletedBy IS NULL
      UPDATE ClinForm SET DeletedAt=NULL,DeletedBy=NULL WHERE ClinFormId=@ClinFormId;
  END
  SELECT @EventId AS EventId, @ClinFormId AS ClinFormId, @EventNum AS EventNum;
END;
GO

EXEC DbLogChange 519, 'Tweak','Altered dbo.AddClinForm to populate EventNum and PersonId in ClinForm, and to use existing shared form if possible.'
GO

IF NOT object_id('UpdateClinEventSetTime') IS NULL DROP PROCEDURE UpdateClinEventSetTime
GO

EXEC DbLogChange 519, 'Cleanup','Dropped procedure UpdateClinFormSetTime, has not been used for a while.'
GO

ALTER PROCEDURE dbo.UpdateClinFormSetTime( @ClinFormId INT, @NewEventTime DateTime ) AS
BEGIN
  DECLARE @NewEventId INT;
  DECLARE @PersonId INT;
  DECLARE @NewEventNum INT;
  DECLARE @OldEventId INT;
  DECLARE @StudyId INT;
  DECLARE @FormId INT;
  DECLARE @DeletedBy INT;
  DECLARE @ExistingClinFormId INT;
  DECLARE @ErrMsg VARCHAR(512);                 
  SELECT @StudyId = ce.StudyId, @PersonId=ce.PersonId, @OldEventId=ce.EventId, @FormId=cf.FormId FROM ClinEvent ce
    JOIN ClinForm cf ON cf.EventId=ce.EventId AND cf.ClinFormId=@ClinFormId;
  SET @NewEventNum = dbo.FnEventTimeToNum( @NewEventTime );
  /* Check for existing event */
  SELECT @NewEventId = EventId FROM ClinEvent WHERE StudyId=@StudyId AND PersonId=@PersonId AND EventNum=@NewEventNum;
  IF @NewEventId IS NULL 
  BEGIN
    INSERT INTO ClinEvent (StudyId,PersonId,EventNum) VALUES( @StudyId,@PersonId,@NewEventNum );
    SET @NewEventId=SCOPE_IDENTITY();
  END
  ELSE 
  BEGIN                                                                                     
    /* Event exists, check for existing form that would conflict with this form */
    SELECT @ExistingClinFormId = ClinFormId,@DeletedBy=DeletedBy FROM ClinForm WHERE FormId=@FormId AND EventId=@NewEventId AND ClinFormId<>@ClinFormId;
    IF NOT @ExistingClinFormId IS NULL
    BEGIN
      SET @ErrMsg = 'Skjemaet kan ikke flyttes til ' + dbo.LongTime( @NewEventTime )+ '.\nDet finnes allerede et tilsvarende skjema der!' ;
      IF NOT @DeletedBy IS NULL
        SET @ErrMsg = @ErrMsg + '\nDet andre skjemaet er slettet, så du må evt. angre sletting.';
      RAISERROR( @ErrMsg,16,1 );
      RETURN -1;
    END;
  END;
  UPDATE ClinForm SET EventId=@NewEventId,EventNum=@NewEventNum WHERE ClinFormId=@ClinFormId;
  IF @@ROWCOUNT = 0
    RAISERROR( 'Dette skjemaet kan dessverre ikke flyttes av deg.\nBare egne skjema opprettet siste 24 timer kan flyttes!', 16, 1 )
  ELSE BEGIN
    /* Move orphaned variables */
    EXEC UpdateClinDataEventId @FormId,@OldEventId,@NewEventId;
    IF ( SELECT COUNT(*) FROM ClinForm WHERE EventId=@OldEventId ) = 0
      UPDATE ClinObservation SET EventId=@NewEventId WHERE EventId=@OldEventId;
  END;
END;
GO

EXEC DbLogChange 519, 'Tweak','Altered dbo.UpdateClinFormSetTime to update EventNum when moving form.'
GO

REVOKE UPDATE,INSERT,DELETE ON ClinForm TO [public] AS [dbo]
REVOKE UPDATE,INSERT,DELETE ON ClinEvent TO [public] AS [dbo]
GO

EXEC DbLogChange 519, 'Security','Revoked all modifying privileges on ClinForm and ClinEvent.'
GO

ALTER VIEW NDV.Variabler (dato, pasientid, navn, verdi) 
AS
SELECT ce.EventTime as dato,p.NationalId as pasientid,co.VarName as navn,ISNULL(CONVERT(VARCHAR,co.DTVal,126),ISNULL(CONVERT(VARCHAR,co.EnumVal),CONVERT(VARCHAR,co.Quantity) ) ) as verdi
  FROM dbo.ClinObservation co 
  JOIN dbo.ClinEvent ce ON ce.EventId=co.EventId
  JOIN dbo.Person p ON p.PersonId=ce.PersonId
  JOIN dbo.StudCase sc ON sc.PersonId=p.PersonId AND sc.MarkedForExport=1
  JOIN dbo.Study s ON s.StudyId=sc.StudyId AND StudName = 'NDV'
  WHERE ( co.VarName LIKE 'NDV_%' ) OR ( co.VarName IN ('SYSBP','DIABP','WEIGHT','HEIGHT','WAIST','BMI','HBA1C','DIABETESKOMPLIKASJONER')) OR ( co.VarName LIKE 'ATC_%' )
GO

EXEC DbLogChange 519, 'Feature','Altered view NDV.Variabler to include data from shared forms.'
GO

ALTER FUNCTION dbo.SameData( @RowId INT, @Quantity DECIMAL(18,4), @DTVal DateTime,@EnumVal INT, @TextVal VARCHAR(MAX) ) RETURNS INT
AS 
BEGIN
  DECLARE @RetVal INT;
  DECLARE @OldQuantity DECIMAL(18,4);
  DECLARE @OldDTVal DateTime;
  DECLARE @OldEnumVal INT;
  DECLARE @OldTextVal VARCHAR(MAX);
  SELECT @OldQuantity=Quantity,@OldDTVal=DTVal,@OldEnumVal=EnumVal,@OldTextVal=TextVal
    FROM dbo.ClinObservation WHERE RowId=@RowId;
  IF ( @OldQuantity IS NULL ) 
    AND ( @OldTextVal IS NULL ) 
    AND ( @OldDTVal IS NULL ) 
    AND ( @OldEnumVal IS NULL)
      SET @RetVal = -1
  ELSE 
    IF  (( @OldQuantity=@Quantity ) OR ( @OldQuantity IS NULL AND @Quantity IS NULL )) 
    AND (( @OldDTVal=@DTVal ) OR ( @OldDTVal IS NULL AND @DTVal IS NULL ))
    AND (( @OldTextVal=@TextVal ) OR ( @OldTextVal IS NULL AND @TextVal IS NULL )) 
    AND (( @OldEnumVal=@EnumVal ) OR ( @OldEnumVal IS NULL AND @EnumVal IS NULL ))
      SET @RetVal=1
    ELSE
      SET @RetVal= 0;
  RETURN @RetVal;
END
GO

EXEC DbLogChange 519, 'Bugfix','Altered function dbo.SameData to distinguish between -1 and NULL data.'
GO

GRANT UPDATE,SELECT ON UserLog TO [public] AS [dbo]
GO

EXEC AddStudy 'NoStudy'
GO

UPDATE dbo.UserLog SET StudyId=(SELECT StudyId FROM dbo.Study WHERE StudName='NoStudy' ) WHERE 
NOT EXISTS (SELECT StudyId FROM dbo.Study WHERE StudyId=UserLog.StudyId )
GO

IF dbo.DbConstraintExists( 'FK_UserLog_Study') = 0 
  ALTER TABLE dbo.UserLog ADD CONSTRAINT FK_UserLog_Study FOREIGN KEY (StudyId) REFERENCES dbo.Study(StudyId)
GO

REVOKE UPDATE,SELECT ON UserLog TO [public] AS [dbo]
GO

EXEC DbLogChange 519, 'Bugfix','Added foreign key FK_UserLog_Study on table UserLog.'
GO

IF dbo.DbConstraintExists( 'FK_PersonData_Study') = 0 
  ALTER TABLE Dash.PersonData ADD CONSTRAINT FK_PersonData_Study FOREIGN KEY (StudyId) REFERENCES dbo.Study(StudyId) ON DELETE CASCADE
GO

EXEC DbLogChange 519, 'Tweak','Added foreign key FK_PersonData_Study on table Dash.PersonData (cascading deletes).'
GO

IF dbo.DbConstraintExists( 'FK_PersonData_Person') = 0 
  ALTER TABLE Dash.PersonData ADD CONSTRAINT FK_PersonData_Person FOREIGN KEY (PersonId) REFERENCES dbo.Person(PersonId) ON DELETE CASCADE
GO

EXEC DbLogChange 519, 'Tweak','Added foreign key FK_PersonData_Person on table Dash.PersonData (cascading deletes).'
GO

IF dbo.DbConstraintExists( 'FK_ImportContext_Study') = 0 
  ALTER TABLE dbo.ImportContext ADD CONSTRAINT FK_ImportContext_Study FOREIGN KEY (StudyId) REFERENCES dbo.Study(StudyId)
GO

EXEC DbLogChange 519, 'Bugfix','Added foreign key FK_ImportContext_Study on table ImportContext.'
GO

ALTER PROCEDURE dbo.AddLabData( @PersonId INT, @LabDate DateTime,@LabName varchar(40), @NumResult FLOAT,
  @DevResult INT = NULL, @TxtResult VARCHAR(MAX) = null, @Comment VARCHAR(MAX) = null,
  @ArithmeticComp Char(2) = NULL, @UnitStr varchar(24) = NULL, @BatchId INTEGER = NULL, @RefInterval VARCHAR(MAX) = NULL ) AS
BEGIN
  DECLARE @OrigCodeId INT;
  DECLARE @LabCodeId INT;
  DECLARE @TimeDiff FLOAT;
  DECLARE @LabDataId INT;
  SET NOCOUNT ON;
  SET @TimeDiff=1/24;
  IF @RefInterval = '' SET @RefInterval = NULL;
  /* Map the Code, shoud be fast, because LabName is indexed */
  SELECT @OrigCodeId = LabCodeId FROM LabCode WHERE LabName=@LabName;
  SELECT @LabCodeId = ISNULL(SynonymId,LabCodeId) FROM LabCode WHERE LabCodeId=@OrigCodeId;
  /* Create a new code for this name, if needed */
  IF @OrigCodeId IS NULL
  BEGIN
    INSERT INTO LabCode (LabName) VALUES(@LabName);
    SET @OrigCodeId = SCOPE_IDENTITY();
    SET @LabCodeId = @OrigCodeId;
  END;           
  IF RTRIM(SUBSTRING(@TxtResult,1,255)) ='' SET @TxtResult = NULL; 
  /* Replace only same labdata (code,value,time) created by the same user, or batch-imported */
  UPDATE LabData SET LabCodeId=@LabCodeId,NumResult=@NumResult,
      DevResult=@DevResult,TxtResult=@TxtResult,Comment=@Comment,RefInterval=@RefInterval,
      ArithmeticComp=@ArithmeticComp,UnitStr=@UnitStr,BatchId=@BatchId
    WHERE PersonId=@PersonId AND ( OrigCodeId=@OrigCodeId OR LabCodeId=@LabCodeId )
    AND ( @LabDate=LabDate ) 
    AND ( (NOT @BatchId IS NULL) OR ( CreatedBy=USER_ID() OR NOT BatchId IS NULL ) );
  /* If no replacement was made, try to add the data */
  IF @@ROWCOUNT > 0
     SELECT @@ROWCOUNT as RetCode,'Replacements done' as RetText,@TimeDiff AS TimeDiff
  ELSE BEGIN
    INSERT INTO dbo.LabData (PersonId,LabDate,LabCodeId,OrigCodeId,NumResult,
        DevResult,TxtResult,Comment,RefInterval,
        ArithmeticComp,UnitStr,BatchId)
      VALUES( @PersonId,@LabDate,@LabCodeId,@OrigCodeId,@NumResult,
        @DevResult,@TxtResult,@Comment,@RefInterval,
        @ArithmeticComp,@UnitStr,@BatchId );
    SELECT 0 as RetCode,'Data added' as RetText,@TimeDiff AS TimeDiff
  END
  UPDATE StudCase SET LastWrite=GetDate() WHERE PersonId=@PersonId;
END
GO


EXEC DbLogChange 519, 'Feature','Added optional parameter RefInterval to AddLabData.'
GO

ALTER PROCEDURE dbo.GetLabData ( @PersonId INT ) AS
BEGIN
  SELECT ResultId,LabDate,ld.LabCodeId,lc.LabName,ld.NumResult,ld.DevResult,ld.TxtResult,ld.ArithmeticComp,ld.Comment,ld.RefInterval
  FROM LabData ld
    JOIN dbo.LabCode lc on lc.LabCodeId=ld.LabCodeId
  WHERE ld.PersonId=@PersonId
END
GO

EXEC DbLogChange 519, 'Feature','Added column RefInterval to GetLabData.'
GO


ALTER PROCEDURE dbo.GetClinEvents( @SessId INT, @PersonId INT ) AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @ProfRel INT;
  DECLARE @StudyId INT;
  DECLARE @CenterId INT;
  SET @StudyId=dbo.GetStudyId( @SessID )
  IF @StudyId IS NULL BEGIN
    SELECT -1,'Invalid Session'
  END
  ELSE BEGIN            
    /* Find the center, same as user center */
    SELECT @CenterId=sg.GroupId FROM StudCase sc 
    JOIN StudyGroup sg ON sg.GroupId=sc.GroupId AND sc.PersonId=@PersonId
    JOIN UserList ul ON ul.CenterId=sg.CenterId;
    IF @CenterId IS NULL
      RAISERROR( 'Person not in your center',16,1)
    ELSE BEGIN 
      INSERT INTO CaseLog (PersonId,LogType,LogText)
      VALUES( @PersonId,'LESE','Journal lest av ' + USER_NAME() );
      SELECT e.EventNum,cf.FormId,e.EventId,e.EventTime FROM ClinEvent e
      JOIN ClinForm cf on cf.EventId=e.EventId
      WHERE e.PersonId=@PersonId AND e.StudyId=@StudyId;
    END;
  END;
END
GO

EXEC DbLogChange 519, 'Bugfix','Qualified columns PersonId and StudyId in GetClinEvents.'
GO

IF dbo.DbConstraintExists('FK_CaseLog_Person' ) = 0 
  ALTER TABLE [dbo].[CaseLog] ADD FOREIGN KEY ([PersonId]) REFERENCES [dbo].[Person] ([PersonId])
GO

EXEC DbLogChange 519, 'Bugfix','Added foreign key FK_CaseLog_Person to table CaseLog.'
GO

IF NOT OBJECT_ID('UtilDropDefault') IS NULL DROP PROCEDURE UtilDropDefault
GO

CREATE PROCEDURE dbo.UtilDropDefault( @TableName NVARCHAR(128), @ColName NVARCHAR(128) )
AS
BEGIN
  DECLARE @Command NVARCHAR(MAX)
  SELECT @Command = 'ALTER TABLE ' + @TableName + ' drop constraint ' + d.name
  FROM sys.tables t   
    JOIN sys.default_constraints d ON d.parent_object_id = t.object_id  
    JOIN sys.columns c ON c.object_id = t.object_id      
    AND c.column_id = d.parent_column_id
  WHERE t.name = @TableName
  AND c.name = @ColName;
  IF NOT @Command IS NULL EXECUTE( @Command );
END
GO

IF dbo.DbColumnExists( 'UserLog','SessGuid') = 1  
BEGIN
  EXEC UtilDropDefault 'UserLog','SessGuid'
  ALTER TABLE UserLog DROP COLUMN SessGuid
END  
GO

IF dbo.DbColumnExists( 'UserLog','WebRequest') = 1  ALTER TABLE UserLog DROP COLUMN WebRequest
GO

IF dbo.DbColumnExists( 'UserLog','DomainName') = 1  ALTER TABLE UserLog DROP COLUMN DomainName
GO

IF dbo.DbColumnExists( 'UserLog','RemoteAddr') = 1  ALTER TABLE UserLog DROP COLUMN RemoteAddr
GO

EXEC DbLogChange 519, 'Cleanup','Removed obsolete columns in table UserLog.'
GO

EXEC UtilDropObject 'UtilUpdateRights'
GO

EXEC DbLogChange 519, 'Cleanup','Removed obsolete procedures UtilUpdateRights.'
GO

IF NOT SCHEMA_ID( 'DataImport') IS NULL DROP SCHEMA DataImport
GO

IF NOT SCHEMA_ID( 'Journalansvarlig') IS NULL DROP SCHEMA Journalansvarlig
GO

IF NOT SCHEMA_ID( 'ChangeWorksite') IS NULL DROP SCHEMA ChangeWorksite
GO

IF NOT SCHEMA_ID( 'ChangeProfession') IS NULL DROP SCHEMA ChangeProfession
GO

IF NOT SCHEMA_ID( 'EnterLabdata') IS NULL DROP SCHEMA EnterLabdata
GO

IF NOT SCHEMA_ID( 'superuser') IS NULL DROP SCHEMA superuser
GO

IF NOT SCHEMA_ID( 'PrintPrescription') IS NULL DROP SCHEMA PrintPrescription
GO

EXEC DbLogChange 519, 'Cleanup','Removed unused schemas: DataImport, Journalansvarlig, ChangeWorksite, ChangeProfession, EnterLabdata, superuser, PrintPrescription.'
GO

IF NOT OBJECT_ID('GetCaseListMarevan') IS NULL DROP PROCEDURE dbo.GetCaseListMarevan
GO

IF NOT OBJECT_ID('GetCaseListDigitoxin') IS NULL DROP PROCEDURE dbo.GetCaseListDigitoxin
GO

IF NOT OBJECT_ID('AddSoapSession') IS NULL DROP PROCEDURE dbo.AddSoapSession
GO

EXEC DbLogChange 519, 'Cleanup','Removed unused procedures: GetCaseListMarevan, GetCaseListDigitoxin, AddSoapSession.'
GO

EXECUTE DbFinalizeUpgrade 519;
GO

COMMIT TRANSACTION UpgradeTo519;
GO

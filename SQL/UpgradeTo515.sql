SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo515;
PRINT 'Starting upgrade to 515'
GO

DELETE FROM DbUpgradeLog WHERE DbVer > 514;
EXEC DbCheckVersion 514;       
EXECUTE DbStartUpgrade 515;
GO

IF NOT OBJECT_ID('dbo.UpdateClinDataUnLockRow') IS NULL DROP PROCEDURE UpdateClinDataUnlockRow
GO
IF NOT OBJECT_ID('dbo.ClinThreadData') IS NULL DROP TABLE dbo.ClinThreadData
GO
IF NOT OBJECT_ID('dbo.ClinThread') IS NULL DROP TABLE dbo.ClinThread
GO
IF NOT OBJECT_ID('ClinFormThread') IS NULL DROP TABLE dbo.ClinFormThread
GO

CREATE TABLE dbo.ClinThread ( ThreadId INT IDENTITY(1,1) NOT NULL, StudyId INT NOT NULL, PersonId INT NOT NULL, 
  ThreadName VARCHAR(24), ThreadTypeId INT NOT NULL, 
  CreatedAt DateTime NOT NULL DEFAULT getdate(), CreatedBy INT NOT NULL DEFAULT user_id() )
GO
                         
ALTER TABLE dbo.ClinThread ADD CONSTRAINT PK_ClinThread PRIMARY KEY (ThreadId )
GO
ALTER TABLE dbo.ClinThread ADD CONSTRAINT FK_ClinThread FOREIGN KEY (ThreadTypeId ) REFERENCES dbo.MetaThreadType( V )
ALTER TABLE dbo.ClinThread ADD CONSTRAINT FK_ClinThread_Study FOREIGN KEY (StudyId ) REFERENCES dbo.Study( StudyId )
ALTER TABLE dbo.ClinThread ADD CONSTRAINT FK_ClinThread_Person FOREIGN KEY (PersonId ) REFERENCES dbo.Person( PersonId )

CREATE UNIQUE INDEX IDX_ClinThread_StudyPersonTypeName ON ClinThread( StudyId,PersonId,ThreadTypeId,ThreadName )
GO

CREATE TABLE dbo.ClinThreadData (
    RowId INT IDENTITY(1,1) NOT NULL, EventId INT NOT NULL, TouchId INT NOT NULL, ItemId INT NOT NULL, ThreadId INT NOT NULL, 
    Quantity DECIMAL(18,4),  DTVal DateTime, EnumVal INT,TextVal VARCHAR(MAX), ObsDate DateTime DEFAULT getdate(), 
    Locked INT DEFAULT 0, LockedAt DateTime, LockedBy INT, ChangeCount TinyInt DEFAULT 0 )
GO

ALTER TABLE dbo.ClinThreadData ADD CONSTRAINT PK_ClinThreadData PRIMARY KEY(RowId)
GO
ALTER TABLE dbo.ClinThreadData ADD CONSTRAINT FK_ClinThreadData_ClinEvent FOREIGN KEY(EventId) REFERENCES dbo.ClinEvent( EventId )
GO
ALTER TABLE dbo.ClinThreadData ADD CONSTRAINT FK_ClinThreadData_ClinTouch FOREIGN KEY(TouchId) REFERENCES dbo.ClinTouch( TouchId )
GO
ALTER TABLE dbo.ClinThreadData ADD CONSTRAINT FK_ClinThreadData_MetaItem FOREIGN KEY(ItemId) REFERENCES dbo.MetaItem( ItemId )
GO
ALTER TABLE dbo.ClinThreadData ADD CONSTRAINT FK_ClinThreadData_ClinThread FOREIGN KEY(ThreadId) REFERENCES dbo.ClinThread( ThreadId )
GO
CREATE UNIQUE INDEX IDX_ClinThread_EventItemThread ON ClinThreadData( EventId,ItemId,ThreadId)
GO

IF NOT OBJECT_ID('dbo.GetClinFormThreads') IS NULL DROP PROCEDURE dbo.GetClinFormThreads
GO

CREATE PROCEDURE dbo.GetClinFormThreads( @ClinFormId INT )
AS
BEGIN
  SELECT ct.ThreadId,ct.ThreadName,mt.FixedThreads 
  FROM ClinForm cf  
  JOIN ClinEvent ce ON ce.EventId=cf.EventId
  JOIN MetaForm mf ON mf.FormId=cf.FormId 
  JOIN MetaThreadType mt ON mt.V = mf.ThreadTypeId
  JOIN ClinThread ct ON ct.StudyId=ce.StudyId AND ct.PersonId=ce.PersonId AND ct.ThreadTypeId=mf.ThreadTypeId
  WHERE cf.ClinFormId=@ClinFormId
  
  UNION 
  
  SELECT 0,NewThreadName,FixedThreads 
  FROM ClinForm cf
  JOIN MetaForm mf ON mf.FormId=cf.FormId 
  JOIN MetaThreadType mt ON mt.V = mf.ThreadTypeId 
  WHERE cf.ClinFormId=@ClinFormId AND mt.FixedThreads=0
  
  ORDER BY ct.ThreadId
END
GO


GRANT EXECUTE ON dbo.GetClinFormThreads TO [public]
GO

UPDATE MetaForm SET ThreadTypeId=3 WHERE FormId=508
GO

IF NOT OBJECT_ID('dbo.AddClinThread') IS NULL DROP PROCEDURE dbo.AddClinThread
GO

CREATE PROCEDURE dbo.AddClinThread( @ClinFormId INT, @ThreadName VARCHAR(24) )
AS
BEGIN
  DECLARE @ThreadTypeId INT;
  DECLARE @StudyId INT;
  DECLARE @PersonId INT;                                                                                                           
  DECLARE @ThreadId INT;
  -- Find threadTypeId
  SELECT @ThreadTypeId = mf.ThreadTypeId,@PersonId=ce.PersonId,@StudyId=ce.StudyId 
    FROM MetaForm mf 
      JOIN ClinForm cf ON cf.FormId=mf.FormId
      JOIN ClinEvent ce ON ce.EventId = cf.EventId 
    WHERE cf.ClinFormId=@ClinFormId;  
  SELECT @ThreadId = ThreadId FROM dbo.ClinThread WHERE StudyId=@StudyId AND PersonId=@PersonId AND ThreadTypeId=@ThreadTypeId AND ThreadName=@ThreadName;
  IF @ThreadId IS NULL                                                                                                            
  BEGIN
    INSERT INTO dbo.ClinThread( StudyId,PersonId,ThreadName,ThreadTypeId) VALUES( @StudyId,@PersonId,@ThreadName,@ThreadTypeId );
    SET @ThreadId = SCOPE_IDENTITY();
  END
  SELECT @ThreadId AS ThreadId, @ThreadName AS ThreadName;
END
GO

GRANT EXECUTE ON dbo.AddClinThread TO public
GO

IF NOT OBJECT_ID('dbo.DeleteClinThread') IS NULL DROP PROCEDURE DeleteClinThread
GO

CREATE PROCEDURE dbo.DeleteClinThread( @ThreadId INT ) AS
BEGIN
  DECLARE @FixedThreads BIT;
  SELECT @FixedThreads = FixedThreads FROM MetaThreadType mt JOIN ClinThread ct ON ct.ThreadTypeId=mt.V WHERE ct.ThreadId=@ThreadId;
  IF @FixedThreads = 1
    RAISERROR( 'This is a fixed thread and can not be deleted.', 16, 1 )
  ELSE
  BEGIN          
    DECLARE @DataRowCount INT;
    SELECT @DataRowCount = COUNT(RowId) FROM ClinThreadData WHERE ThreadId=@ThreadId;
    IF @DataRowCount = 0 
      DELETE FROM ClinThread WHERE ThreadId=@ThreadId
    ELSE
      RAISERROR( 'This thread has data and can not be deleted.', 16, 1 );
  END
END
GO

GRANT EXECUTE ON dbo.DeleteClinThread TO public
GO

IF NOT OBJECT_ID('dbo.RenameClinThread') IS NULL DROP PROCEDURE RenameClinThread
GO

CREATE PROCEDURE dbo.RenameClinThread( @ThreadId INT, @ThreadName VARCHAR(24) )
AS
BEGIN
  -- Fails if existing thread with the same name, unique index
  UPDATE ClinThread SET ThreadName = @ThreadName WHERE ThreadId=@ThreadId; 
END
GO

GRANT EXECUTE ON dbo.RenameClinThread TO public
GO

IF NOT OBJECT_ID('dbo.GetClinThreadData') IS NULL DROP PROCEDURE GetClinThreadData
GO

CREATE PROCEDURE dbo.GetClinThreadData( @ThreadId INT )
AS
BEGIN
  SELECT co.RowId,e.EventId,e.EventNum,e.EventTime,mi.VarName,co.Quantity,co.DTVal,
    co.EnumVal,co.Locked,co.ChangeCount,co.TextVal,co.ThreadId,co.ItemId
  FROM ClinThreadData co 
    JOIN MetaItem mi ON mi.ItemId=co.ItemId
    JOIN ClinEvent e ON e.EventId=co.EventId
  WHERE co.ThreadId=@ThreadId;
END
GO

GRANT EXECUTE ON GetClinThreadData to public
GO


IF NOT OBJECT_ID('dbo.UpdateClinThreadData') IS NULL DROP PROCEDURE UpdateClinThreadData
GO


CREATE PROCEDURE dbo.UpdateClinThreadData ( @RowId INT, @TouchId INT, @Quantity decimal(18,4),@DTVal DateTime, @EnumVal int, @TextVal VARCHAR(MAX) )
AS
BEGIN
  DECLARE @Locked INT;
  DECLARE @ItemId INT;
  SELECT @Locked = Locked, @ItemId = ItemId FROM ClinThreadData WHERE RowId=@RowId;
  IF @Locked = 1
  BEGIN
    RAISERROR( 'Threaded datapoint with RowId=%d and ItemId=%d is locked.',16,1,@RowId,@ItemId ) 
    RETURN -1;
  END
  UPDATE ClinThreadData SET
    Quantity=@Quantity,DTVal=@DTVal,EnumVal=@EnumVal,TextVal=@TextVal,
    ObsDate=GetDate(),TouchId=@TouchId,ChangeCount=ChangeCount+1
  WHERE ( RowId=@RowId ) AND ( Locked = 0 )
  AND
    ( 
      ( ISNULL(Quantity,-1) <> ISNULL(@Quantity,-1) ) OR 
      ( ISNULL(DTVal,'1899-12-30') <> ISNULL(@DTVal,'1899-12-30' ) ) OR 
      ( ISNULL(EnumVal,-1) <> ISNULL(@EnumVal,-1 ) ) OR 
      ( ISNULL(TextVal,'') <> ISNULL(@TextVal,'') )
    )
END
GO

GRANT EXECUTE ON dbo.UpdateClinThreadData TO [public]
GO

IF NOT OBJECT_ID('dbo.AddClinThreadData') IS NULL DROP PROCEDURE AddClinThreadData
GO

CREATE PROCEDURE dbo.AddClinThreadData ( @TouchId INT, @ThreadId INT, @ItemId INT, @Quantity decimal(18,4),
  @DTVal DateTime, @EnumVal int, @TextVal VARCHAR(MAX) )
AS
BEGIN
  DECLARE @EventId INT;
  DECLARE @RowId INT;
  DECLARE @Locked INT;
  DECLARE @MsgResult VARCHAR(32);  
  SET NOCOUNT ON;
  -- Make sure the TouchId is valid, matches an open session, and find the matching EventId
  SELECT @EventId=EventId FROM dbo.ClinTouch t 
    JOIN dbo.UserLog u on (u.SessId=t.SessId ) AND ( u.ClosedAt IS NULL ) AND (u.UserId=USER_ID())
    WHERE (t.TouchId=@TouchId) AND (t.CreatedBy=USER_ID())
  IF @EventId IS NULL
  BEGIN
    RAISERROR( 'Invalid SessId, UserId or TouchId.', 16, 1 );
    RETURN -1;
  END
  ELSE 
  BEGIN  
    -- Find row to update
    SELECT @RowId=RowId, @Locked=Locked FROM dbo.ClinThreadData WHERE EventId=@EventId AND ItemId=@ItemId AND ThreadId=@ThreadId;          
    IF @RowId IS NULL
    BEGIN
      INSERT INTO dbo.ClinThreadData (TouchId,ItemId,ThreadId,Quantity,DTVal,EnumVal,TextVal,EventId)
        VALUES (@TouchId,@ItemId,@ThreadId,@Quantity,@DTVal,@EnumVal,@TextVal,@EventId)
      SET @RowId = SCOPE_IDENTITY();
      SET @MsgResult = 'Data inserted';
    END
   -- Make sure it is unlocked
    ELSE IF @Locked = 0
    BEGIN
      UPDATE dbo.ClinThreadData SET TouchId=@TouchId, Quantity=@Quantity, DTVal=@DTVal, EnumVal=@EnumVal, TextVal=@TextVal
      WHERE RowId=@RowId;      
      SET @MsgResult = 'Data updated';
    END  
    ELSE
    BEGIN
      RAISERROR( 'Variable %d is already locked', 16, 1, @ItemId );
      RETURN -2;
    END;                                               
  END
  SELECT @RowId AS RowId,0 AS Locked,@MsgResult AS MsgResult;
END
GO

GRANT EXECUTE ON dbo.AddClinThreadData TO [public]
GO

IF NOT OBJECT_ID('dbo.UpdateClinThreadLockRow') IS NULL DROP PROCEDURE UpdateClinThreadLockRow
GO

CREATE PROCEDURE dbo.UpdateClinThreadLockRow( @RowId INT ) AS
  UPDATE dbo.ClinThreadData SET Locked=1,LockedAt=GetDate(),LockedBy=USER_ID()
  WHERE RowId=@RowId AND Locked=0;
  IF @@ROWCOUNT=1
    PRINT 'The row was successfully locked'
  ELSE BEGIN
    PRINT 'The row could not be locked';
    RAISERROR( 'Row %d could not be locked',1,16,@RowId );
  END
GO

GRANT EXECUTE ON dbo.UpdateClinThreadLockRow TO [public]
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
    UPDATE dbo.ClinForm SET SignedAt=NULL,SignedBy=NULL,FormStatus='I' WHERE ClinFormId=@ClinFormId;
    SELECT @EventId = EventId,@FormId = FormId FROM ClinForm WHERE ClinFormId=@ClinFormId;
    UPDATE ClinObservation SET LockedAt=NULL,LockedBy=NULL,Locked=0
      WHERE TouchId IN ( SELECT TouchId FROM ClinTouch WHERE EventId=@EventId AND FormId=@FormId);
    UPDATE ClinThreadData SET LockedAt=NULL,LockedBy=NULL,Locked=0
      WHERE TouchId IN ( SELECT TouchId FROM ClinTouch WHERE EventId=@EventId AND FormId=@FormId);
    RETURN;
  END
  ELSE
  BEGIN  
    RAISERROR( @MessageText, 16,1 )
    RETURN -2;
  END;
END
GO
  
UPDATE Person SET FstName=RTRIM(LTRIM(FstName)) WHERE FstName <> LTRIM(LTRIM(FstName))
GO

UPDATE Person SET LstName=RTRIM(LTRIM(LstName)) WHERE LstName <> RTRIM(LTRIM(LstName))
GO

UPDATE Person SET NationalId=NULL WHERE NationalId=''
GO

IF dbo.DbColumnExists( 'MetaForm','MustFollow' ) = 1
 ALTER TABLE MetaForm DROP COLUMN MustFollow
GO

IF dbo.DbColumnExists( 'MetaForm','ParentId' ) = 0
 ALTER TABLE MetaForm ADD ParentId INT
GO

UPDATE MetaForm SET ParentId=472 WHERE FormId=508
UPDATE MetaForm SET ParentId=472 WHERE FormId=490
UPDATE MetaForm SET ParentId=472 WHERE FormId=509
UPDATE MetaForm SET ParentId=472 WHERE FormId=510
UPDATE MetaForm SET ParentId=472 WHERE FormId=518
UPDATE MetaForm SET ParentId=472 WHERE FormId=524
UPDATE MetaForm SET ParentId=472 WHERE FormId=554
UPDATE MetaForm SET ParentId=509 WHERE FormId=547
UPDATE MetaForm SET ParentId=509 WHERE FormId=525
UPDATE MetaForm SET ParentId=525 WHERE FormId=548
UPDATE MetaForm SET ParentId=525 WHERE FormId=526
UPDATE MetaForm SET ParentId=526 WHERE FormId=549
UPDATE MetaForm SET ParentId=508 WHERE FormId=507
UPDATE MetaForm SET ParentId=507 WHERE FormId=550
UPDATE MetaForm SET ParentId=507 WHERE FormId=550
UPDATE MetaForm SET ParentId=526 WHERE FormId=523
GO

ALTER PROCEDURE dbo.LoadStudyCase( @StudyId INT, @PersonId INT )
AS
BEGIN
  SELECT p.*,sc.*,sg.*,ss.*,c.*,mr.*,
     up.Signature as PrimaryContactSign,up.FullName as PrimaryContactName
    FROM Person p
    LEFT OUTER JOIN dbo.StudCase sc ON sc.PersonId=p.PersonId AND sc.StudyId=@StudyId
    LEFT OUTER JOIN StudyStatus ss ON ss.StudyId=@StudyId AND ss.StatusId=sc.FinState
    LEFT OUTER JOIN StudyGroup sg ON sg.StudyId=@StudyId AND sg.GroupId=sc.GroupId
    LEFT OUTER JOIN StudyCenter c ON c.CenterId=sg.CenterId
    LEFT OUTER JOIN ClinRelation cr ON cr.PersonId=sc.PersonId AND cr.UserId=USER_ID() AND ExpiresAt>getdate()
    LEFT OUTER JOIN MetaRelation mr ON mr.RelId = cr.RelId
    LEFT OUTER JOIN UserList ul ON ul.UserId=sc.HandledBy
    LEFT OUTER JOIN Person up ON up.PersonId=ul.PersonId
  WHERE p.PersonId=@PersonId
END
GO

ALTER PROCEDURE dbo.AddPerson( 
  @DOB DateTime,
  @FstName VARCHAR(30),
  @MidName VARCHAR(30),
  @LstName VARCHAR(30),
  @GenderId INT,
  @NationalId VARCHAR(16) = NULL )
AS
BEGIN
  DECLARE @MatchCount INT;
  DECLARE @PersonId INT;
  SET NOCOUNT ON;
  SET @FstName = LTRIM(RTRIM(@FstName));
  SET @LstName = LTRIM(RTRIM(@LstName));
  SET @MidName = LTRIM(RTRIM(@MidName));
  IF Datalength(@NationalId)<11 SET @NationalId=NULL;
  IF NOT @NationalId IS NULL SELECT @MatchCount = COUNT(*) FROM Person WHERE NationalId=@NationalId;
  IF @MatchCount = 1
    SELECT @PersonId=PersonId FROM Person WHERE NationalId=@NationalId
  ELSE IF @MatchCount > 1
    SET @PersonId = -@MatchCount
  ELSE BEGIN
    SELECT @MatchCount = COUNT(*) FROM Person WHERE DOB=@DOB and FstName=@FstName AND LstName=@LstName AND GenderId=@GenderId;
    IF @MatchCount = 1
      SELECT @PersonId=PersonId FROM Person WHERE DOB=@DOB and FstName=@FstName AND LstName=@LstName AND GenderId=@GenderId;
    ELSE IF @MatchCount > 1
      SET @PersonId = -@MatchCount
    ELSE BEGIN
      INSERT INTO Person (DOB,FstName,MidName,LstName,GenderId,NationalId)
        VALUES(@DOB,@FstName,@MidName,@LstName,@GenderId,@NationalId);
      SET @PersonId = SCOPE_IDENTITY();
    END;
  END;
  SELECT @PersonId AS PersonId;
  RETURN ISNULL(@PersonId,-1);
END
GO

ALTER PROCEDURE dbo.UpdatePerson( @PersonId INT, @DOB DateTime, @GenderId TinyInt, @FstName VARCHAR(30), @LstName VARCHAR(30), @NationalId VARCHAR(16) ) AS
BEGIN
  UPDATE Person SET NationalId=NULL WHERE PersonId=@PersonId;
  UPDATE Person SET GenderId=@GenderId,DOB=@DOB,FstName=LTRIM(RTRIM(@FstName)),LstName=LTRIM(RTRIM(@LstName)),NationalId=@NationalId WHERE PersonId=@PersonId;
END
GO

ALTER TRIGGER dbo.T_StudCase_Update ON StudCase
AFTER UPDATE AS 
 BEGIN
  INSERT INTO StudCaseLog (StudCaseId,OldStatusId,OldGroupId,OldHandler,NewStatusId,NewGroupId,NewHandler)
    SELECT o.StudCaseId,o.FinState,o.GroupId,o.HandledBy,n.FinState,n.GroupId,n.HandledBy
    FROM deleted o JOIN inserted n on n.StudCaseId=o.StudCaseId
    AND (( o.FinState<>n.FinState) OR (ISNULL(o.GroupId,0)<>ISNULL(n.GroupId,0)) OR ( o.HandledBy<>n.HandledBy) )
END
GO

IF dbo.DbColumnExists( 'ClinEvent','StatusId' ) = 0
  ALTER TABLE dbo.ClinEvent ADD StatusId INT
GO

IF dbo.DbColumnExists( 'ClinEvent','GroupId' ) = 0
  ALTER TABLE dbo.ClinEvent ADD GroupId INT  
GO

IF dbo.DbColumnExists( 'ClinEvent','EventTimeOld' ) = 1
  ALTER TABLE dbo.ClinEvent DROP COLUMN EventTimeOld  
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
    SELECT @EventId=EventId FROM ClinEvent WHERE StudyId=@StudyId AND PersonId=@PersonId AND EventNum=@EventNum;
    IF @EventId IS NULL 
    BEGIN  
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
    END
    ELSE
      SELECT @ClinFormId = ClinFormId, @DeletedBy = DeletedBy FROM ClinForm WHERE EventId=@EventId AND FormId=@FormId;
    IF @ClinFormId IS NULL
    BEGIN
      INSERT INTO ClinForm (EventId,FormId) VALUES (@EventId,@FormId);
      SET @ClinFormId=SCOPE_IDENTITY();
    END
    ELSE IF NOT @DeletedBy IS NULL
      UPDATE ClinForm SET DeletedAt=NULL,DeletedBy=NULL WHERE ClinFormId=@ClinFormId;
  END
  SELECT @EventId AS EventId, @ClinFormId AS ClinFormId, @EventNum AS EventNum;
END;
GO

IF NOT OBJECT_ID('UserRoleInfo') IS NULL DROP TABLE dbo.UserRoleInfo
GO
 
CREATE TABLE dbo.UserRoleInfo ( RoleName sysname NOT NULL, RoleCaption VARCHAR(24), 
  RoleInfo VARCHAR(MAX), IsActive BIT DEFAULT 1 )
GO

ALTER TABLE dbo.UserRoleInfo ADD CONSTRAINT PK_UserRoleInfo PRIMARY KEY(RoleName)
GO


IF NOT OBJECT_ID('ResetUserRoleInfo') IS NULL DROP PROCEDURE dbo.ResetUserRoleInfo
GO

CREATE PROCEDURE dbo.ResetUserRoleInfo
AS
BEGIN
  DELETE FROM UserRoleInfo WHERE 1=1
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('PrintPrescription'  ,'Forskrivningsrett',  'Gir tillatelse til utskrift av egne resepter.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('DrugPrescriber'     ,'Resepter',           'Gir tillatelse til å klargjøre resepter.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('Journalansvarlig'   ,'Journalansvarlig',   'Gir visse lovbestemte rettigheter og plikter rundt endring av journal.  Gjelder bare for de pasienter man er journalansvarlig for.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('superuser'          ,'Superbruker',        'Gir enkelte rettigheter rundt oppdatering av faginnhold i systemet.  Superbruker bør også tildeles rollen Tilgangsstyring (db_accessadmin).' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('db_accessadmin'     ,'Tilgangsstyring',    'Gir tillatelse til å legge til/fjerne brukere, samt tildele andre roller til brukerne.  Kan bare tildeles av systemeier (db_owner).' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('db_owner'           ,'Systemeier',         'Gir alle rettigheter lokalt i databasen, inkludert alle oppgraderinger. Kan bare tildeles av andre med samme rolle.  Overstyrer alle andre roller.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('ChangeWorksite'     ,'Ambulering',         'Gir tillatelse til å bytte arbeidssted selv.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('ChangeProfession'   ,'Bytte yrke',         'Gir tillatelse til å bytte mellom flere yrker selv.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('DataImport'         ,'Importere data',     'Brukes for automatiske prosesser for dataimport.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('EnterLabdata'       ,'Redigere labarket',  'Gir tillatelse til å redigere laboratoriebildet.' )
  UPDATE UserRoleInfo SET IsActive=0 WHERE RoleName IN ('EnterLabData','ProtocolOwner'    ,'DataImport')
END
GO
  
GRANT EXECUTE ON dbo.ResetUserRoleInfo TO [public]
GO

EXEC ResetUserRoleInfo
GO

ALTER PROCEDURE dbo.GetRoles AS
BEGIN
  SELECT principal_id as RoleId,name as RoleName,uri.RoleCaption,uri.RoleInfo
  FROM sys.database_principals 
  LEFT OUTER JOIN UserRoleInfo uri ON name=uri.RoleName 
  WHERE type='R' AND uri.IsActive=1
  ORDER BY RoleName
END
GO

IF NOT OBJECT_ID('GBD.Tvangsvedtak') IS NULL DROP VIEW GBD.Tvangsvedtak
GO

CREATE VIEW GBD.Tvangsvedtak AS
  SELECT ce.StudyId,ce.PersonId,ce.EventTime,co0.DTVal AS StartDate,co1.DTVal as StopDate,ISNULL(co2.EnumVal,1) AS StopAction,CONVERT(INT,getdate()-co1.DTVal) AS DaysPastDue,
    cf.ClinFormId
  FROM dbo.ClinEvent ce
  JOIN dbo.ClinForm cf ON cf.EventId=ce.EventId AND cf.DeletedAt IS NULL
  JOIN dbo.MetaForm mf ON mf.FormId=cf.FormId AND mf.FormName='TVANGSVEDTAK'
  LEFT OUTER JOIN dbo.ClinObservation co0 ON co0.EventId=ce.EventId AND co0.VarName='TVANG_START' 
  LEFT OUTER JOIN dbo.ClinObservation co1 ON co1.EventId=ce.EventId AND co1.VarName='TVANG_SLUTT' 
  LEFT OUTER JOIN dbo.ClinObservation co2 ON co2.EventId=ce.EventId AND co2.VarName='TVANG_SLUTT_AKSJON'
GO 

GRANT SELECT ON GBD.Tvangsvedtak TO [public]
GO

IF dbo.DbColumnExists('DbProcList','MinVersion' ) = 0
  ALTER TABLE dbo.DbProcList Add MinVersion INT
GO

IF dbo.DbColumnExists('DbProcList','MaxVersion' ) = 0
  ALTER TABLE dbo.DbProcList Add MaxVersion INT
GO

IF dbo.DbColumnExists('DSSRule','MinVersion' ) = 0
  ALTER TABLE dbo.DSSRule ADD MinVersion INT
GO

IF dbo.DbColumnExists('DSSRule','MaxVersion' ) = 0
  ALTER TABLE dbo.DSSRule Add MaxVersion INT
GO

IF NOT OBJECT_ID('GetLastEnumVal') IS NULL DROP FUNCTION dbo.GetLastEnumVal
GO

CREATE FUNCTION dbo.GetLastEnumVal( @PersonId INT, @VarName VARCHAR(24) ) RETURNS INT
AS
BEGIN
 DECLARE @RetVal INT;
 SET @RetVal = ( SELECT TOP 1 co.EnumVal FROM ClinObservation co 
   JOIN dbo.ClinEvent ce ON ce.EventId=co.EventId 
   JOIN dbo.ClinTouch ct ON ct.TouchId=co.TouchId
   JOIN dbo.ClinForm cf ON cf.EventId=ct.EventId AND cf.FormId=ct.FormId AND cf.DeletedAt IS NULL
   WHERE ( ce.PersonId=@PersonId ) AND ( co.VarName=@VarName ) AND ISNULL(co.EnumVal,-1) >= 0 
   ORDER BY ce.EventNum DESC );
   RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetLastEnumVal TO [public]
GO

IF dbo.DbColumnExists( 'MetaForm', 'HelpText' ) = 1
  ALTER TABLE MetaForm DROP COLUMN HelpText
GO


ALTER PROCEDURE dbo.UpdateClinDataEventId( @FormId INT, @OldEventId INT, @NewEventId INT )
AS
BEGIN
  -- Find variable names on this form
  SELECT mi.ItemId,mi.VarName INTO #FormItems 
  FROM dbo.MetaItem mi JOIN dbo.MetaFormItem mfi ON mfi.ItemId=mi.ItemId
  WHERE mfi.FormId=@FormId;                                                                       
  -- Make non-greedy by deleting all items found in other forms
  DELETE FROM #FormItems WHERE ItemId IN (SELECT mfi.ItemId FROM dbo.MetaFormItem mfi
  WHERE mfi.FormId IN ( SELECT FormId FROM dbo.ClinForm WHERE EventId=@OldEventId AND FormId <> @FormId));
  -- Move all standard variables
  UPDATE dbo.ClinObservation SET EventId = @NewEventId WHERE EventId = @OldEventId
  AND VarName IN ( SELECT VarName FROM #FormItems ); 
  -- Move all threaded variables
  UPDATE dbo.ClinThreadData SET EventId = @NewEventId WHERE EventId = @OldEventId
  AND ItemId IN ( SELECT ItemId FROM #FormItems ); 
END
GO

EXECUTE DbFinalizeUpgrade 515;
GO

COMMIT TRANSACTION UpgradeTo515;
GO


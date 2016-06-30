--BEGIN TRANSACTION UpgradeTo6316;
--GO

PRINT 'Overall purpose: Connecting dbo.ClinForm with dbo.UserLog to track profession for creator/signer of ClinForm rows.'

--  ADD column ProfId to table UserLog to track profession for every session
--  ADD columns CreatedSessId and SignedSessId to table ClinForm to track session for creation and signing
--  ALTER procedure dbo.AddSession to include ProfId in UserLog
--  ALTER procedure dbo.AddClinForm to store SessId with creation of form

--EXECUTE dbo.DbStartUpgrade 6315, 6316;
--GO


PRINT '--  ADD column ProfId to table dbo.UserLog to track profession for every session'
GO

IF dbo.DbColumnExists( 'UserLog', 'ProfId') = 0
  ALTER TABLE dbo.UserLog ADD ProfId INT NULL, FOREIGN KEY(ProfId) REFERENCES dbo.MetaProfession(ProfId)
GO

PRINT '--  ADD columns CreatedSessId and SignedSessId to table dbo.ClinForm to track session for creation and signing'
GO

IF dbo.DbColumnExists( 'ClinForm', 'CreatedSessId') = 0
  ALTER TABLE dbo.ClinForm ADD CreatedSessId INT NULL, FOREIGN KEY(CreatedSessId) REFERENCES dbo.UserLog(SessId)
GO

IF dbo.DbColumnExists( 'ClinForm', 'SignedSessId') = 0
  ALTER TABLE dbo.ClinForm ADD SignedSessId INT NULL, FOREIGN KEY(SignedSessId) REFERENCES dbo.UserLog(SessId)
GO


PRINT '--  ALTER procedure dbo.AddSession to include ProfId in table dbo.UserLog'
GO

ALTER PROCEDURE dbo.AddSession( @StudyId INT, @CompName NVARCHAR(128), @CompUser NVARCHAR(128), @CompTime DateTime, @AppVer VARCHAR(50)   )
AS
BEGIN
  DECLARE @ExpectedUserName NVARCHAR(128);
  /* Check for existing user in UserList, create if needed */
  IF NOT EXISTS( SELECT 1 FROM dbo.UserList WHERE UserId=USER_ID() )
    INSERT INTO dbo.UserList (UserId,UserName,IsActive) VALUES(USER_ID(),USER_NAME(),1);
  /* Check for existing user in StudyUser, create if needed */
  IF NOT EXISTS( SELECT 1 FROM dbo.StudyUser WHERE StudyId=@StudyId AND UserId=USER_ID() )
    INSERT INTO dbo.StudyUser (StudyId,UserId) VALUES(@StudyId,USER_ID());
  /* Make sure user name is a match and that the user is active */                              
  SELECT @ExpectedUserName = UserName FROM dbo.UserList WHERE ( UserId=USER_ID()) AND ISNULL(IsActive,1)=1;
  /* Add Session if user is active and matches expected name */
  IF @ExpectedUserName IS NULL
  BEGIN
    RAISERROR( 'Your application account has been deactivated.\nPlease contact a superuser to reactivate it.', 16, 1 );
    RETURN -1;
  END
  ELSE IF @ExpectedUserName=USER_NAME() 
  BEGIN
    /* Finally add log entry */
    INSERT INTO dbo.UserLog (StudyId,CompName,CompUser,CompTime,AppVer)
      VALUES(@StudyId,@CompName,@CompUser,@CompTime,@AppVer );
    SELECT SCOPE_IDENTITY() AS SessId;
  END
  ELSE
  BEGIN
    RAISERROR( 'The username "%s" seems to be invalid.\nCopy this error message and contact local support.', 16, 1, @ExpectedUserName );
    RETURN -2;
  END
END;
GO

PRINT '--  ALTER procedure dbo.AddClinForm to store SessId with creation of form'
GO

ALTER PROCEDURE dbo.AddClinForm( @SessId INT, @PersonId INT, @FormId INT, @EventTime DateTime ) AS
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
    FROM dbo.ClinForm cf JOIN dbo.ClinEvent ce ON ce.EventId=cf.EventId 
    WHERE ce.PersonId=@PersonId AND cf.FormId=@FormId AND ce.EventNum=@EventNum;
    
    -- If not found, search for matching EventId in this study                        
    IF @EventId IS NULL
      SELECT @EventId=EventId FROM dbo.ClinEvent WHERE StudyId=@StudyId AND PersonId=@PersonId AND EventNum=@EventNum;
      
    IF @EventId IS NULL 
    BEGIN         
      -- No matching ClinFormId and no matching EventId
      SELECT @StatusId=StatusId,@GroupId=GroupId FROM dbo.StudCase WHERE StudyId=@StudyId AND PersonId=@PersonId;
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
      INSERT INTO dbo.ClinForm (EventId,FormId,PersonId,EventNum,CreatedSessId) VALUES (@EventId,@FormId,@PersonId,@EventNum,@SessId);
      SET @ClinFormId=SCOPE_IDENTITY();
    END
    ELSE IF NOT @DeletedBy IS NULL
      UPDATE dbo.ClinForm SET DeletedAt=NULL,DeletedBy=NULL WHERE ClinFormId=@ClinFormId;
  END
  SELECT @EventId AS EventId, @ClinFormId AS ClinFormId, @EventNum AS EventNum;
END;

--EXECUTE dbo.DbFinalizeUpgrade 6316;
--GO

--COMMIT TRANSACTION UpgradeTo6316;
--GO



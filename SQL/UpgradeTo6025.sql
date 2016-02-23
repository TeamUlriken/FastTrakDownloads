BEGIN TRANSACTION UpgradeTo6025
PRINT 'Starting upgrade to 6025'

DELETE FROM DbUpgradeLog WHERE DbVer > 6024;

EXEC DbCheckVersion 6024;
EXECUTE DbStartUpgrade 6025;
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
    WHERE 
     msf.StudyId=@StudyId AND dbo.MetaFormIsUsable( msf.FormId ) = 1
  END
END
GO

/* Remove some rights for public */
REVOKE EXECUTE ON dbo.AddLabData TO [public]

/* Selects are avaiable for public */
REVOKE SELECT ON dbo.DbProcList TO [superuser]
REVOKE SELECT ON dbo.DSSRule TO [superuser]
REVOKE SELECT ON dbo.KBMetaMember TO [superuser]
REVOKE SELECT ON dbo.KBDrugToProblem TO [superuser]
REVOKE SELECT ON dbo.PIA TO [superuser]
REVOKE SELECT ON dbo.KBAtcIndex TO [superuser]
REVOKE SELECT ON dbo.DbUpgradeLog TO [superuser]
REVOKE SELECT ON dbo.DSSStudyRule TO [superuser]
REVOKE SELECT ON dbo.TextItems TO [superuser]
REVOKE SELECT ON dbo.KBInteraction TO [superuser]

/* Remove some unneded permissions */
REVOKE UPDATE ON dbo.Person TO [public]
REVOKE INSERT ON dbo.StudyStatus TO [public]
REVOKE UPDATE ON Dash.CaseListHistory TO [public]
REVOKE UPDATE ON dbo.MetaFormItem TO [public]
REVOKE UPDATE ON dbo.MetaItem TO [public]
REVOKE UPDATE ON dbo.MetaForm TO [public]
REVOKE UPDATE ON dbo.MetaAlertLevel TO [public]
REVOKE UPDATE ON dbo.MetaTreatType TO [public]

/* Remove permissions on upgrade log */
REVOKE INSERT ON dbo.DbUpgradeLog TO [public]
REVOKE INSERT ON dbo.DbUpgradeLog TO [superuser]
REVOKE UPDATE ON dbo.DbUpgradeLog TO [public]
REVOKE UPDATE ON dbo.DbUpgradeLog TO [superuser]
GO

/* No delete permissions for anybody */
REVOKE DELETE ON dbo.DbUpgradeLog TO [public]
REVOKE DELETE ON Dash.CaseListHistory TO [public]
GO

ALTER PROCEDURE dbo.AddLabName( @LabName VARCHAR(40) ) AS
BEGIN
  DECLARE @LabCodeId INT;
  SELECT @LabCodeId = LabCodeId
  FROM dbo.LabCode
  WHERE LabName = @LabName;
  IF @LabCodeId IS NULL
  BEGIN
    INSERT INTO dbo.LabCode(LabName) VALUES (@LabName);
    SET @LabCodeId = SCOPE_IDENTITY();
  END
  SELECT LabCodeId, LabName, VarName, LoincCode, SynonymId, CreatedAt, CreatedBy
  FROM dbo.LabCode
  WHERE LabCodeId = @LabCodeId;
END
GO

ALTER PROCEDURE dbo.AddLabGroup( @LabGroupName VARCHAR(40) ) AS
BEGIN
  DECLARE @MaxSort INT;
  DECLARE @LabGroupId INT;
  SELECT @LabGroupId = LabGroupId
  FROM dbo.LabGroup
  WHERE LabGroupName = @LabGroupName;
  IF NOT @LabGroupId IS NULL
    SELECT LabGroupId, LabGroupName, SortOrder, CreatedAt, CreatedBy FROM dbo.LabGroup
    WHERE LabGroupName = @LabGroupName
  ELSE
  BEGIN
    SELECT @MaxSort = ISNULL(MAX(SortOrder), 0) FROM dbo.LabGroup;
    INSERT INTO dbo.LabGroup(LabGroupName, SortOrder) VALUES (@LabGroupName, @MaxSort + 1);
    SELECT SCOPE_IDENTITY() AS LabGroupId, @LabGroupName AS LabGroupName, @MaxSort + 1 AS SortOrder, GETDATE() AS CreatedAt, USER_ID() AS CreatedBy;
  END
END
GO

ALTER PROCEDURE dbo.GetLabGroupMapping AS
BEGIN
  SELECT lg.SortOrder, lg.LabGroupId, lg.LabGroupName, lc.LabCodeId, lc.LabName, lc.VarName
  FROM dbo.LabGroup lg
  LEFT OUTER JOIN dbo.LabCodeGroup lcg ON lcg.LabGroupId = lg.LabGroupId
  LEFT OUTER JOIN dbo.LabCode lc ON lc.LabCodeId = lcg.LabCodeId
  ORDER BY lg.SortOrder, lc.LabName
END
GO

ALTER PROCEDURE dbo.GetLabGroups AS
BEGIN
  SELECT LabGroupId, LabGroupName, SortOrder, CreatedAt, CreatedBy
  FROM dbo.LabGroup
  ORDER BY SortOrder, LabGroupId
END
GO

ALTER PROCEDURE dbo.DeleteLabGroup( @LabGroupId INT ) AS
BEGIN
  DELETE FROM dbo.LabGroup
  WHERE LabGroupId = @LabGroupId;
END
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
    -- Unsign form 
    UPDATE dbo.ClinForm SET SignedAt=NULL,SignedBy=NULL,FormStatus='I' WHERE ClinFormId=@ClinFormId;
    SELECT @EventId = EventId,@FormId = FormId FROM dbo.ClinForm WHERE ClinFormId=@ClinFormId;
    -- Unsign standard variables
    UPDATE dbo.ClinDatapoint SET LockedAt=NULL,LockedBy=NULL,Locked=0
      WHERE EventId=@EventId AND ItemId IN (SELECT ItemId from dbo.MetaFormItem WHERE FormId=@FormId);
    -- Unsign threaded variables
    UPDATE dbo.ClinThreadData SET LockedAt=NULL,LockedBy=NULL,Locked=0
      WHERE EventId=@EventId AND ItemId IN (SELECT ItemId from dbo.MetaFormItem WHERE FormId=@FormId);
    RETURN;
  END
  ELSE
  BEGIN  
    RAISERROR( @MessageText, 16,1 )
    RETURN -2;
  END;
END
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
    INSERT INTO UserLog (StudyId,CompName,CompUser,CompTime,AppVer)
      VALUES(@StudyId,@CompName,@CompUser,@CompTime,@AppVer );
    SELECT SCOPE_IDENTITY() AS SessId;
  END
  ELSE
  BEGIN
    RAISERROR( 'The username "%s" seems to be invalid.\nCopy this error message and contact the supplier of the application.', 16, 1, @ExpectedUserName );
    RETURN -2;
  END
END;
GO


EXECUTE dbo.DbFinalizeUpgrade 6025;
GO

COMMIT TRANSACTION UpgradeTo6025;
GO


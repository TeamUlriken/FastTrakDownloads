BEGIN TRANSACTION UpgradeTo6027
PRINT 'Starting upgrade to 6027'

DELETE FROM DbUpgradeLog WHERE DbVer > 6026;

EXEC DbCheckVersion 6026;
EXECUTE DbStartUpgrade 6027;
GO

IF dbo.DbIndexExists( 'StudCaseLog', 'IDX_StudCaseLog_StudCaseId' ) IS NULL
  CREATE INDEX IDX_StudCaseLog_StudCaseId ON dbo.StudCaseLog( StudCaseId )
GO
 
IF NOT OBJECT_ID('StudyCaseAtCenterNow' ) IS NULL 
  DROP FUNCTION dbo.StudyCaseAtCenterNow
GO 

CREATE FUNCTION dbo.StudyCaseAtCenterNow( @StudyId INT, @PersonId INT, @CenterId INT ) RETURNS INT
AS
BEGIN
  DECLARE @RetVal INT;
  SELECT @RetVal = COUNT(*) FROM StudCase sc 
  JOIN StudyGroup sg ON sg.StudyId=sc.StudyId AND sg.GroupId=sc.GroupId
  WHERE sc.StudyId=@StudyId AND sc.PersonId=@PersonId AND sg.CenterId=@CenterId;
  RETURN @RetVal;
END
GO

IF NOT OBJECT_ID('StudyCaseAtCenterBefore' ) IS NULL 
  DROP FUNCTION dbo.StudyCaseAtCenterBefore
GO 

CREATE FUNCTION dbo.StudyCaseAtCenterBefore( @StudyId INT, @PersonId INT, @CenterId INT ) RETURNS INT
AS
BEGIN
  DECLARE @RetVal INT;
  SELECT @RetVal = COUNT(*) FROM StudCase sc  
  JOIN StudCaseLog sl ON sl.StudCaseId=sc.StudCaseId
  JOIN StudyGroup sg ON sg.StudyId=sc.StudyId AND sg.GroupId=sl.OldGroupId
  WHERE sc.StudyId=@StudyId AND sc.PersonId=@PersonId AND sg.CenterId=@CenterId;
  RETURN @RetVal;
END
GO

IF NOT OBJECT_ID('StudyCaseAtCenterEver' ) IS NULL 
  DROP FUNCTION dbo.StudyCaseAtCenterEver
GO 

CREATE FUNCTION dbo.StudyCaseAtCenterEver( @StudyId INT, @PersonId INT, @CenterId INT ) RETURNS INT
AS
BEGIN
  DECLARE @RetVal INT;
  SELECT @RetVal = COUNT(*) FROM StudCase sc  
  JOIN StudCaseLog sl ON sl.StudCaseId=sc.StudCaseId
  JOIN StudyGroup sg ON sg.StudyId=sc.StudyId AND sg.GroupId=sl.NewGroupId
  WHERE sc.StudyId=@StudyId AND sc.PersonId=@PersonId AND sg.CenterId=@CenterId;
  RETURN @RetVal;
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6027;
GO

COMMIT TRANSACTION UpgradeTo6027;
GO

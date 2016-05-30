SET XACT_ABORT OFF;

BEGIN TRANSACTION UpgradeTo6312
GO

PRINT 'Overall purpose: Bugfix in GetUserDetails, would not return data for all users.'

--  ALTER procedure GetUserDetails to return information about other users too.

EXECUTE dbo.DbStartUpgrade 6311, 6312;
GO

PRINT '--  ALTER procedure GetUserDetails to return information about other users too.'
GO

ALTER PROCEDURE [dbo].[GetUserDetails]( @UserNameOrId NVARCHAR(128), @StudyId INT = NULL ) AS
BEGIN
  -- Get UserId if UserNameOrId is a username.
  DECLARE @UserId INT;
  IF ISNUMERIC(@UserNameOrId)=1 
    SET @UserId=CONVERT(INT,@UserNameOrId)
  ELSE 
    SET @UserId = USER_ID(@UserNameOrId);
  SELECT u.UserId, su.hasdbaccess, u.UserName, p.*, mp.*, c.*, @StudyId AS StudyId, sg.GroupId, sg.GroupName
    FROM dbo.UserList u
      LEFT JOIN sys.sysusers su ON su.uid=u.UserId
      LEFT JOIN dbo.Person p ON p.PersonId=u.PersonId
      LEFT JOIN dbo.MetaProfession mp ON mp.ProfId=u.ProfId
      LEFT JOIN dbo.StudyCenter c ON c.CenterId=u.CenterId
      LEFT JOIN dbo.StudyUser stu ON stu.StudyId=@StudyId AND stu.UserId=su.uid
      LEFT JOIN dbo.StudyGroup sg ON sg.GroupId=stu.GroupId AND sg.StudyId=stu.StudyId
    WHERE u.UserId = @UserId;
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6312;
GO

COMMIT TRANSACTION UpgradeTo6312;
GO

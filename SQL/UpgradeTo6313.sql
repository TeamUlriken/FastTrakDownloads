SET XACT_ABORT OFF;

BEGIN TRANSACTION UpgradeTo6313
GO

PRINT 'Overall purpose: Add profession privileges and disabling of groups'

-- CREATE procedure dbo.GetMetaFormProfessionPrivileges to return privileges for forms based on profession.

EXECUTE dbo.DbStartUpgrade 6312,6313;
GO

PRINT '--  CREATE procedure dbo.GetMetaFormProfessionPrivileges to return privileges for forms based on profession.'
GO

IF NOT OBJECT_ID('GetMetaFormProfessionPrivileges') IS NULL
  DROP PROCEDURE dbo.GetMetaFormProfessionPrivileges
GO

CREATE PROCEDURE dbo.GetMetaFormProfessionPrivileges AS
BEGIN
  SELECT mp.ProfId, mfpp.FormId, mf.FormTitle, mfpp.ProfType, mp.ProfName, mfpp.CanCreate, mfpp.CanEdit, mfpp.CanSign	
  FROM dbo.MetaFormProfessionPrivilege mfpp
  JOIN dbo.MetaForm mf ON mf.FormId = mfpp.FormId
  JOIN dbo.MetaProfession mp ON mfpp.ProfType = mp.ProfType;
END;
GO

GRANT EXECUTE ON dbo.GetMetaFormProfessionPrivileges TO [public] AS [dbo]
GO

PRINT '--  CREATE procedure dbo.DisableStudyGroup to allow old groups/departments to be disabled safely'
GO

IF NOT OBJECT_ID('dbo.DisableStudyGroup') IS NULL 
  DROP PROCEDURE DisableStudyGroup
GO

CREATE PROCEDURE dbo.DisableStudyGroup( @StudyId INT, @GroupId INT ) AS
BEGIN
  DECLARE @GroupMemberCount INTEGER;
  SELECT @GroupMemberCount = COUNT(sc.PersonId) FROM dbo.StudCase sc 
  JOIN dbo.StudyGroup sg ON sg.StudyId=sc.StudyId AND sg.GroupId=sc.GroupId
  JOIN dbo.Person p ON p.PersonId = sc.PersonId AND p.TestCase = 0
  WHERE sc.StudyId = @StudyId AND sc.GroupId=@GroupId;
  IF @GroupMemberCount > 0
    RAISERROR(  'Deaktivering ikke mulig, fordi det er %d personer i denne gruppen.', 16, 1, @GroupMemberCount )
  ELSE
    UPDATE dbo.StudyGroup SET GroupActive = 0 WHERE StudyId=@StudyId AND GroupId = @GroupId;
END
GO

GRANT EXECUTE ON dbo.DisableStudyGroup TO [superuser] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6313;
GO

COMMIT TRANSACTION UpgradeTo6313;
GO
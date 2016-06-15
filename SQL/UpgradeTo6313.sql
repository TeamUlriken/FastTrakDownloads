SET XACT_ABORT OFF;

BEGIN TRANSACTION UpgradeTo6313
GO

PRINT 'Overall purpose: Support profession privileges to for edit, sign and create forms.'

-- CREATE procedure dbo.GetMetaFormProfessionPrivileges to return privileges for forms based on profession.

EXECUTE dbo.DbStartUpgrade 6312,6313;
GO

PRINT '--  CREATE procedure dbo.GetMetaFormProfessionPrivileges to return privileges for forms based on profession.'
GO

IF NOT OBJECT_ID('GetMetaFormProfessionPrivileges') IS NULL
  DROP PROCEDURE GetMetaFormProfessionPrivileges
GO

CREATE PROCEDURE dbo.GetMetaFormProfessionPrivileges AS
BEGIN
  SELECT mp.ProfId, mfpp.FormId, mf.FormTitle, mfpp.ProfType, mp.ProfName, mfpp.CanCreate, mfpp.CanEdit, mfpp.CanSign	
  FROM dbo.MetaFormProfessionPrivilege mfpp
  JOIN dbo.MetaForm mf ON mf.FormId = mfpp.FormId
  JOIN dbo.MetaProfession mp ON mfpp.ProfType = mp.ProfType;
END;
GO

GRANT EXECUTE ON dbo.GetMetaFormProfessionPrivleges TO [public] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6313;
GO

COMMIT TRANSACTION UpgradeTo6313;
GO
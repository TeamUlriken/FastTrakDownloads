BEGIN TRANSACTION UpgradeTo6040
PRINT 'Starting upgrade to 6040'

DELETE FROM DbUpgradeLog WHERE DbVer > 6039;

EXEC DbCheckVersion 6039;
EXECUTE DbStartUpgrade 6040;
GO

IF object_id('dbo.RoleMember') IS NULL
BEGIN

CREATE TABLE dbo.RoleMember ( 
  RowId INT IDENTITY(1,1) NOT NULL,            
  guid UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
  RoleName NVARCHAR(128) NOT NULL, RoleId INT NOT NULL,
  MemberName NVARCHAR(128) NOT NULL, MemberId INT NOT NULL,
  RevokedBy INT NULL, 
  RevokedAt DateTime NULL,
  GrantedBy INT NOT NULL DEFAULT DATABASE_PRINCIPAL_ID(), 
  GrantedAt DateTime NOT NULL DEFAULT getdate() )

ALTER TABLE dbo.RoleMember 
  ADD CONSTRAINT FK_RoleMember_MemberId 
  FOREIGN KEY (MemberId) REFERENCES dbo.UserList( UserId )

ALTER TABLE dbo.RoleMember 
  ADD CONSTRAINT FK_RoleMember_RevokedBy 
  FOREIGN KEY (RevokedBy) REFERENCES dbo.UserList( UserId )

ALTER TABLE dbo.RoleMember 
  ADD CONSTRAINT FK_RoleMember_GrantedBy 
  FOREIGN KEY (GrantedBy) REFERENCES dbo.UserList( UserId )
  
END

IF NOT OBJECT_ID('AddRoleMember') IS NULL
  DROP PROCEDURE dbo.AddRoleMember
GO

CREATE PROCEDURE dbo.AddRoleMember( @RoleName NVARCHAR(128), @MemberName NVARCHAR(128) )
AS
BEGIN
  EXEC sp_addrolemember @RoleName,@MemberName;
  IF IS_ROLEMEMBER( @RoleName, @MemberName ) = 1
    INSERT INTO dbo.RoleMember
     ( RoleName, RoleId, MemberName, MemberId ) 
     VALUES( @RoleName,DATABASE_PRINCIPAL_ID(@RoleName), @MemberName, DATABASE_PRINCIPAL_ID(@MemberName) )
  ELSE  
    RAISERROR( 'The membership has not been added.', 16,1 )   
END
GO

IF NOT OBJECT_ID('DropRoleMember') IS NULL
  DROP PROCEDURE dbo.DropRoleMember
GO

CREATE PROCEDURE dbo.DropRoleMember( @RoleName NVARCHAR(128), @MemberName NVARCHAR(128) )
AS
BEGIN
  EXEC sp_droprolemember @RoleName,@MemberName;
  IF IS_ROLEMEMBER( @RoleName, @MemberName ) = 0
  BEGIN
    UPDATE dbo.RoleMember SET RevokedAt = GetDate(), RevokedBy=DATABASE_PRINCIPAL_ID() 
      WHERE RoleName = @RoleName AND MemberName=@MemberName AND MemberId=DATABASE_PRINCIPAL_ID(@MemberName)
      AND RevokedAt IS NULL;
    INSERT INTO dbo.RoleMember
     ( RoleName, RoleId, MemberName, MemberId, RevokedAt, RevokedBy ) 
     VALUES( @RoleName,  DATABASE_PRINCIPAL_ID(@RoleName), @MemberName, DATABASE_PRINCIPAL_ID(@MemberName),
       GetDate(), DATABASE_PRINCIPAL_ID() )
  END
  ELSE
    RAISERROR ( 'The membership has not been dropped.', 16,1 )   
END
GO

GRANT EXECUTE ON dbo.AddRoleMember TO [superuser] AS [dbo]
GO

GRANT EXECUTE ON dbo.DropRoleMember TO [superuser] AS [dbo]
GO

IF dbo.DbColumnExists( 'UserRoleInfo','SortOrder') = 0
 ALTER TABLE UserRoleInfo ADD SortOrder INT
GO

UPDATE dbo.UserRoleInfo SET SortOrder = 1 WHERE RoleName='db_owner'
UPDATE dbo.UserRoleInfo SET SortOrder = 2 WHERE RoleName='superuser'
UPDATE dbo.UserRoleInfo SET SortOrder = 3 WHERE RoleName='db_ddladmin'
UPDATE dbo.UserRoleInfo SET SortOrder = 4 WHERE RoleName='db_accessadmin'
UPDATE dbo.UserRoleInfo SET SortOrder = 5 WHERE RoleName='PrintPrescription'
UPDATE dbo.UserRoleInfo SET SortOrder = 6 WHERE RoleName='DrugPrescriber'
UPDATE dbo.UserRoleInfo SET SortOrder = 7 WHERE RoleName='EnterLabData'
UPDATE dbo.UserRoleInfo SET SortOrder = 8 WHERE RoleName='DataImport'
UPDATE dbo.UserRoleInfo SET SortOrder = 9 WHERE RoleName='DataImport'
UPDATE dbo.UserRoleInfo SET SortOrder = 10 WHERE RoleName='Journalansvarlig'
UPDATE dbo.UserRoleInfo SET SortOrder = 11 WHERE RoleName='ChangeProfession'
GO

ALTER VIEW dbo.RoleMembership AS
SELECT 
  ul.CenterId, ul.UserId, ul.UserName, p.FullName,sp.Name as RoleName, ur.RoleCaption, ur.RoleInfo,c.CenterName,
  ur.SortOrder,p.HPRNo 
FROM 
  dbo.UserRoleInfo ur JOIN  
  sys.database_principals sp on sp.Name=ur.RoleName
  JOIN sys.sysmembers sm ON sm.groupuid=sp.principal_id
  JOIN dbo.UserList ul ON ul.UserId=sm.memberuid
  LEFT OUTER JOIN dbo.StudyCenter c on c.CenterId=ul.CenterId
  LEFT OUTER JOIN dbo.Person p ON p.PersonId=ul.PersonId
GO

ALTER PROCEDURE dbo.UpdateFormSignClinId( @ClinFormId INT ) AS
BEGIN
  DECLARE @MsgText VARCHAR(512);
  DECLARE @EventId INT;
  DECLARE @FormId INT;
  UPDATE dbo.ClinForm SET SignedAt=getdate(),SignedBy=user_id(),FormStatus='L'
    WHERE ClinFormId=@ClinFormId AND (SignedBy IS NULL );
  IF @@ROWCOUNT=0 
  BEGIN
    SET @MsgText = dbo.GetTextItem( 'UpdateFormSignClinId','Failed' );
    RAISERROR (@MsgText,16,1 )
  END
  ELSE
  BEGIN                                           
    SELECT @EventId = EventId, @FormId=FormId FROM dbo.ClinForm WHERE ClinFormId=@ClinFormId; 
    UPDATE dbo.ClinDatapoint SET LockedAt=getdate(),LockedBy=user_id(),Locked=1 
      WHERE Locked=0 AND TouchId IN ( SELECT TouchId FROM dbo.ClinTouch WHERE EventId=@EventId AND FormId=@FormId)
  END
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6040;
GO

COMMIT TRANSACTION UpgradeTo6040;
GO




BEGIN TRANSACTION UpgradeTo6048
PRINT 'Starting upgrade to 6048'

DELETE FROM DbUpgradeLog WHERE DbVer > 6047;

EXEC DbCheckVersion 6047;
EXECUTE DbStartUpgrade 6048;
GO

IF USER_ID( 'Gruppeleder' ) IS NULL
  CREATE ROLE Gruppeleder
GO

IF USER_ID( 'Leder' ) IS NULL
  CREATE ROLE Leder
GO

IF USER_ID( 'Avdelingsleder' ) IS NULL
  CREATE ROLE Avdelingsleder
GO

EXEC sp_addrolemember 'Journalansvarlig', 'Leder'
EXEC sp_addrolemember 'Journalansvarlig', 'Avdelingsleder'
EXEC sp_addrolemember 'Journalansvarlig', 'Gruppeleder'
GO

ALTER PROCEDURE dbo.CanUnsignForm( @ClinFormId INT, @CanUnsign INT OUTPUT, @MessageText VARCHAR(MAX) OUTPUT ) 
AS
BEGIN
  SET @CanUnsign = 0;
  IF ( IS_MEMBER('Superuser') + IS_MEMBER('Journalansvarlig') ) > 0
  BEGIN
    SET @MessageText = 'Superbruker og Journalansvarlig kan gjenåpne andres skjema.';
    SET @CanUnsign = 2;
    RETURN;
  END
  ELSE
  BEGIN                            
    DECLARE @SignedBy INT;
    SELECT @SignedBy = SignedBy FROM dbo.ClinForm WHERE ClinFormId=@ClinFormId;
    IF ( @SignedBy IS NULL )
    BEGIN
      SET @MessageText = 'Skjemaet er usignert!';
      RETURN;
    END  
    ELSE IF ( @SignedBy=USER_ID() )
    BEGIN 
      SET @MessageText = 'Brukere kan gjenåpne sine egne skjema.';
      SET @CanUnsign = 1;
    END
    ELSE  
    BEGIN
      SET @MessageText = 'Skjemaet er signert av en annen bruker: ';
      SET @MessageText = @MessageText + ISNULL(USER_NAME(@SignedBy),'(ukjent)') + '.\n';
      SET @MessageText = @MessageText + 'Denne brukeren, Superbruker eller Journalansvarlig kan gjenåpne skjemaet!';             
      SET @CanUnsign = -1;
    END;
  END;
END
GO

GRANT INSERT,UPDATE,SELECT ON dbo.UserRoleInfo TO [superuser] AS [dbo]
GO

IF NOT EXISTS( SELECT 1 FROM dbo.UserRoleInfo WHERE RoleName='Leder')
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive ) VALUES( 'Leder', 'Leder', 'Leder for en institusjon', 1 )
GO

IF NOT EXISTS( SELECT 1 FROM dbo.UserRoleInfo WHERE RoleName='Avdelingsleder')
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive ) VALUES( 'Avdelingsleder', 'Avdelingsleder', 'Leder for en avdeling', 1 )
GO

IF NOT EXISTS( SELECT 1 FROM dbo.UserRoleInfo WHERE RoleName='Gruppeleder')
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive ) VALUES( 'Gruppeleder', 'Gruppeleder', 'Leder for en gruppe', 1 )
GO

COMMIT TRANSACTION UpgradeTo6048;
GO

EXECUTE dbo.DbFinalizeUpgrade 6048;
GO

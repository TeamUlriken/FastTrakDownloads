SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6001;
PRINT 'Starting upgrade to 6001'

DELETE FROM DbUpgradeLog WHERE DbVer > 600;

EXEC DbCheckVersion 600;       
EXECUTE DbStartUpgrade 6001;
GO

IF dbo.DbColumnExists( 'Person','DeathDate' ) = 1
  ALTER TABLE dbo.Person DROP COLUMN DeathDate
GO

IF dbo.DbColumnExists( 'Person','DeceasedDate' ) = 0
  ALTER TABLE dbo.Person ADD DeceasedDate DateTime
GO

IF dbo.DbColumnExists( 'Person','DeceasedInd' ) = 0
  ALTER TABLE dbo.Person ADD DeceasedInd BIT
GO

IF NOT OBJECT_ID('dbo.LivingStatusCheck') IS NULL
  DROP TABLE dbo.LivingStatusCheck
GO

CREATE TABLE [dbo].[LivingStatusCheck] ( 
  NationalId VARCHAR(16) NOT NULL, 
  LastChecked DateTime NOT NULL,            
  CONSTRAINT PK_LivingStatusCheck PRIMARY KEY CLUSTERED ( NationalId ) )
GO

IF NOT OBJECT_ID( 'dbo.GetLivingStatusCandidates') IS NULL 
  DROP PROCEDURE GetLivingStatusCandidates
GO

CREATE PROCEDURE [dbo].[GetLivingStatusCandidates] ( @DayInterval INT = 7 )
AS
BEGIN
  SELECT DISTINCT NationalId FROM dbo.Person WHERE NOT ( NULLIF(NationalId,'') IS NULL ) AND ISNULL(DeceasedInd,0) = 0
  EXCEPT 
  SELECT NationalId FROM LivingStatusCheck WHERE LastChecked > DATEADD( DAY, -@DayInterval, GETDATE() )
END
GO

GRANT EXECUTE ON [dbo].[GetLivingStatusCandidates] TO [public] AS [dbo]
GO

IF NOT OBJECT_ID( 'dbo.UpdateLivingStatus') IS NULL 
  DROP PROCEDURE dbo.UpdateLivingStatus
GO

CREATE PROCEDURE [dbo].[UpdateLivingStatus]( @NationalId VARCHAR(16), @DeceasedDate DateTime, @DeceasedInd BIT )
AS
BEGIN
  UPDATE dbo.Person SET DeceasedInd = @DeceasedInd, DeceasedDate = @DeceasedDate WHERE NationalId = @NationalId;
  UPDATE dbo.LivingStatusCheck SET LastChecked = GETDATE() WHERE NationalId=@NationalId;
  -- If nothing affected, insert row for check
  IF @@ROWCOUNT = 0
    INSERT INTO LivingStatusCheck( NationalId, LastChecked ) VALUES( @NationalId, GETDATE() )
END
GO

GRANT EXECUTE ON [dbo].[UpdateLivingStatus] TO [public] AS [dbo]
GO

EXECUTE DbFinalizeUpgrade 6001;
GO

COMMIT TRANSACTION UpgradeTo6001;
GO



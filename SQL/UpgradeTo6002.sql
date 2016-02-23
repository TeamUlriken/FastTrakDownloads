SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6002;
PRINT 'Starting upgrade to 6002'

DELETE FROM DbUpgradeLog WHERE DbVer > 6001;

EXEC DbCheckVersion 6001;
EXECUTE DbStartUpgrade 6002;
GO

IF dbo.DbColumnExists( 'Person','StreetAddress' ) = 0
  ALTER TABLE dbo.Person ADD StreetAddress VARCHAR(64) NULL
GO

IF dbo.DbColumnExists( 'Person','PostalCode' ) = 0
  ALTER TABLE dbo.Person ADD PostalCode VARCHAR(12) NULL
GO

IF dbo.DbColumnExists( 'Person','City' ) = 0
  ALTER TABLE dbo.Person ADD City VARCHAR(32) NULL
GO

IF dbo.DbColumnExists( 'Person','KommuneNr' ) = 0
  ALTER TABLE dbo.Person ADD KommuneNr VARCHAR(8) NULL
GO

IF dbo.DbColumnExists( 'Person','KommuneNavn' ) = 0
  ALTER TABLE dbo.Person ADD KommuneNavn VARCHAR(32) NULL
GO

IF dbo.DbColumnExists( 'Person','FylkeNr' ) = 0
  ALTER TABLE dbo.Person ADD FylkeNr VARCHAR(8) NULL
GO

IF dbo.DbColumnExists( 'Person','FylkeNavn' ) = 0
  ALTER TABLE dbo.Person ADD FylkeNavn VARCHAR(32) NULL
GO


EXECUTE DbFinalizeUpgrade 6002;
GO

COMMIT TRANSACTION UpgradeTo6002;
GO



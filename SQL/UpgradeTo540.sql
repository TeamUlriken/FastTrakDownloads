SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo540;
PRINT 'Starting upgrade to 540'

DELETE FROM DbUpgradeLog WHERE DbVer > 530;

EXEC DbCheckVersion 530;       
EXECUTE DbStartUpgrade 540;
GO

-- Add LastUpdate to FEST

IF dbo.DbColumnExists( 'FEST.Refusjonskode', 'LastUpdate' ) = 0
  ALTER TABLE FEST.Refusjonskode ADD LastUpdate DateTime
GO

UPDATE FEST.Refusjonskode SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

IF dbo.DbColumnExists( 'FEST.Vilkar', 'LastUpdate' ) = 0
  ALTER TABLE FEST.Vilkar ADD LastUpdate DateTime
GO

UPDATE FEST.Vilkar SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

IF dbo.DbColumnExists( 'FEST.Refusjonsgruppe', 'LastUpdate' ) = 0
  ALTER TABLE FEST.Refusjonsgruppe ADD LastUpdate DateTime
GO

UPDATE FEST.Refusjonsgruppe SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

-- Add LastUpdate to Comm

IF dbo.DbColumnExists( 'Comm.Organization', 'LastUpdate' ) = 0
  ALTER TABLE Comm.Organization ADD LastUpdate DateTime
GO

UPDATE Comm.Organization SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

IF dbo.DbColumnExists( 'Comm.Partner', 'LastUpdate' ) = 0
  ALTER TABLE Comm.Partner ADD LastUpdate DateTime
GO

UPDATE Comm.Partner SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

-- Add LastUpdate to rules

IF dbo.DbColumnExists( 'DbProcList', 'LastUpdate' ) = 0
  ALTER TABLE dbo.DbProcList ADD LastUpdate DateTime
GO

UPDATE dbo.DbProcList SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

IF dbo.DbColumnExists( 'DSSStudyRule', 'LastUpdate' ) = 0
  ALTER TABLE dbo.DSSStudyRule ADD LastUpdate DateTime
GO

UPDATE dbo.DSSStudyRule SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

IF dbo.DbColumnExists( 'DSSRule', 'LastUpdate' ) = 0
  ALTER TABLE dbo.DSSRule ADD LastUpdate DateTime
GO

UPDATE dbo.DSSRule SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

IF dbo.DbColumnExists( 'MetaNomList', 'LastUpdate' ) = 0
  ALTER TABLE dbo.MetaNomList ADD LastUpdate DateTime
GO

UPDATE dbo.MetaNomList SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

IF dbo.DbColumnExists( 'MetaNomItem', 'LastUpdate' ) = 0
  ALTER TABLE dbo.MetaNomItem ADD LastUpdate DateTime
GO

UPDATE dbo.MetaNomItem SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

IF dbo.DbColumnExists( 'MetaNomListItem', 'LastUpdate' ) = 0
  ALTER TABLE dbo.MetaNomListItem ADD LastUpdate DateTime
GO

UPDATE dbo.MetaNomListItem SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

EXEC DbLogChange 540,'Tweak','Added LastUpdate to MetaNomList, MetaNomItem, MetaNomListItem to prepare for direct download'
GO


IF dbo.DbColumnExists( 'MetaForm', 'LastUpdate' ) = 0
  ALTER TABLE MetaForm ADD LastUpdate DateTime
GO

UPDATE MetaForm SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

IF dbo.DbColumnExists( 'MetaStudyForm', 'LastUpdate' ) = 0
  ALTER TABLE MetaStudyForm ADD LastUpdate DateTime
GO

UPDATE MetaStudyForm SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'ExcludeCaption' ) = 0
  ALTER TABLE MetaFormItem ADD ExcludeCaption BIT
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'LastUpdate' ) = 0
  ALTER TABLE MetaFormItem ADD LastUpdate DateTime
GO

IF dbo.DbColumnExists( 'MetaItem', 'LastUpdate' ) = 0
  ALTER TABLE MetaItem ADD LastUpdate DateTime
GO

UPDATE MetaItem SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

IF dbo.DbColumnExists( 'MetaItemAnswer', 'ShortCode' ) = 0
  ALTER TABLE MetaItemAnswer ADD ShortCode VARCHAR(5)
GO

IF dbo.DbColumnExists( 'MetaItemAnswer', 'LastUpdate' ) = 0
  ALTER TABLE MetaItemAnswer ADD LastUpdate DateTime
GO

UPDATE MetaItemAnswer SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

EXEC DbLogChange 540,'Tweak','Added LastUpdate to MetaItem and MetaItemAnswer to prepare for direct download'
GO

-- Add some other missing fields

IF dbo.DbColumnExists( 'DSSRule', 'Title' ) = 0
  ALTER TABLE dbo.DSSRule ADD Title VARCHAR(64)
GO

IF dbo.DbColumnExists('DSSRule', 'Description') = 0
  ALTER TABLE dbo.DSSRule ADD Description VARCHAR(MAX)
GO

EXEC DbLogChange 540,'Tweak','Added title and description to DSSRule'
GO


EXECUTE DbFinalizeUpgrade 540;
GO

COMMIT TRANSACTION UpgradeTo540;
GO

BEGIN TRANSACTION UpgradeTo6023
PRINT 'Starting upgrade to 6023'

DELETE FROM DbUpgradeLog WHERE DbVer > 6022;

EXEC DbCheckVersion 6022;
EXECUTE DbStartUpgrade 6023;
GO

IF NOT OBJECT_ID('MetaItemType') IS NULL
  ALTER TABLE dbo.MetaItem DROP CONSTRAINT FK_MetaItem_ItemType
GO

IF NOT OBJECT_ID('MetaItemType') IS NULL
  DROP TABLE dbo.MetaItemType
GO

CREATE TABLE dbo.MetaItemType ( ItemType INT NOT NULL, Description VARCHAR(32) NOT NULL, LoincScale VARCHAR(4) NULL, Active BIT NOT NULL, HasData BIT NOT NULL )
GO

ALTER TABLE dbo.MetaItemType ADD CONSTRAINT PK_MetaItemType PRIMARY KEY (ItemType)
GO

INSERT INTO dbo.MetaItemType ( ItemType, Description, LoincScale, Active, HasData  ) VALUES ( 1,'Quantity','QN', 1, 1 ) 
INSERT INTO dbo.MetaItemType ( ItemType, Description, LoincScale, Active, HasData ) VALUES ( 2,'Enumeration','ORD', 1, 1 ) 
INSERT INTO dbo.MetaItemType ( ItemType, Description, LoincScale, Active, HasData ) VALUES ( 3, 'Named entity','NOM', 1, 1 ) 
INSERT INTO dbo.MetaItemType ( ItemType, Description, LoincScale, Active, HasData ) VALUES ( 4, 'Narrative, free text','NAR', 1, 1 ) 
INSERT INTO dbo.MetaItemType ( ItemType, Description, Active, HasData ) VALUES ( 5, 'Date', 1, 1 ) 
INSERT INTO dbo.MetaItemType ( ItemType, Description, Active, HasData ) VALUES ( 6, 'Header', 0, 0 ) 
INSERT INTO dbo.MetaItemType ( ItemType, Description, Active, HasData ) VALUES ( 7, 'Checklist', 0, 1 ) 
INSERT INTO dbo.MetaItemType ( ItemType, Description, Active, HasData ) VALUES ( 8, 'Message', 1, 0 ) 

ALTER TABLE MetaItem ADD CONSTRAINT FK_MetaItem_ItemType FOREIGN KEY (ItemType) REFERENCES dbo.MetaItemType ( ItemType )
GO

EXECUTE dbo.DbFinalizeUpgrade 6023;
GO

COMMIT TRANSACTION UpgradeTo6023;
GO


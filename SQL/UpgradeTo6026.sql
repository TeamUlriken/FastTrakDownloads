BEGIN TRANSACTION UpgradeTo6026
PRINT 'Starting upgrade to 6026'

DELETE FROM DbUpgradeLog WHERE DbVer > 6025;

EXEC DbCheckVersion 6025;
EXECUTE DbStartUpgrade 6026;
GO

IF NOT OBJECT_ID('FEST.FK_KodeVilkar_Vilkar') IS NULL
  ALTER TABLE [FEST].[KodeVilkar]
  DROP  CONSTRAINT [FK_KodeVilkar_Vilkar]
GO

IF NOT OBJECT_ID('FEST.FK_KodeVilkar_RefVilkar') IS NULL
  ALTER TABLE [FEST].[KodeVilkar]
  DROP  CONSTRAINT [FK_KodeVilkar_RefVilkar]
GO

IF NOT OBJECT_ID('FEST.FK_FEST_KodeVilkar_RefVilkar') IS NULL
  ALTER TABLE [FEST].[KodeVilkar]
  DROP  CONSTRAINT [FK_FEST_KodeVilkar_RefVilkar]
GO

ALTER TABLE [FEST].[KodeVilkar] WITH CHECK ADD CONSTRAINT [FK_KodeVilkar_Vilkar] FOREIGN KEY([RefVilkar])
REFERENCES [FEST].[Vilkar] ([Id])
ON DELETE CASCADE
GO

IF NOT OBJECT_ID('FEST.FK_GruppeVilkar_Vilkar') IS NULL
  ALTER TABLE [FEST].[GruppeVilkar]
  DROP CONSTRAINT [FK_GruppeVilkar_Vilkar]
GO

IF NOT OBJECT_ID('FEST.FK_GruppeVilkar_RefVilkar') IS NULL
  ALTER TABLE [FEST].[GruppeVilkar]
  DROP CONSTRAINT [FK_GruppeVilkar_RefVilkar]
GO

IF NOT OBJECT_ID('FEST.FK_FEST_GruppeVilkar_RefVilkar') IS NULL
  ALTER TABLE [FEST].[GruppeVilkar]
  DROP CONSTRAINT [FK_FEST_GruppeVilkar_RefVilkar]
GO

ALTER TABLE [FEST].[GruppeVilkar] WITH CHECK ADD CONSTRAINT [FK_GruppeVilkar_Vilkar] FOREIGN KEY([RefVilkar])
REFERENCES [FEST].[Vilkar] ([Id])
ON DELETE CASCADE
GO

IF NOT OBJECT_ID('FEST.FK_GruppeVilkar_Gruppe') IS NULL
  ALTER TABLE [FEST].[GruppeVilkar]
  DROP CONSTRAINT [FK_GruppeVilkar_Gruppe]
GO

IF NOT OBJECT_ID('FEST.FK_GruppeVilkar_RefRefusjonsgruppe') IS NULL
  ALTER TABLE [FEST].[GruppeVilkar]
  DROP CONSTRAINT [FK_GruppeVilkar_RefRefusjonsgruppe]
GO

IF NOT OBJECT_ID('FEST.FK_FEST_GruppeVilkar_RefRefusjonsgruppe') IS NULL
  ALTER TABLE [FEST].[GruppeVilkar]
  DROP CONSTRAINT [FK_FEST_GruppeVilkar_RefRefusjonsgruppe]
GO

ALTER TABLE [FEST].[GruppeVilkar] WITH CHECK ADD CONSTRAINT [FK_GruppeVilkar_Gruppe] FOREIGN KEY([RefRefusjonsgruppe])
REFERENCES [FEST].[Refusjonsgruppe] ([Id])
ON DELETE CASCADE
GO

EXECUTE dbo.DbFinalizeUpgrade 6026;
GO

COMMIT TRANSACTION UpgradeTo6026;
GO

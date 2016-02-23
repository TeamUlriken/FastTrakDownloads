SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6006
PRINT 'Starting upgrade to 6006'

DELETE FROM DbUpgradeLog WHERE DbVer > 6005;

EXEC DbCheckVersion 6005;
EXECUTE DbStartUpgrade 6006;
GO

IF NOT OBJECT_ID('FEST.FK_Refusjonskode_Refusjonsgruppe') IS NULL
  ALTER TABLE FEST.Refusjonskode DROP CONSTRAINT FK_Refusjonskode_Refusjonsgruppe
GO

IF NOT OBJECT_ID('FEST.FK_FEST_Refusjonskode_RefRefusjonsgruppe') IS NULL
  ALTER TABLE FEST.Refusjonskode DROP CONSTRAINT FK_FEST_Refusjonskode_RefRefusjonsgruppe
GO

ALTER TABLE FEST.Refusjonskode WITH CHECK ADD CONSTRAINT FK_Refusjonskode_Refusjonsgruppe FOREIGN KEY (RefRefusjonsgruppe)
  REFERENCES FEST.Refusjonsgruppe (Id)
  ON DELETE CASCADE 
  ON UPDATE NO ACTION
GO

IF NOT OBJECT_ID('FEST.FK_KodeVilkar_Refusjonskode') IS NULL
  ALTER TABLE FEST.KodeVilkar DROP CONSTRAINT FK_KodeVilkar_Refusjonskode
GO

IF NOT OBJECT_ID('FEST.FK_KodeVilkar_RefRefusjonskode') IS NULL
  ALTER TABLE FEST.KodeVilkar DROP CONSTRAINT FK_KodeVilkar_RefRefusjonskode
GO

IF NOT OBJECT_ID('FEST.FK_FEST_KodeVilkar_RefRefusjonskode') IS NULL
  ALTER TABLE FEST.KodeVilkar DROP CONSTRAINT FK_FEST_KodeVilkar_RefRefusjonskode
GO

ALTER TABLE FEST.KodeVilkar WITH CHECK ADD CONSTRAINT FK_KodeVilkar_Refusjonskode FOREIGN KEY (RefRefusjonskode)
  REFERENCES FEST.Refusjonskode (Id)
  ON DELETE CASCADE 
  ON UPDATE NO ACTION
GO

EXECUTE DbFinalizeUpgrade 6006;
GO

COMMIT TRANSACTION UpgradeTo6006;
GO

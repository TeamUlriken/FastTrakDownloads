BEGIN TRANSACTION UpgradeTo6035
PRINT 'Starting upgrade to 6035'

DELETE FROM DbUpgradeLog WHERE DbVer > 6034;

EXEC DbCheckVersion 6034;
EXECUTE DbStartUpgrade 6035;
GO

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_Refusjonskode_Refusjonsgruppe' )
 ALTER TABLE FEST.Refusjonskode DROP CONSTRAINT FK_Refusjonskode_Refusjonsgruppe
GO 

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_Refusjonskode_RefRefusjonsgruppe' )
 ALTER TABLE FEST.Refusjonskode DROP CONSTRAINT FK_Refusjonskode_RefRefusjonsgruppe
GO 

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_FEST_Refusjonskode_RefRefusjonsgruppe' )
 ALTER TABLE FEST.Refusjonskode DROP CONSTRAINT FK_FEST_Refusjonskode_RefRefusjonsgruppe
GO 
 

ALTER TABLE FEST.Refusjonskode WITH CHECK ADD CONSTRAINT FK_FEST_Refusjonskode_RefRefusjonsgruppe FOREIGN KEY (RefRefusjonsgruppe)
  REFERENCES FEST.Refusjonsgruppe (Id)
  ON DELETE CASCADE 
  ON UPDATE NO ACTION
GO

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_KodeVilkar_Vilkar' )
 ALTER TABLE FEST.KodeVilkar DROP CONSTRAINT FK_KodeVilkar_Vilkar
GO 

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_KodeVilkar_RefVilkar' )
 ALTER TABLE FEST.KodeVilkar DROP CONSTRAINT FK_KodeVilkar_RefVilkar
GO 

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_FEST_KodeVilkar_RefVilkar' )
 ALTER TABLE FEST.KodeVilkar DROP CONSTRAINT FK_FEST_KodeVilkar_RefVilkar
GO 

ALTER TABLE FEST.KodeVilkar WITH CHECK ADD CONSTRAINT FK_KodeVilkar_RefVilkar FOREIGN KEY (RefVilkar)
  REFERENCES FEST.Vilkar (Id)
  ON DELETE CASCADE 
  ON UPDATE NO ACTION
GO

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_KodeVilkar_Refusjonskode' )
 ALTER TABLE FEST.KodeVilkar DROP CONSTRAINT FK_KodeVilkar_Refusjonskode
GO 

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_KodeVilkar_RefRefusjonskode' )
 ALTER TABLE FEST.KodeVilkar DROP CONSTRAINT FK_KodeVilkar_RefRefusjonskode
GO 

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_FEST_KodeVilkar_RefRefusjonskode' )
 ALTER TABLE FEST.KodeVilkar DROP CONSTRAINT FK_FEST_KodeVilkar_RefRefusjonskode
GO 

ALTER TABLE FEST.KodeVilkar WITH CHECK ADD CONSTRAINT FK_KodeVilkar_RefRefusjonskode FOREIGN KEY (RefRefusjonskode)
  REFERENCES FEST.Refusjonskode (Id)
  ON DELETE CASCADE 
  ON UPDATE NO ACTION
GO

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_GruppeVilkar_Vilkar' )
 ALTER TABLE FEST.GruppeVilkar DROP CONSTRAINT FK_GruppeVilkar_Vilkar
GO 

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_GruppeVilkar_RefVilkar' )
 ALTER TABLE FEST.GruppeVilkar DROP CONSTRAINT FK_GruppeVilkar_RefVilkar
GO 

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_FEST_GruppeVilkar_RefVilkar' )
 ALTER TABLE FEST.GruppeVilkar DROP CONSTRAINT FK_FEST_GruppeVilkar_RefVilkar
GO 

ALTER TABLE FEST.GruppeVilkar WITH CHECK ADD CONSTRAINT FK_GruppeVilkar_RefVilkar FOREIGN KEY (RefVilkar)
  REFERENCES FEST.Vilkar (Id)
  ON DELETE CASCADE 
  ON UPDATE NO ACTION
GO

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_GruppeVilkar_Refusjonsgruppe' )
 ALTER TABLE FEST.GruppeVilkar DROP CONSTRAINT FK_GruppeVilkar_Refusjonsgruppe
GO 

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_GruppeVilkar_RefRefusjonsgruppe' )
 ALTER TABLE FEST.GruppeVilkar DROP CONSTRAINT FK_GruppeVilkar_RefRefusjonsgruppe
GO 

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_FEST_GruppeVilkar_RefRefusjonsgruppe' )
 ALTER TABLE FEST.GruppeVilkar DROP CONSTRAINT FK_FEST_GruppeVilkar_RefRefusjonsgruppe
GO 

IF EXISTS( SELECT * FROM sysobjects WHERE name = 'FK_GruppeVilkar_Gruppe' )
 ALTER TABLE FEST.GruppeVilkar DROP CONSTRAINT FK_GruppeVilkar_Gruppe
GO 

ALTER TABLE FEST.GruppeVilkar WITH CHECK ADD CONSTRAINT FK_GruppeVilkar_RefRefusjonsgruppe FOREIGN KEY (RefRefusjonsgruppe)
  REFERENCES FEST.Refusjonsgruppe (Id)
  ON DELETE CASCADE 
  ON UPDATE NO ACTION
GO

EXECUTE dbo.DbFinalizeUpgrade 6035;
GO

COMMIT TRANSACTION UpgradeTo6035;
GO





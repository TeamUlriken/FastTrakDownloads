SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6056
PRINT 'Starting upgrade to 6056'

-- Purpose of this update:
--   Add fields to LabClass to select only lab classifications that are trusted
--   Add Journalansvarlig field to StudCase to allow for this role per protocol.
--   Add Highlight field to MetaFormItem to support highlighting of certain CRF variables
--   Add field NLK to table LabClass (Norsk Laboratoriekodeverk)
--   Add GrantTo field to DbProcList to allow custom rights on procedures
-- Author: Magne Rekdal

DELETE FROM DbUpgradeLog WHERE  DbVer > 6055;

EXEC DbCheckVersion 6055;
EXECUTE DbStartUpgrade 6056;
GO

IF dbo.DbColumnExists( 'LabClass', 'IsGroup') = 0
  ALTER TABLE dbo.LabClass ADD IsGroup BIT
GO

IF dbo.DbColumnExists( 'LabClass', 'TrustLevel') = 0
  ALTER TABLE dbo.LabClass ADD TrustLevel INT NOT NULL DEFAULT 0;
GO

ALTER PROCEDURE Report.GetLabData( @PersonId INT )
AS
BEGIN
  SELECT ld.PersonId, lc.VarName, ld.NumResult, ld.LabDate, ld.ResultId
  FROM dbo.LabData ld
    JOIN dbo.LabCode lc ON lc.LabCodeId = ld.LabCodeId
    JOIN dbo.LabClass la ON la.LabClassId = lc.LabClassId
  WHERE ( ld.PersonId = @PersonId ) AND ( la.TrustLevel > 2 );
END
GO

IF dbo.DbColumnExists( 'StudCase', 'Journalansvarlig' ) = 0
  ALTER TABLE dbo.StudCase ADD Journalansvarlig INT
  ALTER TABLE dbo.StudCase ADD CONSTRAINT FK_Journalansvarlig_UserId FOREIGN KEY ( Journalansvarlig ) REFERENCES dbo.UserList (UserId)
  ON UPDATE CASCADE; 
GO
 
IF NOT OBJECT_ID('dbo.UpdateCaseJournalansvar') IS NULL
  DROP PROCEDURE dbo.UpdateCaseJournalansvar
GO

CREATE PROCEDURE dbo.UpdateCaseJournalansvar( @StudyId INT, @PersonId INT )
AS
BEGIN
  UPDATE dbo.StudCase SET Journalansvarlig = USER_ID() WHERE StudyId=@StudyId AND PersonId=@PersonId
END
GO

GRANT EXECUTE ON dbo.UpdateCaseJournalansvar TO [Journalansvarlig]
GO

ALTER PROCEDURE dbo.ResetUserRoleInfo
AS
BEGIN
  DELETE FROM UserRoleInfo WHERE 1=1
   -- Innebygde roller
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('db_owner'           ,'Systemeier',         'Gir alle rettigheter lokalt i databasen, inkludert alle oppgraderinger. Kan bare tildeles av andre med samme rolle.', 1, 1 )
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('db_ddladmin'        ,'Oppgradering',       'Gir tillatelse til å oppgradere databasen.  Kan bare tildeles av systemeier (db_owner).', 1, 2 )
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('db_accessadmin'     ,'Opprette brukere',   'Gir tillatelse til å legge til/fjerne brukere, samt tildele andre roller til brukerne.  Kan bare tildeles av systemeier (db_owner).', 1, 3 )
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('db_securityadmin'   ,'Tilgangsstyring',    'Gir til å tildele andre roller til brukerne.  Kan bare tildeles av systemeier (db_owner).', 1, 4 )
  -- Systemansvarlig
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('superuser'          ,'Superbruker',        'Gir enkelte rettigheter rundt oppdatering av faginnhold i systemet.  Superbruker tildeles normalt også rollene Opprette brukere, Tilgangsstyring og Oppgradering (db_accessadmin, db_securityadmin, db_ddladmin).', 1, 5 )
  -- Hierarki 
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('Leder'             ,'Leder',              'Leder for en institusjon', 1, 6 )
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('Avdelingsleder'    ,'Avdelingsleder',     'Leder for en avdeling', 1, 7 )
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('Gruppeleder'       ,'Gruppeleder',        'Leder for en gruppe', 1, 8 )
  -- Spesielle roller/behov
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('ChangeWorksite'     ,'Ambulering',         'Gir tillatelse til å bytte arbeidssted selv.', 1, 9 )
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('ChangeProfession'   ,'Bytte yrke',         'Gir tillatelse til å bytte mellom flere yrker selv.', 1, 10 )
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('PrintPrescription'  ,'Forskrivningsrett',  'Gir tillatelse til utskrift av egne resepter.', 1, 11 )
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('Journalansvarlig'   ,'Journalansvarlig',   'Gir visse lovbestemte rettigheter og plikter rundt endring av journal.  Gjelder bare for de pasienter man er journalansvarlig for.', 1, 12 )
  -- Roller som ikke lenger er i bruk
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('DrugPrescriber'     ,'Resepter',           'Gir tillatelse til å klargjøre resepter.', 0, 13 )
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('DataImport'         ,'Importere data',     'Brukes for automatiske prosesser for dataimport.', 0, 14 )
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('EnterLabdata'       ,'Redigere labarket',  'Gir tillatelse til å redigere laboratoriebildet.', 0, 15 )
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('EPRResponsible'     ,'Journalansvarlig',   'Foreldet rolle, bruk Journalansvarlig i stedet.', 0, 16 )
  INSERT INTO dbo.UserRoleInfo( RoleName, RoleCaption, RoleInfo, IsActive, SortOrder ) VALUES('ProtocolOwner'      ,'Protokollansvarlig', 'Foreldet rolle, bruk Superuser i stedet.', 0, 17 )
END
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'Highlight' ) = 0
  ALTER TABLE dbo.MetaFormItem ADD Highlight TINYINT
GO

GRANT UPDATE ON dbo.MetaFormItem TO [superuser] AS [dbo]
GO

UPDATE dbo.MetaFormItem SET Highlight=1 WHERE FormId IN (618,649) AND ItemId IN (3196,3389,3342)
GO

ALTER PROCEDURE CRF.GetFormItems( @FormId INT ) AS
BEGIN
  SELECT mfi.OrderNumber,mi.ItemId,mi.VarName,mi.LabName,mi.ItemType,mi.UnitStr,
    mi.MinNormal,mi.MaxNormal,mi.ThreadTypeId, mi.Multiline,
    mfi.ExcludeFromText,mfi.ExcludeCaption, mfi.ItemHeader,mfi.ItemText,
    mfi.ItemHelp,mfi.Optional,mfi.ReadOnly,mfi.CarryForward,
    mfi.MinExpression,mfi.MaxExpression,mfi.Decimals,mfi.Expression, mfi.FormatStr,mfi.Highlight,
    DefaultValue,ISNULL(Visibility,1) as Visibility,mfi.PageNumber,mfi.LastUpdate 
  FROM dbo.MetaFormItem mfi 
    JOIN dbo.MetaItem mi ON mi.ItemId=mfi.ItemId 
    LEFT OUTER JOIN dbo.MetaFormPage mfp ON mfp.PageId=mfi.PageId 
  WHERE mfi.FormId=@FormId 
  ORDER BY mfi.PageNumber,mfi.OrderNumber
END
GO

EXECUTE dbo.ResetUserRoleInfo
GO

IF NOT OBJECT_ID('MetaFormCarryException') IS NULL DROP TABLE dbo.MetaFormCarryException
GO

CREATE TABLE dbo.MetaFormCarryException( 
 RowId INT NOT NULL,
 FormId INT NOT NULL,
 ItemId INT NOT NULL,
 EnumVal INT NOT NULL,
 LastUpdate DateTime NOT NULL )
GO

ALTER TABLE dbo.MetaFormCarryException ADD CONSTRAINT PK_MetaFormCarryException PRIMARY KEY (RowId)
GO
ALTER TABLE dbo.MetaFormCarryException ADD CONSTRAINT FK_MetaFormCarryException_FormId FOREIGN KEY (FormId)
REFERENCES dbo.MetaForm(FormId)
GO

ALTER TABLE dbo.MetaFormCarryException ADD CONSTRAINT FK_MetaFormCarryException_ItemId FOREIGN KEY (ItemId)
REFERENCES dbo.MetaItem(ItemId)
GO

IF NOT OBJECT_ID('CRF.GetFormCarryExceptions') IS NULL DROP PROCEDURE CRF.GetFormCarryExceptions
GO

CREATE PROCEDURE CRF.GetFormCarryExceptions AS
BEGIN
  SELECT FormId,ItemId,EnumVal FROM dbo.MetaFormCarryException ORDER BY FormId,ItemId,EnumVal
END
GO

GRANT EXECUTE ON CRF.GetFormCarryExceptions TO [public] AS [dbo]
GO

IF dbo.DbColumnExists( 'LabClass', 'NLK' ) = 0 
  ALTER TABLE dbo.LabClass ADD NLK VARCHAR(8) NULL
GO

IF dbo.DbColumnExists( 'DbProcList', 'GrantTo' ) = 0
  ALTER TABLE dbo.DbProcList ADD GrantTo VARCHAR(MAX)
GO

GRANT UPDATE ON dbo.DbProcList TO [superuser] AS [dbo]
GO

UPDATE dbo.DbProcList SET LastUpdate='2000-01-01'
GO

EXECUTE dbo.DbFinalizeUpgrade 6056;
GO

COMMIT TRANSACTION UpgradeTo6056;
GO


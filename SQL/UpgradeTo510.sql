EXEC AddSchema 'FEST'
GO

SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo510;
PRINT 'Starting upgrade to 510'

DELETE FROM DbUpgradeLog WHERE DbVer > 509;
GO
EXEC DbCheckVersion 509;           
EXECUTE DbStartUpgrade 510;
GO

ALTER TABLE dbo.MetaNomItem ALTER COLUMN ItemName VARCHAR(MAX)
GO

IF dbo.DbColumnExists( 'MetaNomList', 'OID') = 0
  ALTER TABLE MetaNomList ADD OID INT
GO 

IF NOT object_Id('FEST.GruppeVilkar') IS NULL 
  DROP TABLE FEST.GruppeVilkar
GO

IF NOT object_Id('FEST.KodeVilkar') IS NULL 
  DROP TABLE FEST.KodeVilkar
GO

IF NOT object_Id('FEST.Vilkar') IS NULL 
  DROP TABLE FEST.Vilkar
GO

IF NOT object_Id('FEST.Refusjonskode') IS NULL 
  DROP TABLE FEST.Refusjonskode
GO

IF NOT object_Id('FEST.Refusjonsgruppe') IS NULL 
  DROP TABLE FEST.Refusjonsgruppe
GO

IF NOT object_Id('FEST.Reseptgruppe') IS NULL 
  DROP TABLE FEST.Reseptgruppe
GO

IF NOT object_Id('FEST.Refusjonshjemmel') IS NULL 
  DROP TABLE FEST.Refusjonshjemmel
GO

CREATE TABLE FEST.Reseptgruppe ( 
  V CHAR(2) NOT NULL, 
  DN VARCHAR(24) NOT NULL )
GO

ALTER TABLE FEST.Reseptgruppe ADD CONSTRAINT PK_Reseptgruppe PRIMARY KEY (V)
GO

INSERT INTO FEST.Reseptgruppe (V,DN) VALUES( 'A','Reseptgruppe A' )
INSERT INTO FEST.Reseptgruppe (V,DN) VALUES( 'B','Reseptgruppe B' )
INSERT INTO FEST.Reseptgruppe (V,DN) VALUES( 'C','Reseptgruppe C' )
INSERT INTO FEST.Reseptgruppe (V,DN) VALUES( 'F','Reseptgruppe F' )
INSERT INTO FEST.Reseptgruppe (V,DN) VALUES( 'CF','Reseptgruppe CF' )
GO

CREATE TABLE FEST.Refusjonshjemmel ( 
  V INT NOT NULL, 
  S VARCHAR(24),
  DN VARCHAR(MAX) NOT NULL,
  KreverVedtak BIT,
  KreverVarekobling BIT,  
  OldCodeId INT,
  ShortCode VARCHAR(8),
  Informasjon VARCHAR(MAX) )
GO

ALTER TABLE FEST.Refusjonshjemmel ADD CONSTRAINT PK_Refusjonshjemmel PRIMARY KEY (V)
GO

INSERT INTO FEST.Refusjonshjemmel (V, S, DN, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (100, '2.16.578.1.12.4.1.1.7427', '�5.14', 0, NULL, 'Bl�reseptforskriften', 18);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (200, '2.16.578.1.12.4.1.1.7427', '�5-14 �2', '�2', 0, 1, 'Viser til legemidler med forh�ndsgodkjent refusjon, oppf�rt i refusjonslisten', 1);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (300, '2.16.578.1.12.4.1.1.7427', '�5-14 �3', '�3', 0, NULL, 'Viser til legemidler refundert etter individuell s�knad', 19);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (301, '2.16.578.1.12.4.1.1.7427', '�5-14 �3a','�3a', 1, 0, 'Dersom s�rlige grunner foreligger, ytes st�nad til et legemiddel som ikke er oppf�rt i refusjonslisten for den aktuelle refusjonskoden. St�nad forutsetter at den aktuelle bruken er dekket av en refusjonskode i refusjonslisten', 2);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (302, '2.16.578.1.12.4.1.1.7427', '�5-14 �3b','�3b', 1, NULL, 'Unntaksvis ytes st�nad til kostbare legemidler som brukes i behandling av kroniske sykdommer som ikke er nevnt i refusjonslisten', 3);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (400, '2.16.578.1.12.4.1.1.7427', '�5-14 �4', '�4', 0, 0, 'Allmennfarlige smittsomme sykdommer', 4);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (500, '2.16.578.1.12.4.1.1.7427', '�5-14 �5', '�5', 0, NULL, 'Viser til medisinsk forbruksmateriell', 20);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (501, '2.16.578.1.12.4.1.1.7427', '�5-14 �5.1','�5.1', 0, 1, 'Bleier og annet materiell som m� skiftes med visse mellomrom ved inkontinens som f�lge av varige forstyrrelser av endetarmens eller urinbl�rens funksjon', 5);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (502, '2.16.578.1.12.4.1.1.7427', '�5-14 �5.2','�5.2', 0, 1, 'Kateter og annet materiell som m� skiftes med visse mellomrom ved urinretensjon p� grunn av varige forstyrrelser av urinbl�rens funksjon', 6);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (503, '2.16.578.1.12.4.1.1.7427', '�5-14 �5.3','�5.3', 0, 1, 'Bandasjemateriell og kanyler o.l. som nyttes etter operasjoner i strupe og luftveier med langvarige eller varige fistler', 7);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (504, '2.16.578.1.12.4.1.1.7427', '�5-14 �5.4','�5.4', 0, 1, 'Ved diabetes ytes det st�nad til penner, spr�yter, forbruksmateriell til inhalator, spisser, lansetter, materiell til m�ling av sukker og ketoner i blod og urin, og inneliggende insulinkanyle/insulinknapp. For personer over 16 �r er det et vilk�r for rett til st�nad til inneliggende insulinkanyle/insulinknapp at vedkommende har vesentlige problemer med injeksjonene', 8);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (505, '2.16.578.1.12.4.1.1.7427', '�5-14 �5.5','�5.5', 0, 1, 'Stomiposer og annet materiell som m� skiftes med visse mellomrom pga. stomier fra tarm og urinveier. N�r det ytes st�nad til stomiposer kan det ogs� ytes st�nad til stomitang', 9);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (506, '2.16.578.1.12.4.1.1.7427', '�5-14 �5.6','�5.6', 0, 1, 'Ved bl�dersykdom ytes det st�nad til blodstillende produkter, og til spr�yter, spisser, kompresser og annet n�dvendig utstyr for � f� satt transfusjoner av faktorkonsentrater. Det ytes st�nad til inntil 400 spr�yter og spisser pr. �r. Til pasienter under 16 �r og til pasienter som p� grunn av spesielle forhold trenger flere enn 400 spr�yter og spisser pr. �r, ytes det st�nad til det n�dvendige antall etter begrunnet henvisning fra lege', 10);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (507, '2.16.578.1.12.4.1.1.7427', '�5-14 �5.7','�5.7', 0, 1, 'Ved kronisk obstruktiv lungesykdom og asthma bronchiale ytes det st�nad til spr�yter, spisser, fysiologisk saltvann, sterilt vann, PEF-m�lere, inntil 2 inhalasjonskamre med eller uten maske pr. �r og transtracheal oksygenkatetere og forlengelsesslanger. Det ytes st�nad til inntil 400 spr�yter og spisser pr. �r. Til pasienter under 16 �r og til pasienter som p� grunn av spesielle forhold trenger flere enn 400 spr�yter og spisser pr. �r, ytes det st�nad til det n�dvendige antall etter begrunnet henvisning fra lege. Anskaffelse av PEF-m�lere b�r v�re tilr�dd av spesialist i lungesykdommer, indremedisin eller barnesykdommer', 11);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (508, '2.16.578.1.12.4.1.1.7427', '�5-14 �5.8','�5.8', 0, 1, 'Til barn med veksthormonforstyrrelse ytes det st�nad til penner, spr�yter og spisser til injeksjon av veksthormonpreparater. Det ytes st�nad til enten inntil 400 spr�yter og spisser pr. �r eller til 3 penner i pasientens behandlingsperiode og inntil 400 spisser pr. �r. Til pasienter som p� grunn av spesielle forhold trenger flere enn 400 spr�yter og spisser pr. �r, ytes det st�nad til det n�dvendige antall etter begrunnet anvisning fra lege. Behandlingsutstyret m� v�re instituert i sykehus eller sykehuspoliklinikk, som ogs� m� v�re ansvarlig for kontroll og oppf�lging av behandlingen', 12);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (509, '2.16.578.1.12.4.1.1.7427', '�5-14 �5.9','�5.9', 0, 1, 'For nyretransplanterte ytes det st�nad til teststrimler til m�ling av blod og proteiner i urin. Det ytes st�nad til inntil 400 teststrimler pr. �r etter anvisning fra spesialist i indremedisin', 21);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (510, '2.16.578.1.12.4.1.1.7427', '�5-14 �5.10','�5.10', 0, 1, 'Hoftebeskytter til personer med osteoporose med tidligere lavenergibrudd og til personer med vesentlig svekket benstruktur som p� grunn av medikamentbruk og helseplager har �kt risiko for � falle. Hoftebeskytteren m� v�re rekvirert av lege. Det kan ekspederes/utleveres inntil 4 hoftebeskyttere per �r', 13);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (511, '2.16.578.1.12.4.1.1.7427', '�5-14 �5.11','�5.11', 0, 1, 'Medisinsk forbruksmateriell til m�ling av glukose/sukker i blod og urin for personer som er avhengige av intraven�s ern�ring', 22);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (600, '2.16.578.1.12.4.1.1.7427', '�5-14 �6', '�6', 0, NULL, 'Viser til n�ringsmidler', 23);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (601, '2.16.578.1.12.4.1.1.7427', '�5-14 �6.1','�6.1', 1, 0, 'N�ringsmidler ved sykelige prosesser som affiserer munn, svelg og spiser�r og som hindrer tilf�rsel av vanlig mat. Sykelige prosesser som affiserer mage eller tarm, og som hindrer opptak av viktige n�ringsstoffer. Stoffskiftesykdom (metabolsk sykdom). Behandlingsrefrakt�r epilepsi (ketogen diett)', 14);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (602, '2.16.578.1.12.4.1.1.7427', '�5-14 �6.2','�6.2', 1, 0, 'N�ringsmidler ved laktose-, melkeproteinintoleranse eller -allergi hos barn under 10 �r', 15);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (603, '2.16.578.1.12.4.1.1.7427', '�5-14 �6.3','�6.3', 0, 0, 'N�ringsmidler ved Fenylketonuri (F�llings sykdom)', 16);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, ShortCode, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (604, '2.16.578.1.12.4.1.1.7427', '�5-14 �6.4','�6.4', 1, 0, 'N�ringsmidler ved behandling av kreft/immunsvikt eller annen sykdom som medf�rer s� sterk svekkelse at n�ringstilskudd er p�krevd', 17);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (700, '2.16.578.1.12.4.1.1.7427', '�5-22', 0, 0, 'Viser til bidragssats prevensjonsmidler', 24);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (701, '2.16.578.1.12.4.1.1.7427', '�5.22I', 0, NULL, 'Immunsvikt, referer gml. � 9 pkt. 38', 25);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (702, '2.16.578.1.12.4.1.1.7427', '�5.22K', 0, NULL, 'Kreft, referer gml. � 9 pkt. 9', 26);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (703, '2.16.578.1.12.4.1.1.7427', '�5.22P', 0, NULL, 'P-piller til jenter i alderen 16-19 �r', 27);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (704, '2.16.578.1.12.4.1.1.7427', '�5.22S', 0, NULL, 'Smerter i terminalfase andre diagnoser', 28);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (800, '2.16.578.1.12.4.1.1.7427', '�5.25', 0, NULL, 'Yrkesskade', 29);
INSERT INTO FEST.Refusjonshjemmel (V, S, DN, KreverVedtak, KreverVarekobling, Informasjon, OldCodeId) VALUES (900, '2.16.578.1.12.4.1.1.7427', '�10-7i', 0, 1, 'Brystproteser', 30);
GO

CREATE TABLE FEST.Refusjonsgruppe
 (                        
   Id VARCHAR(40) NOT NULL,
   Status CHAR(1) NOT NULL,
   Tidspunkt DateTime NOT NULL,
   RefRefusjonshjemmel INT,
   GruppeNr VARCHAR(12) NOT NULL,
   GruppeNavn VARCHAR(MAX),
   Atc VARCHAR(7),      
   KreverRefusjonskode BIT NOT NULL,
   RefusjonsberettigetBruk VARCHAR(MAX),
)

ALTER TABLE FEST.Refusjonsgruppe ADD CONSTRAINT PK_Refusjonsgruppe PRIMARY KEY (Id)
GO

ALTER TABLE FEST.Refusjonsgruppe ADD CONSTRAINT FK_Refusjonsgruppe_Refusjonshjemmel FOREIGN KEY (RefRefusjonshjemmel) REFERENCES FEST.Refusjonshjemmel(V)
GO

CREATE UNIQUE INDEX IDX_Refusjonsgruppe_Gruppenr ON FEST.Refusjonsgruppe(GruppeNr)
GO

CREATE TABLE FEST.Refusjonskode
 (            
   Id uniqueidentifier NOT NULL, -- Added by Emetra AS
   RefRefusjonsgruppe VARCHAR(40) NOT NULL,
   V VARCHAR(6) NOT NULL,
   S VARCHAR(32) NOT NULL,
   DN VARCHAR(MAX) NOT NULL,       
   OID INTEGER NOT NULL,   
   Underterm VARCHAR(MAX),
   RefVilkar Uniqueidentifier,
   GyldigFraDato DateTime NOT NULL,
   GyldigTilDato DateTime NULL
 )
                                                                                                  
ALTER TABLE FEST.Refusjonskode ADD CONSTRAINT PK_Refusjonskode PRIMARY KEY (Id)
GO

ALTER TABLE FEST.Refusjonskode ADD CONSTRAINT FK_Refusjonskode_Refusjonsgruppe
  FOREIGN KEY (RefRefusjonsgruppe) REFERENCES FEST.Refusjonsgruppe( Id )
GO

ALTER TABLE FEST.RefusjonsKode ADD ICPC2 AS ( 1-ABS(SIGN(OID-7170)))
ALTER TABLE FEST.RefusjonsKode ADD ICD10 AS ( 1-ABS(SIGN(OID-7110)))
GO

CREATE TABLE FEST.Vilkar
(
  Id VARCHAR(40) NOT NULL,  
  Status CHAR(1) NOT NULL,
  Tidspunkt DateTime NOT NULL,
  VilkarNr INT NOT NULL,
  Gruppe INT,
  GjelderFor INT,
  Tekst VARCHAR(MAX),
  GyldigFraDato DateTime NOT NULL,
  GyldigTilDato DateTime NULL
)

ALTER TABLE FEST.Vilkar ADD CONSTRAINT PK_Vilkar PRIMARY KEY (Id)
GO

CREATE TABLE FEST.GruppeVilkar
( Id UniqueIdentifier NOT NULL,
  RefRefusjonsgruppe VARCHAR(40) NOT NULL,
  RefVilkar VARCHAR(40) NOT NULL 
)

ALTER TABLE FEST.GruppeVilkar ADD CONSTRAINT PK_GruppeVilkar PRIMARY KEY (RefRefusjonsgruppe,RefVilkar)
GO

ALTER TABLE FEST.GruppeVilkar ADD CONSTRAINT FK_GruppeVilkar_Vilkar FOREIGN KEY (RefVilkar) REFERENCES FEST.Vilkar(Id)
ALTER TABLE FEST.GruppeVilkar ADD CONSTRAINT FK_GruppeVilkar_Gruppe FOREIGN KEY (RefRefusjonsgruppe) REFERENCES FEST.Refusjonsgruppe(Id)
GO

CREATE TABLE FEST.KodeVilkar
( 
  Id uniqueidentifier NOT NULL,
  RefRefusjonskode uniqueidentifier NOT NULL,
  RefVilkar VARCHAR(40) NOT NULL 
)

ALTER TABLE FEST.KodeVilkar ADD CONSTRAINT PK_KodeVilkar PRIMARY KEY (RefRefusjonskode,RefVilkar)
GO

ALTER TABLE FEST.KodeVilkar ADD CONSTRAINT FK_KodeVilkar_Vilkar FOREIGN KEY (RefVilkar) REFERENCES FEST.Vilkar(Id)
ALTER TABLE FEST.KodeVilkar ADD CONSTRAINT FK_KodeVilkar_Refusjonskode FOREIGN KEY (RefRefusjonskode) REFERENCES FEST.Refusjonskode(Id)
GO


IF EXISTS( SELECT id FROM sysobjects WHERE name='MetaReimbursementCode' AND type='V' )
  DROP VIEW dbo.MetaReimbursementCode
GO

IF EXISTS( SELECT id FROM sysobjects WHERE name='OldMetaReimbursementCode' AND type='U' )
  EXEC sp_rename 'OldMetaReimbursementCode','MetaReimbursementCode'
GO

IF dbo.DbColumnExists( 'MetaReimbursementCode','OID7427') = 0
  ALTER TABLE MetaReimbursementCode ADD OID7427 INT
GO

IF dbo.DbColumnExists( 'DrugPrescription','ProbCode') = 0
  ALTER TABLE DrugPrescription ADD ProbCode VARCHAR(8)
GO

ALTER PROCEDURE dbo.GetReimbCodes AS
BEGIN
  SELECT CodeId,CodeText,CodeHeader,'' AS CodeInfo FROM MetaReimbursementCode
   WHERE CodeId IN (1,2,3,4)
END
GO

IF dbo.DbColumnExists( 'MetaReimbursementCode','CodeInfo') = 1
  ALTER TABLE MetaReimbursementCode DROP COLUMN CodeInfo
GO

IF dbo.DbColumnExists( 'MetaReimbursementCode','ProdType') = 1
  ALTER TABLE MetaReimbursementCode DROP COLUMN ProdType
GO

IF dbo.DbColumnExists( 'MetaReimbursementCode','ValidFrom') = 1
  ALTER TABLE MetaReimbursementCode DROP COLUMN ValidFrom
GO

IF dbo.DbColumnExists( 'MetaReimbursementCode','ValidUntil') = 1
  ALTER TABLE MetaReimbursementCode DROP COLUMN ValidUntil
GO

GRANT UPDATE,INSERT ON MetaReimbursementCode TO [public]
GO

UPDATE MetaReimbursementCode SET OID7427=200 WHERE CodeId=1
UPDATE MetaReimbursementCode SET OID7427=301 WHERE CodeId=2
UPDATE MetaReimbursementCode SET OID7427=302 WHERE CodeId=3
UPDATE MetaReimbursementCode SET OID7427=400 WHERE CodeId=4
UPDATE MetaReimbursementCode SET OID7427=501 WHERE CodeId=5
UPDATE MetaReimbursementCode SET OID7427=502 WHERE CodeId=6
UPDATE MetaReimbursementCode SET OID7427=503 WHERE CodeId=7
UPDATE MetaReimbursementCode SET OID7427=504 WHERE CodeId=8
UPDATE MetaReimbursementCode SET OID7427=505 WHERE CodeId=9
UPDATE MetaReimbursementCode SET OID7427=506 WHERE CodeId=10
UPDATE MetaReimbursementCode SET OID7427=507 WHERE CodeId=11
UPDATE MetaReimbursementCode SET OID7427=508 WHERE CodeId=12
UPDATE MetaReimbursementCode SET OID7427=510 WHERE CodeId=13
UPDATE MetaReimbursementCode SET OID7427=601 WHERE CodeId=14
UPDATE MetaReimbursementCode SET OID7427=602 WHERE CodeId=15
UPDATE MetaReimbursementCode SET OID7427=603 WHERE CodeId=16
UPDATE MetaReimbursementCode SET OID7427=604 WHERE CodeId=17
GO

IF ( SELECT(MAX(CodeId)) FROM MetaReimbursementCode ) = 17
BEGIN
  INSERT INTO MetaReimbursementCode (CodeId,CodeText,CodeHeader,OID7427)
    VALUES(18,'�5-14','Bl�reseptforskriften',100) 
  INSERT INTO MetaReimbursementCode (CodeId,CodeText,CodeHeader,OID7427)
    VALUES(19,'�3','Individuell s�knad',300) 
  INSERT INTO MetaReimbursementCode (CodeId,CodeText,CodeHeader,OID7427)
    VALUES(20,'�5','Medisinsk forbruksmateriell',500) 
  INSERT INTO MetaReimbursementCode (CodeId,CodeText,CodeHeader,OID7427)
    VALUES(21,'�5.9','Nyretransplanterte',509) 
  INSERT INTO MetaReimbursementCode (CodeId,CodeText,CodeHeader,OID7427)
    VALUES(22,'�5.9','Intraven�s ern�ring',511) 
  INSERT INTO MetaReimbursementCode (CodeId,CodeText,CodeHeader,OID7427)
    VALUES(23,'�6','N�ringsmidler',600) 
  INSERT INTO MetaReimbursementCode (CodeId,CodeText,CodeHeader,OID7427)
    VALUES(24,'�5-22','Prevensjonsmidler',700) 
  INSERT INTO MetaReimbursementCode (CodeId,CodeText,CodeHeader,OID7427)
    VALUES(25,'�5-22I','Immunsvikt',701) 
  INSERT INTO MetaReimbursementCode (CodeId,CodeText,CodeHeader,OID7427)
    VALUES(26,'�5-22K','Kreft',702) 
  INSERT INTO MetaReimbursementCode (CodeId,CodeText,CodeHeader,OID7427)
    VALUES(27,'�5-22P','P-piller for unge',703) 
  INSERT INTO MetaReimbursementCode (CodeId,CodeText,CodeHeader,OID7427)
    VALUES(28,'�5-22S','Smerter i terminalfase',704) 
  INSERT INTO MetaReimbursementCode (CodeId,CodeText,CodeHeader,OID7427)
    VALUES(29,'�5-25','Yrkesskade',800) 
  INSERT INTO MetaReimbursementCode (CodeId,CodeText,CodeHeader,OID7427)
    VALUES(30,'�10-7i','Brystproteser',900)
END 
GO

REVOKE UPDATE,INSERT,DELETE ON MetaReimbursementCode TO [public]
GO

IF NOT OBJECT_ID('FEST.FinnRefusjonskoder') IS NULL DROP PROCEDURE FEST.FinnRefusjonskoder
GO

CREATE PROCEDURE FEST.FinnRefusjonskoder( @ATC VARCHAR(7) ) AS 
BEGIN
  DECLARE @OID INT;
  DECLARE @AltOID INT;      
  -- Choose alternative OID based on ICPC/ICD10 problem list
  SELECT @OID = OID FROM MetaNomList l JOIN UserList ul ON ul.ProbListId = l.ListId AND ul.UserId=USER_ID();
  IF @OID = 7110 SET @AltOid=7435;
  IF @OID = 7170 SET @AltOId=7434;
  -- Find matching codes for ATC
  SELECT rk.V as CodeText, ISNULL(rk.Underterm,rk.DN) as CodeHeader,rk.OID,rg.GruppeNavn,rg.RefRefusjonshjemmel AS OID7427
    INTO #temp
    FROM FEST.Refusjonskode rk 
    JOIN FEST.Refusjonsgruppe rg ON rg.Id = rk.RefRefusjonsgruppe
  WHERE CHARINDEX(rg.ATC,@ATC)=1 
    AND ( rg.Status='A' )
    AND ( ( rk.OID = @OID ) OR ( rk.OID = @AltOid ) )
    AND ( ( rk.GyldigFraDato < getdate() ) AND ( ISNULL(rk.GyldigTilDato,getdate()+1) > getdate() ) ); 
  -- Select codes without duplicates 
  SELECT DISTINCT mr.CodeId,t.CodeText,t.CodeHeader,mr.CodeText as CodeInfo 
    FROM #temp t JOIN MetaReimbursementCode mr ON mr.OID7427=t.OID7427
    ORDER BY t.CodeText,mr.CodeText 
END
GO

GRANT EXECUTE ON FEST.FinnRefusjonskoder TO public
GO

IF NOT OBJECT_ID('dbo.UpdateRxProblemCode') IS NULL DROP PROCEDURE dbo.UpdateRxProblemCode
GO

CREATE PROCEDURE dbo.UpdateRxProblemCode( @PrescId INT, @ProbCode VARCHAR(8) ) AS
BEGIN
  UPDATE DrugPrescription SET ProbCode=@ProbCode WHERE PrescId=@PrescId;
END
GO

GRANT EXECUTE ON dbo.UpdateRxProblemCode TO public
GO

EXECUTE DbFinalizeUpgrade 510;

COMMIT TRANSACTION UpgradeTo510;
GO


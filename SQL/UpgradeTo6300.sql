SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6300
PRINT 'Starting upgrade to 6300'

-- Upgrade type: Mixed
-- Purpose of this upgrade
--- Altered procedure GetUsers to include only users where hasdbaccess=1, and excludes dbo, DENY CONNECT will remove users from this list.
--- Added function GetMyPersonId() to support procedures dbo.UpdatePersonHPRNo and UpdatePersonGSM.
--- Added procedures for updating HPRNo and GSM, to avoid having to do UPDATE on dbo.Person table.
--- Altered procedure CRF.GetClinData to include ObsDate field in result set.
--- Altered procedure CRF.GetSingleFormData to include optional @ChangedAfter parameter and ObsDate field in result set.
--- Added procedure dbo.GetDrugsForAdverseReactions to avoid SELECT on dbo.DrugTreatment (may be denied).
--- Added function dbo.GetMyProfession() to support easy checks for profession.
--- Added procedure dbo.UpdatePersonImportantInfo to avoid UPDATE on dbo.Person (is always denied now).
--- Added function dbo.NationalIdIsValid to check for invalid NationalIds.
--- Added procedure CRF.GetClinForms to replace dbo.GetClinForms and support archived forms.
--- Added procedure CRF.UpdateClinFormArchiveStatus to support archived forms.
--- Added procedure CRF.GetClinForm to support Archived bit
--- Dropped procedure dbo.LoadClinForm, and created synonym to CRF.GetClinForm instead.
--- Added procedure CRF.AddClinDataDate

EXEC DbCheckVersion 6058;
EXECUTE DbStartUpgrade 6300;
GO

ALTER PROCEDURE dbo.GetUsers AS
BEGIN
  SELECT su.name AS UserName, su.hasdbaccess, su.uid AS UserId, p.ReverseName, ISNULL(ul.IsActive,1) AS IsActive, mp.ProfName
  FROM sys.sysusers su
    LEFT JOIN dbo.UserList ul on ul.UserId=su.uid
    LEFT JOIN dbo.Person p ON ul.PersonId=p.PersonId
    LEFT JOIN dbo.MetaProfession mp ON mp.ProfId=ul.ProfId
  WHERE (su.islogin=1) AND (su.hasdbaccess=1) AND (su.isntgroup=0)
    AND ( NOT su.name in ('dbo','sys','guest') ) 
  ORDER BY su.name
END
GO

IF NOT OBJECT_ID( 'dbo.GetMyPersonId') IS NULL 
  DROP FUNCTION dbo.GetMyPersonId
GO

CREATE FUNCTION dbo.GetMyPersonId() RETURNS INT
AS
BEGIN
  DECLARE @PersonId INT;
  SET @PersonId = 0;
  SELECT TOP 1 @PersonId = PersonId FROM dbo.UserList WHERE UserId = USER_ID();
  RETURN @PersonId;
END
GO

GRANT EXECUTE ON dbo.GetMyPersonId TO [public] AS [dbo]
GO

IF NOT OBJECT_ID( 'dbo.UpdatePersonHPRNo') IS NULL 
  DROP PROCEDURE dbo.UpdatePersonHPRNo
GO

CREATE PROCEDURE dbo.UpdatePersonHPRNo ( @PersonId INT, @HPRNo INT) AS
BEGIN
  -- Must be superuser or dbo to update somebody elses HPRNo
  IF (is_rolemember('superuser') = 0 AND is_rolemember('db_owner') = 0 AND dbo.GetMyPersonId() <> @PersonId) 
  BEGIN
    RAISERROR( 'Du kan bare endre ditt eget HPR-Nummer!',16,1 )
    RETURN -1;
  END;
  UPDATE dbo.Person SET HPRNo = CASE WHEN @HPRNo = 0 THEN NULL ELSE @HPRNo END WHERE PersonId = @PersonId
END
GO

GRANT EXECUTE ON dbo.UpdatePersonHPRNo TO [public] AS [dbo]
GO

IF NOT OBJECT_ID( 'dbo.UpdatePersonGSM') IS NULL 
  DROP PROCEDURE dbo.UpdatePersonGSM
GO

CREATE PROCEDURE dbo.UpdatePersonGSM ( @PersonId INT, @GSM VARCHAR(16)) AS
BEGIN
  -- Must be superuser or dbo to update somebody elses GSM
  IF (is_rolemember('superuser') = 0 AND is_rolemember('db_owner') = 0 AND dbo.GetMyPersonId() <> @PersonId) 
  BEGIN
    RAISERROR( 'Du kan kun endre ditt eget telefonnummer!',16,1 )
    RETURN -1;
  END;
  UPDATE dbo.Person SET GSM = @GSM WHERE PersonId = @PersonId
END
GO

GRANT EXECUTE ON dbo.UpdatePersonGSM TO [public] AS [dbo]
GO

ALTER PROCEDURE CRF.GetClinData( @StudyId INT, @PersonId INT ) AS
BEGIN
  SELECT 
    cdp.RowId, ce.EventId, ce.EventNum, ce.EventTime, mi.ItemId, mi.VarName, 
    cdp.Quantity, cdp.EnumVal, cdp.DTVal, cdp.TextVal, 
    cdp.ObsDate, cdp.Locked, cdp.ChangeCount
  FROM dbo.ClinDataPoint cdp
    JOIN dbo.ClinEvent ce ON ce.EventId=cdp.EventId 
    JOIN dbo.MetaItem mi ON mi.ItemId=cdp.ItemId
  WHERE ce.PersonId=@PersonId
  ORDER BY ce.EventNum,ce.EventId;
END
GO

ALTER PROCEDURE CRF.GetSingleFormData( @ClinFormId INT, @ChangedAfter DateTime = NULL ) AS
BEGIN
  IF @ChangedAfter IS NULL SET @ChangedAfter = '1980-01-01';
  SELECT 
    cdp.RowId, cdp.EventId,ce.EventNum, ce.EventTime, mi.ItemId, mi.VarName,
    cdp.Quantity, cdp.EnumVal, cdp.DTVal, cdp.TextVal, 
    cdp.ObsDate, cdp.Locked, cdp.ChangeCount
  FROM dbo.ClinDataPoint cdp
    JOIN dbo.ClinEvent ce ON ce.EventId=cdp.EventId
    JOIN dbo.ClinForm cf ON cf.EventId=cdp.EventId
    JOIN dbo.MetaFormItem mfi ON mfi.FormId=cf.FormId AND mfi.ItemId=cdp.ItemId
    JOIN dbo.MetaItem mi ON mi.ItemId = cdp.ItemId
  WHERE ( cf.ClinFormId=@ClinFormId ) AND ( ( cdp.ObsDate > @ChangedAfter ) OR ( cdp.LockedAt > @ChangedAfter ) );
END
GO

IF NOT OBJECT_ID('dbo.GetDrugsForAdverseReactions', 'P') IS NULL
  DROP PROCEDURE dbo.GetDrugsForAdverseReactions
GO

CREATE PROCEDURE dbo.GetDrugsForAdverseReactions( @PersonId INT ) AS
BEGIN
  SELECT DISTINCT ATC,DrugName,DrugForm, NULL AS StartReason,NULL AS DoseCode,NULL AS StrengthUnit,NULL AS Strength 
  FROM dbo.DrugTreatment 
  WHERE PersonId=@PersonId AND DATALENGTH(ATC)>2 
  ORDER BY DrugName;
END
GO

GRANT EXECUTE ON dbo.GetDrugsForAdverseReactions TO [public] AS [dbo]
GO

IF NOT OBJECT_ID( 'dbo.GetMyProfession') IS NULL 
  DROP FUNCTION dbo.GetMyProfession
GO

CREATE FUNCTION dbo.GetMyProfession() RETURNS VARCHAR(3) AS
BEGIN
  DECLARE @RetVal VARCHAR(3);
  SELECT @RetVal = ProfType 
  FROM dbo.UserList ul 
    JOIN dbo.MetaProfession mp ON mp.ProfId=ul.ProfId
  WHERE ul.UserId=USER_ID();
  RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetMyProfession TO [public] AS [dbo]
GO

IF NOT OBJECT_ID( 'dbo.UpdatePersonImportantInfo', 'P') IS NULL
  DROP PROCEDURE dbo.UpdatePersonImportantInfo
GO

CREATE PROCEDURE dbo.UpdatePersonImportantInfo( @PersonId INT, @DocId INT, @DocText VARCHAR(MAX) )
AS
BEGIN
  IF NOT dbo.GetMyProfession() IN ('LE','SP') 
  BEGIN
    RAISERROR( 'Bare leger og sykepleiere kan redigere denne informasjonen!', 16, 1 );
	RETURN -1;
  END;
  IF @DocId=50001 
    UPDATE dbo.Person SET CAVE=@DocText WHERE PersonId=@PersonId
  ELSE IF @DocId=50003 
    UPDATE dbo.Person SET Reservations=@DocText WHERE PersonId=@PersonId
  ELSE IF @DocId=50005 
    UPDATE dbo.Person SET NB=@DocText WHERE PersonId=@PersonId
  ELSE IF @DocId=11036
    UPDATE dbo.Person SET Allergies=@DocText WHERE PersonId=@PersonId
  ELSE
    RAISERROR( 'Ukjent dokumentidentifikator angitt.', 16, 1 );
END
GO

GRANT EXECUTE ON dbo.UpdatePersonImportantInfo TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('NationalIdIsValid') IS NULL 
  DROP FUNCTION dbo.NationalIdIsValid
GO

CREATE FUNCTION dbo.NationalIdIsValid (@NationalId VARCHAR(11)) RETURNS INTEGER
AS  
BEGIN  
  DECLARE @pasientid VARCHAR (11);
  DECLARE @d1 integer, @d2 integer, @m1 integer, 
          @m2 integer, @a1 integer, @a2 integer, 
          @i1 integer, @i2 integer, @i3 integer, 
          @k1 integer, @k2 integer;

  SET @pasientid = RIGHT(REPLICATE('0',11) + @NationalId,11)
  SET @d1 = CAST(SUBSTRING(@pasientid,  1, 1) AS INTEGER)
  SET @d2 = CAST(SUBSTRING(@pasientid,  2, 1) AS INTEGER)
  SET @m1 = CAST(SUBSTRING(@pasientid,  3, 1) AS INTEGER)
  SET @m2 = CAST(SUBSTRING(@pasientid,  4, 1) AS INTEGER)
  SET @a1 = CAST(SUBSTRING(@pasientid,  5, 1) AS INTEGER)
  SET @a2 = CAST(SUBSTRING(@pasientid,  6, 1) AS INTEGER)
  SET @i1 = CAST(SUBSTRING(@pasientid,  7, 1) AS INTEGER)
  SET @i2 = CAST(SUBSTRING(@pasientid,  8, 1) AS INTEGER)
  SET @i3 = CAST(SUBSTRING(@pasientid,  9, 1) AS INTEGER)
  SET @k1 = CAST(SUBSTRING(@pasientid, 10, 1) AS INTEGER)
  SET @k2 = CAST(SUBSTRING(@pasientid, 11, 1) AS INTEGER)
  
  IF (((3 * @d1 + 7 * @d2 + 6 * @m1 + 1 * @m2 + 8 * @a1 + 9 * @a2 + 4 * @i1 + 5 * @i2 + 2 * @i3 + 1 * @k1) % 11) != 0) RETURN 0;
  IF (((5 * @d1 + 4 * @d2 + 3 * @m1 + 2 * @m2 + 7 * @a1 + 6 * @a2 + 5 * @i1 + 4 * @i2 + 3 * @i3 + 2 * @k1 + 1 * @k2) % 11) != 0) RETURN 0;
  RETURN 1;
END
GO

GRANT EXECUTE ON dbo.NationalIdIsValid TO [public] AS [dbo]
GO

GRANT UPDATE ON dbo.ClinForm TO [public] AS [dbo]
GO

IF  dbo.DbColumnExists( 'ClinForm', 'Archived' ) = 0
  ALTER TABLE dbo.ClinForm ADD Archived BIT NOT NULL CONSTRAINT DF_ClinForm_Archived DEFAULT (0)
GO

REVOKE UPDATE ON dbo.ClinForm TO [public]
GO

IF NOT OBJECT_ID('CRF.GetClinForms', 'P') IS NULL
  DROP PROCEDURE CRF.GetClinForms
GO

CREATE PROCEDURE CRF.GetClinForms( @StudyId INT, @PersonId INT, @IncludeArchived BIT ) AS
BEGIN
  -- Log reads
  INSERT INTO dbo.CaseLog (PersonId,LogType,LogText)
  VALUES( @PersonId,'LESE','Journal lest av ' + USER_NAME() );
  --- Get forms
  SELECT ce.EventNum,cf.FormId,ce.EventId,ce.EventTime,mf.FormTitle,mf.FormName,
    cf.ClinFormId,cf.FormStatus,cf.FormComplete,cf.Comment,cf.CachedText,
    mfs.StatusDesc,cf.CreatedAt,cf.SignedAt, cf.Archived,
    up1.Signature AS CreatedBySign, ul1.ProfId AS CreatedByProfId, cf.CreatedBy,
    up2.Signature AS SignedBySign, ul2.ProfId AS SignedByProfId, cf.SignedBy
  FROM dbo.ClinEvent ce
    JOIN dbo.ClinForm cf on cf.EventId=ce.EventId AND ( cf.DeletedAt IS NULL )
    JOIN dbo.MetaFormStatus mfs ON mfs.FormStatus=cf.FormStatus
    JOIN dbo.MetaForm mf on mf.FormId=cf.FormId
    JOIN dbo.MetaStudyForm msf ON msf.FormId=cf.FormId AND msf.StudyId = @StudyId
    LEFT JOIN dbo.UserList ul1 ON ul1.UserId=cf.CreatedBy
    LEFT JOIN dbo.UserList ul2 ON ul2.UserId=cf.SignedBy
    LEFT JOIN dbo.Person up1 ON up1.PersonId=ul1.PersonId
    LEFT JOIN dbo.Person up2 ON up2.PersonId=ul2.PersonId
  WHERE ( ce.PersonId = @PersonId ) AND ( ( cf.Archived = 0 ) OR ( @IncludeArchived = 1 ) );
END
GO

GRANT EXECUTE ON CRF.GetClinForms TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('CRF.UpdateClinFormArchiveStatus', 'P') IS NULL
  DROP PROCEDURE CRF.UpdateClinFormArchiveStatus 
GO

CREATE PROCEDURE CRF.UpdateClinFormArchiveStatus( @ClinFormId INT, @ArchiveStatus BIT ) AS
BEGIN
  UPDATE dbo.ClinForm SET Archived = @ArchiveStatus 
  WHERE ( ClinFormId = @ClinFormId ) AND ( Archived <> @ArchiveStatus );
END
GO

GRANT EXECUTE ON CRF.UpdateClinFormArchiveStatus TO [Journalansvarlig] AS [dbo]
GRANT EXECUTE ON CRF.UpdateClinFormArchiveStatus TO [superuser] AS [dbo]
GO

IF NOT OBJECT_ID('CRF.GetClinForm','P') IS NULL DROP PROCEDURE CRF.GetClinForm
GO

CREATE PROCEDURE CRF.GetClinForm( @ClinFormId INT ) AS
BEGIN
  SELECT e.EventNum, cf.FormId, e.EventId, e.EventTime, mf.FormTitle, mf.FormName,
      cf.ClinFormId, cf.FormStatus, cf.FormComplete, cf.Comment, cf.CachedText,
      mfs.StatusDesc, cf.CreatedAt, cf.SignedAt, cf.Archived,
      up1.Signature AS CreatedBySign, cf.CreatedBy, ul1.ProfId AS CreatedByProfId,
      up2.Signature AS SignedBySign, cf.SignedBy, ul2.ProfId AS SignedByProfId
  FROM dbo.ClinEvent e
    JOIN dbo.ClinForm cf on cf.EventId=e.EventId
    JOIN dbo.MetaFormStatus mfs ON mfs.FormStatus=cf.FormStatus
    LEFT JOIN dbo.MetaForm mf on mf.FormId=cf.FormId
    LEFT JOIN dbo.UserList ul1 ON ul1.UserId=cf.CreatedBy
    LEFT JOIN dbo.Person up1 ON up1.PersonId=ul1.PersonId
    LEFT JOIN dbo.UserList ul2 ON ul2.UserId=cf.SignedBy
    LEFT JOIN dbo.Person up2 ON up2.PersonId=ul2.PersonId
  WHERE ClinFormId=@ClinFormId;
END
GO

GRANT EXECUTE ON CRF.GetClinForm TO [public] AS [dbo]
GO

IF NOT OBJECT_ID( 'dbo.LoadClinForm','P') IS NULL
  DROP PROCEDURE dbo.LoadClinForm
GO

IF NOT OBJECT_ID( 'dbo.LoadClinForm','SN') IS NULL
  DROP SYNONYM dbo.LoadClinForm
GO

CREATE SYNONYM dbo.LoadClinForm FOR CRF.GetClinForm
GO

GRANT EXECUTE ON dbo.LoadClinForm TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('dbo.ReportLabTestOverview','V') IS NULL 
  DROP VIEW dbo.ReportLabTestOverview
GO

IF NOT OBJECT_ID( 'CRF.AddClinDataTextVal') IS NULL 
  DROP PROCEDURE CRF.AddClinDataTextVal
GO

CREATE PROCEDURE CRF.AddClinDataTextVal( @TouchId INT, @ItemId INT, @TextVal VARCHAR(MAX) )
AS
BEGIN
  DECLARE @Locked INT;
  DECLARE @RowId INT;
  DECLARE @OldTextVal VARCHAR(MAX);
  DECLARE @EventId INT;

  SELECT @EventId = EventId FROM dbo.ClinTouch WHERE TouchId=@TouchId;
  -- Get existing data
  SELECT @RowId = RowId, @Locked=Locked, @OldTextVal=TextVal
    FROM dbo.ClinDataPoint WHERE EventId=@EventId AND ItemId = @ItemId;
  -- Add if not found
  IF ( @RowId IS NULL )
    INSERT INTO dbo.ClinDataPoint ( TouchId, EventId, ItemId, TextVal ) VALUES ( @TouchId, @EventId, @ItemId, @TextVal )
  ELSE IF ( ISNULL( @OldTextVal, '' ) <> ISNULL( @TextVal, '' ) )
  BEGIN
    -- Need to change
    IF @Locked <> 0
    BEGIN
      RAISERROR( 'Could not save data.  This row is signed.', 16, 1 );
      RETURN -2;
    END;
    UPDATE dbo.ClinDataPoint SET TouchId = @TouchId, TextVal = @TextVal, ChangeCount = ChangeCount + 1, ObsDate=GETDATE() 
    WHERE RowId=@RowId;
  END
END
GO

GRANT EXECUTE ON CRF.AddClinDataTextVal TO [public] AS [dbo]
GO

CREATE PROCEDURE dbo.UtilResetTestActors AS
BEGIN
  UPDATE dbo.Person SET TestCase=1 WHERE NationalId IN (
    '15076500565','21016400952','12057900499','13116900216','14019800513','70019950032','05073500186',
    '70019950032','02039000183', '08077000292', '15040650560','21030550231','12050050295','04056600324',
    '20086600138','03117000205','16126800464','22047800106','28027000608','17108300566', '14076800236' );
  DELETE FROM dbo.LabData WHERE PersonId IN (SELECT PersonId FROM Person WHERE TestCase=1 )
  UPDATE dbo.ImportContext SET LastUpdate = '1980-01-01' WHERE ContextName IN (SELECT 'HVIKT.'+CONVERT(VARCHAR,PersonId) FROM dbo.Person WHERE TestCase=1 );
  UPDATE dbo.ImportContext SET LastUpdate = '1980-01-01' WHERE ContextName IN (SELECT 'DIPS.'+CONVERT(VARCHAR,PersonId) FROM dbo.Person WHERE TestCase=1 );
END
GO

ALTER PROCEDURE Report.GetFormData( @PersonId INT, @FormName VARCHAR(32) ) AS
BEGIN
  SET NOCOUNT ON;
  -- Retrieve data actually registered on specific form with latest data first
  SELECT a.* FROM
  (
    SELECT ce.PersonId,mi.VarName,dp.Quantity,ce.EventTime,dp.RowId,
      RANK() OVER ( PARTITION BY mi.ItemId ORDER BY ce.EventTime, dp.RowId DESC ) AS OrderBy 
    FROM dbo.ClinDatapoint dp 
      JOIN dbo.ClinEvent ce ON ce.EventId = dp.EventId
      JOIN dbo.ClinForm cf ON cf.EventId = ce.EventId
      JOIN dbo.MetaItem mi ON mi.ItemId = dp.ItemId
      JOIN dbo.MetaFormItem mfi ON mfi.FormId = cf.FormId AND mfi.ItemId = mi.ItemId
      JOIN dbo.MetaForm mf ON mf.FormId = mfi.FormId 
    WHERE mf.FormName = @FormName AND ce.PersonId = @PersonId
  ) a
  WHERE a.OrderBy = 1;
END
GO

IF NOT OBJECT_ID('Report.GetFormVariableData') IS NULL 
  DROP PROCEDURE Report.GetFormVariableData
GO

CREATE PROCEDURE Report.GetFormVariableData( @PersonId INT, @FormName VARCHAR(32) ) AS
BEGIN
  SET NOCOUNT ON;
  -- Retrieve variables that appear on specific form with latest data first
  SELECT a.* FROM 
  (
    SELECT ce.PersonId,mi.VarName,dp.Quantity,ce.EventTime,dp.RowId,
       RANK() OVER ( PARTITION BY mi.ItemId ORDER BY ce.EventTime DESC, dp.RowId DESC ) AS OrderBy
    FROM dbo.ClinDatapoint dp 
      JOIN dbo.ClinEvent ce ON ce.EventId = dp.EventId
      JOIN dbo.MetaFormItem mfi ON mfi.ItemId = dp.ItemId
      JOIN dbo.MetaForm mf ON mf.FormId = mfi.FormId 
      JOIN dbo.MetaItem mi ON mi.ItemId = dp.ItemId
    WHERE mf.FormName = @FormName AND ce.PersonId = @PersonId
   ) a
   WHERE a.OrderBy = 1;
END
GO

GRANT EXECUTE ON Report.GetFormVariableData TO [public] AS [dbo]
GO

ALTER PROCEDURE Report.GetLabData( @PersonId INT ) AS
BEGIN
  SET NOCOUNT ON;
  -- Retrieve labdata, latest first
  SELECT a.* FROM 
  (
    SELECT ld.PersonId, lc.VarName, ld.NumResult, ld.LabDate, ld.ResultId,
      RANK() OVER ( ORDER BY LabDate DESC ) AS OrderBy
    FROM dbo.LabData ld
      JOIN dbo.LabCode lc ON lc.LabCodeId = ld.LabCodeId
      JOIN dbo.LabClass la ON la.LabClassId = lc.LabClassId
    WHERE ( ld.PersonId = @PersonId ) AND ( la.TrustLevel > 2 )
  ) a
  WHERE a.OrderBy = 1;
END
GO

IF NOT OBJECT_ID('CRF.AddClinDataDate') IS NULL 
  DROP PROCEDURE CRF.AddClinDataDate
GO

CREATE PROCEDURE CRF.AddClinDataDate ( @TouchId INT, @ItemId INT, @DTVal DateTime )
AS
BEGIN
  DECLARE @Locked INT;
  DECLARE @RowId INT;
  DECLARE @OldDTVal DateTime;
  DECLARE @EventId INT;
  SELECT @EventId = EventId FROM dbo.ClinTouch WHERE TouchId=@TouchId;
  -- Get existing data
  SELECT @RowId = RowId, @Locked=Locked, @OldDTVal=DTVal
    FROM dbo.ClinDataPoint WHERE EventId=@EventId AND ItemId = @ItemId;
  -- Add if not found
  IF ( @RowId IS NULL )
    INSERT INTO dbo.ClinDataPoint ( TouchId, EventId, ItemId, DTVal ) VALUES ( @TouchId, @EventId, @ItemId, @DTVal )
  ELSE IF ( @OldDTVal <> @DTVal ) OR ( @OldDTVal IS NULL AND NOT @DTVal IS NULL ) OR ( @DTVal IS NULL AND NOT @OldDTVal IS NULL )
  BEGIN
    -- Need to change
    IF @Locked <> 0
    BEGIN
      RAISERROR( 'Could not save data.  This row is signed.', 16, 1 );
      RETURN -2;
    END;
    -- Set new value
    UPDATE dbo.ClinDataPoint SET TouchId=@TouchId, DTVal=@DTVal, ChangeCount=ChangeCount + 1, ObsDate=GETDATE() 
    WHERE RowId=@RowId;
  END
END
GO

GRANT EXECUTE ON CRF.AddClinDataDate TO [public] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6300;
GO

COMMIT TRANSACTION UpgradeTo6300;
GO





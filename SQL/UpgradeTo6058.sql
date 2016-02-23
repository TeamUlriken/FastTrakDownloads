SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6058
PRINT 'Starting upgrade to 6058'

-- Purpose of this update:
--   Removed logging from procedures AddClinDataEnum and AddClinDataQuantity, as logging is done by trigger.
---  Dropped unused LastUpdate fields from metadata tables where all rows are updated every time.
---  Added GetLastXXXInPeriod functions to use for reporting.
---  Fixed bug in GetMyMetaForms, duplicates when forms appear in multiple studies.
---  Modified views NDV.Type1 and NDV.Type2 for better performance.
---  Altered procedures AddLabName and UpdateLabClassId to reflect that LoincCode field is gone.
---  Removed LoincCode field from table LabCode, should only be in LabClass.
---  Added LabClassId to table MetaItem with corresponding foreign key.
---  Added procedure CRF.GetItemToLabMapping to return MetaItems that should be treated as labdata.
---  Dropped schemas ORM (empty) and QA (with a view and a procedure ).
---  Added procedure CRF.GetSingleFormData to allow refresh of single form, for better multiuser-support.
---  Using GRANT CONNECT and DENY CONNECT in AddUser and DeleteUser.
---  Added procedure Report.GetPercentileRanksByName for QuickStat.
---  Altered procedure CRF.CanSignClinForm to include information about who signed, and negative error codes in @CanSign.
---  Altered procedure CRF.DeleteClinFormItems to avoid keeping shared items on deleted forms (See bug #5062)
---  Added procedure Report.GetFormsAsPivotData for study matrix reports.
---  Dropped view NDV.LabData, no longer used.

DELETE FROM DbUpgradeLog
WHERE  DbVer > 6057;

EXEC DbCheckVersion 6057;
EXECUTE DbStartUpgrade 6058;
GO

ALTER PROCEDURE CRF.AddClinDataEnum ( @TouchId INT, @ItemId INT, @EnumVal INT )
AS
BEGIN
  DECLARE @Locked INT;
  DECLARE @RowId INT;
  DECLARE @OldEnumVal INT;
  DECLARE @EventId INT;

  SELECT @EventId = EventId FROM dbo.ClinTouch WHERE TouchId=@TouchId;
  -- Get existing data
  SELECT @RowId = RowId, @Locked=Locked, @OldEnumVal=EnumVal
    FROM dbo.ClinDataPoint WHERE EventId=@EventId AND ItemId = @ItemId;
  -- Add if not found
  IF ( @RowId IS NULL )
    INSERT INTO dbo.ClinDataPoint ( TouchId, EventId, ItemId, EnumVal, Quantity ) VALUES ( @TouchId, @EventId, @ItemId, @EnumVal, @EnumVal )
  ELSE IF ( ISNULL( @OldEnumVal, -1 ) <> ISNULL( @EnumVal, -1 ) )
  BEGIN
    -- Need to change
    IF @Locked <> 0
    BEGIN
      RAISERROR( 'Could not save data.  This row is signed.', 16, 1 );
      RETURN -2;
    END;
    UPDATE dbo.ClinDataPoint SET TouchId = @TouchId, EnumVal = @EnumVal, Quantity = @EnumVal, ChangeCount = ChangeCount + 1, ObsDate=GETDATE() 
    WHERE RowId=@RowId;
  END
END
GO

ALTER PROCEDURE CRF.AddClinDataQuantity ( @TouchId INT, @ItemId INT, @Quantity FLOAT )
AS
BEGIN
  DECLARE @Locked INT;
  DECLARE @RowId INT;
  DECLARE @OldQuantity FLOAT;
  DECLARE @EventId INT;
  SELECT @EventId = EventId FROM dbo.ClinTouch WHERE TouchId=@TouchId;
  -- Get existing data
  SELECT @RowId = RowId, @Locked=Locked, @OldQuantity=Quantity
    FROM dbo.ClinDataPoint WHERE EventId=@EventId AND ItemId = @ItemId;
  -- Add if not found
  IF ( @RowId IS NULL )
    INSERT INTO dbo.ClinDataPoint ( TouchId, EventId, ItemId, Quantity ) VALUES ( @TouchId, @EventId, @ItemId, @Quantity )
  ELSE IF ( @OldQuantity <> @Quantity ) OR ( @OldQuantity IS NULL AND NOT @Quantity IS NULL ) OR ( @Quantity IS NULL AND NOT @OldQuantity IS NULL )
  BEGIN
    -- Need to change
    IF @Locked <> 0
    BEGIN
      RAISERROR( 'Could not save data.  This row is signed.', 16, 1 );
      RETURN -2;
    END;
    -- Set new value
    UPDATE dbo.ClinDataPoint SET TouchId=@TouchId, Quantity=@Quantity, ChangeCount=ChangeCount + 1, ObsDate=GETDATE() 
    WHERE RowId=@RowId;
  END
END
GO

IF dbo.DbColumnExists( 'FEST.Refusjonsgruppe','LastUpdate' ) = 1
  ALTER TABLE FEST.Refusjonsgruppe DROP COLUMN LastUpdate
GO

IF dbo.DbColumnExists( 'FEST.Refusjonskode','LastUpdate' ) = 1
  ALTER TABLE FEST.Refusjonskode DROP COLUMN LastUpdate
GO

IF dbo.DbColumnExists( 'FEST.Vilkar','LastUpdate' ) = 1
  ALTER TABLE FEST.Vilkar DROP COLUMN LastUpdate
GO

IF NOT OBJECT_ID('GetLastDTValInPeriod') IS NULL DROP FUNCTION dbo.GetLastDTValInPeriod
GO

CREATE FUNCTION dbo.GetLastDTValInPeriod( @PersonId INT, @ItemId INT, @StartAt DateTime, @StopAt DateTime ) RETURNS DateTime AS
BEGIN
 DECLARE @RetVal DateTime;
 SET @RetVal = ( SELECT TOP 1 cd.DTVal FROM dbo.ClinDataPoint cd
   JOIN dbo.ClinEvent ce ON ce.EventId=cd.EventId
   WHERE ( ce.PersonId=@PersonId ) AND ( cd.ItemId=@ItemId ) AND ( NOT DTVal IS NULL )
   AND ( ce.EventTime < @StopAt ) AND ( ce.EventTime >= @StartAt )
   ORDER BY ce.EventNum DESC );
   RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetLastDTValInPeriod TO [public] as [dbo]
GO

IF NOT OBJECT_ID('GetLastEnumValInPeriod') IS NULL DROP FUNCTION dbo.GetLastEnumValInPeriod
GO

CREATE FUNCTION dbo.GetLastEnumValInPeriod( @PersonId INT, @ItemId INT, @StartAt DateTime, @StopAt DateTime ) RETURNS INT AS
BEGIN
 DECLARE @RetVal INT;
 SET @RetVal = ( SELECT TOP 1 cd.EnumVal FROM dbo.ClinDataPoint cd
   JOIN dbo.ClinEvent ce ON ce.EventId=cd.EventId
   WHERE ( ce.PersonId=@PersonId ) AND ( cd.ItemId=@ItemId ) AND ISNULL(cd.EnumVal,-1) <> -1
   AND ( ce.EventTime < @StopAt ) AND ( ce.EventTime >= @StartAt )
   ORDER BY ce.EventNum DESC );
   RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetLastEnumValInPeriod TO [public] as [dbo]
GO

IF NOT OBJECT_ID('GetLastTextValInPeriod') IS NULL DROP FUNCTION dbo.GetLastTextValInPeriod
GO

CREATE FUNCTION dbo.GetLastTextValInPeriod( @PersonId INT, @ItemId INT, @StartAt DateTime, @StopAt DateTime ) RETURNS VARCHAR(64) AS
BEGIN
 DECLARE @RetVal VARCHAR(64);
 SET @RetVal = ( SELECT TOP 1 cd.TextVal FROM dbo.ClinDataPoint cd
   JOIN dbo.ClinEvent ce ON ce.EventId=cd.EventId
   WHERE ( ce.PersonId=@PersonId ) AND ( cd.ItemId=@ItemId ) AND ISNULL(cd.TextVal,'') <> ''
   AND ( ce.EventTime < @StopAt ) AND ( ce.EventTime >= @StartAt )
   ORDER BY ce.EventNum DESC );
   RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetLastTextValInPeriod TO [public] as [dbo]
GO

IF NOT OBJECT_ID('GetLastQuantityInPeriod') IS NULL DROP FUNCTION dbo.GetLastQuantityInPeriod
GO

CREATE FUNCTION dbo.GetLastQuantityInPeriod( @PersonId INT, @ItemId INT, @StartAt DateTime, @StopAt DateTime ) RETURNS DECIMAL(18,4) AS
BEGIN
 DECLARE @RetVal DECIMAL(18,4);
 SET @RetVal = ( SELECT TOP 1 cd.Quantity FROM dbo.ClinDataPoint cd
   JOIN dbo.ClinEvent ce ON ce.EventId=cd.EventId
   WHERE ( ce.PersonId=@PersonId ) AND ( cd.ItemId=@ItemId ) AND ( NOT cd.Quantity IS NULL )
   AND ( ce.EventTime < @StopAt ) AND ( ce.EventTime >= @StartAt )
   ORDER BY ce.EventNum DESC );
   RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetLastQuantityInPeriod TO [public] as [dbo]
GO

ALTER PROCEDURE dbo.GetMyMetaForms( @StudyId INT, @MyProfession INT = 0 ) AS
BEGIN
  SET NOCOUNT ON;
  IF @MyProfession = 1
  BEGIN                                                
    SELECT msf.FormId,count(cf.FormId) as UsedTimes
    INTO #temp
      FROM Meta.StudyForm msf 
      JOIN dbo.ClinForm cf ON cf.FormId=msf.FormId AND cf.CreatedAt > getdate()-365
      JOIN dbo.UserList ul ON ul.UserId=cf.CreatedBy
      JOIN dbo.UserList me ON me.ProfId=ul.ProfId AND me.UserId=USER_ID()
    WHERE msf.StudyId=@StudyId AND dbo.MetaFormIsUsable( msf.FormId ) = 1
      GROUP BY msf.FormId;
    SELECT TOP 15 msf.* 
    FROM Meta.StudyForm msf 
    JOIN #temp t ON t.FormId=msf.FormId 
    WHERE ( t.UsedTimes > 3 ) AND ( msf.StudyId=@StudyId )
    ORDER BY UsedTimes DESC;
  END
  ELSE
  BEGIN
    SELECT msf.* FROM Meta.StudyForm msf
    JOIN dbo.UserList ul ON ul.UserId=USER_ID()
    WHERE msf.StudyId=@StudyId AND dbo.MetaFormIsUsable( msf.FormId ) = 1
    ORDER BY msf.FormId
  END
END
GO

ALTER VIEW NDV.Type1 AS
SELECT a.PersonId,v.DOB,v.FullName,v.GroupName,DATEDIFF( yy, v.DOB, getdate() ) AS Age
FROM 
(
  SELECT ce.PersonId, dp.EnumVal AS NDV_TYPE,
  RANK() OVER (PARTITION BY ce.PersonId ORDER BY EventNum DESC ) AS OrderBy
  FROM dbo.ClinEvent ce
  JOIN dbo.ClinDataPoint dp ON dp.EventId=ce.EventId
  WHERE dp.ItemId=3196
) a
JOIN dbo.ViewActiveCaseListStub v ON v.PersonId=a.PersonId
JOIN dbo.Study s ON s.StudyId=v.StudyId AND s.StudyName='NDV'
WHERE a.OrderBy=1 AND a.NDV_TYPE=1
GO

ALTER VIEW NDV.Type2 AS
SELECT a.PersonId,v.DOB,v.FullName,v.GroupName,DATEDIFF( yy, v.DOB, getdate() ) AS Age
FROM 
(
  SELECT ce.PersonId, dp.EnumVal AS NDV_TYPE,
  RANK() OVER (PARTITION BY ce.PersonId ORDER BY EventNum DESC ) AS OrderBy
  FROM dbo.ClinEvent ce
  JOIN dbo.ClinDataPoint dp ON dp.EventId=ce.EventId
  WHERE dp.ItemId=3196
) a
JOIN dbo.ViewActiveCaseListStub v ON v.PersonId=a.PersonId
JOIN dbo.Study s ON s.StudyId=v.StudyId AND s.StudyName='NDV'
WHERE a.OrderBy=1 AND a.NDV_TYPE=2
GO

ALTER PROCEDURE dbo.AddLabName( @LabName VARCHAR(40) ) AS
BEGIN
  DECLARE @LabCodeId INT;
  SELECT @LabCodeId = LabCodeId FROM dbo.LabCode WHERE LabName = @LabName;
  IF @LabCodeId IS NULL
  BEGIN
    INSERT INTO dbo.LabCode(LabName) VALUES (@LabName);
    SET @LabCodeId = SCOPE_IDENTITY();
  END;
  SELECT lc.LabCodeId, lc.LabName, lcl.VarName, lcl.Loinc as LoincCode, lc.SynonymId, lc.CreatedAt, lc.CreatedBy
  FROM dbo.LabCode lc LEFT OUTER JOIN dbo.LabClass lcl ON lcl.LabClassId=lc.LabClassId 
  WHERE lc.LabCodeId = @LabCodeId;
END
GO

ALTER PROCEDURE dbo.UpdateLabClassId( @LabCodeId INT, @LabClassId INT ) AS
BEGIN
  IF @LabClassId = 0 SET @LabClassId=NULL;
  UPDATE dbo.LabCode SET LabClassId=NULLIF(@LabClassId,0) WHERE LabCodeId=@LabCodeId;
  -- Copy VarName field
  UPDATE dbo.LabCode SET VarName = ( SELECT VarName FROM dbo.LabClass WHERE LabClassId=LabCode.LabClassId )
    WHERE LabCodeId=@LabCodeId;
END
GO

IF dbo.DbColumnExists( 'LabCode', 'LoincCode' ) = 1
  ALTER TABLE dbo.LabCode DROP COLUMN LoincCode
GO

IF dbo.DbColumnExists( 'MetaItem', 'LabClassId' ) = 0
BEGIN
  ALTER TABLE dbo.MetaItem ADD LabClassId INT NULL
  ALTER TABLE dbo.MetaItem ADD CONSTRAINT FK_MetaItem_LabClassId FOREIGN KEY(LabClassId) REFERENCES dbo.LabClass(LabClassId)
END
GO

IF NOT OBJECT_ID('CRF.GetItemToLabMapping') IS NULL DROP PROCEDURE CRF.GetItemToLabMapping
GO

CREATE PROCEDURE CRF.GetItemToLabMapping AS
BEGIN
  SELECT mi.ItemId,lc.LabClassId,lc.FriendlyName FROM dbo.MetaItem mi 
  JOIN dbo.LabClass lc ON lc.LabClassId=mi.LabClassId
END
GO

GRANT EXECUTE ON CRF.GetItemToLabMapping TO [public] AS [dbo]
GO

GRANT UPDATE ON dbo.MetaItem TO [public] AS [dbo]
UPDATE dbo.MetaItem SET LastUpdate = '2000-01-01'
REVOKE UPDATE ON dbo.MetaItem TO [public]
GO
    
IF NOT SCHEMA_ID('ORM') IS NULL
  DROP SCHEMA [ORM]
GO

IF NOT OBJECT_ID('QA.LabDataNumericInTxtResult') IS NULL 
  DROP VIEW QA.LabDataNumericInTxtResult
GO

IF NOT OBJECT_ID('QA.RepairLabData') IS NULL
  DROP PROCEDURE QA.RepairLabData
GO

IF NOT SCHEMA_ID('QA') IS NULL
  DROP SCHEMA [QA]
GO

IF NOT OBJECT_ID('CRF.GetSingleFormData') IS NULL DROP PROCEDURE CRF.GetSingleFormData
GO

CREATE PROCEDURE CRF.GetSingleFormData( @ClinFormId INT )
AS
BEGIN
  SELECT cdp.RowId, cdp.EventId,ce.EventNum,ce.EventTime, 
    cdp.ItemId, cdp.Quantity, cdp.EnumVal, cdp.DTVal, cdp.TextVal, cdp.Locked, cdp.ChangeCount,
	mi.VarName
  FROM dbo.ClinDataPoint cdp
  JOIN dbo.ClinEvent ce ON ce.EventId=cdp.EventId
  JOIN dbo.ClinForm cf ON cf.EventId=cdp.EventId
  JOIN dbo.MetaFormItem mfi ON mfi.FormId=cf.FormId AND mfi.ItemId=cdp.ItemId
  JOIN dbo.MetaItem mi ON mi.ItemId = cdp.ItemId
  WHERE cf.ClinFormId=@ClinFormId
END
GO

GRANT EXECUTE ON CRF.GetSingleFormData TO [public] AS [dbo]
GO

ALTER PROCEDURE dbo.DeleteUser( @UserName NVARCHAR(128) ) AS
BEGIN
  DECLARE @UserId INT;           
  DECLARE @SqlCmd NVARCHAR(128);
  SELECT @UserId=UserId from dbo.UserList WHERE (UserName=@UserName) AND ( UserId > 0 );
  IF @UserId IS NULL
  BEGIN
    SET @UserId = USER_ID(@UserName);
    IF @UserId > 0
      INSERT INTO dbo.UserList (UserId,UserName,IsActive) VALUES ( @UserId,@UserName,0 );
    ELSE
      RAISERROR( 'Databasebrukeren "%s" finnes ikke', 16, 1, @UserName )
  END
  ELSE
    UPDATE dbo.UserList SET IsActive=0 WHERE UserId=@UserId;
  EXECUTE( 'DENY CONNECT TO [' + @UserName + ']' );   
END
GO

ALTER PROCEDURE dbo.AddUser( @UserName NVARCHAR(128), @Password varchar(30) = NULL )
AS
BEGIN
  DECLARE @DbName NVARCHAR(128);
  DECLARE @OldUserName NVARCHAR(128);
  DECLARE @OldUserId INT;
  DECLARE @InsertUser BIT;
  DECLARE @UserId INT;
  SET @DbName=DB_NAME();
  /* First check for existing login, create if needed */
  IF ( CHARINDEX( CHAR(92), @username ) = 0 )
  BEGIN
    IF NOT EXISTS( SELECT name FROM master.dbo.syslogins where name = @UserName)
      EXEC sp_addlogin @UserName,@Password,@DbName;
  END;
  IF EXISTS( SELECT name FROM sysusers WHERE name=@UserName )
  BEGIN
    /* Reactivate existing user */ 
    SET @UserId = USER_ID(@UserName);
    IF NOT EXISTS( SELECT UserId FROM UserList WHERE UserId=@UserId AND UserName=@UserName )
      INSERT INTO UserList( UserId,UserName,IsActive ) VALUES( @UserId,@UserName,1)                                                                   
    ELSE  
      UPDATE UserList SET IsActive=1 WHERE UserId=@UserId AND UserName=@UserName;
    EXECUTE( 'GRANT CONNECT TO [' + @UserName + ']' );
  END  
  ELSE BEGIN
    /* Grant access to the database */
    EXEC sp_grantdbaccess @UserName;
    SET @UserId = USER_ID(@UserName);
    /* Check for existing users (disabled) with this UserId */
    SELECT @OldUserName = UserName, @OldUserId = UserId FROM UserList WHERE UserId=@UserId;
    IF ( @OldUserId IS NULL )
      INSERT INTO UserList( UserId,UserName,IsActive ) VALUES( @UserId,@UserName,1)                                                                   
    ELSE IF ISNULL(@OldUserName,'') = @UserName
      UPDATE UserList SET IsActive=1 WHERE UserId=@UserId AND UserName=@UserName;
    ELSE
    BEGIN
      /* Not good, a user with this UserId has been deleted, and the username is different */
      RAISERROR( 'Brukeren kunne ikke legges til: UserId/UserName konflikt.\nKontakt leverandøren (DIPS ASA) snarest!', 16,1 );
      RETURN -1;
    END;
  END;
END
GO

IF NOT object_id('Report.GetPercentileRanksByName') IS NULL
  DROP PROCEDURE Report.GetPercentileRanksByName
GO

CREATE PROCEDURE Report.GetPercentileRanksByName( @LabVarName VARCHAR(24) )
AS
BEGIN
  WITH LabRankCount
  AS (SELECT ld.ResultId, ld.NumResult, rank() OVER (ORDER BY ld.NumResult) AS RankOrder, count(*) OVER () AS TotalCount
      FROM dbo.LabData ld
        JOIN dbo.LabCode lc
          ON lc.LabCodeId = ld.LabCodeId
      WHERE (lc.VarName = @LabVarName)
        AND (ld.NumResult > 0)
  )
  SELECT DISTINCT NumResult, 1. * (RankOrder - 1) / (TotalCount - 1) * 100 AS percentilerank
  FROM LabRankCount
  ORDER BY NumResult
END
GO

GRANT EXECUTE ON Report.GetPercentileRanksByName TO [public] AS [dbo]
GO

ALTER PROCEDURE CRF.CanSignClinForm( @ClinFormId INT )
AS
BEGIN
  DECLARE @CanSign INT;
  DECLARE @ErrMsg VARCHAR(512);
  DECLARE @SignedByName VARCHAR(255);
  DECLARE @IsSigned INT;

  SET @CanSign = 1;
  SET @IsSigned = 0;

  -- Is it already signed?
  SELECT @IsSigned = 1, @SignedByName = ISNULL( p.FullName, '(ukjent bruker)' )
  FROM   dbo.ClinForm cf
  LEFT JOIN dbo.UserList ul ON ul.UserId = cf.SignedBy
  LEFT JOIN dbo.Person p ON p.PersonId = ul.PersonId
  WHERE  ClinFormId = @ClinFormId AND FormStatus = 'L';

  IF @IsSigned = 1
    BEGIN
      SET @CanSign = -1;
      SET @ErrMsg = 'Skjema er allerede signert av ' + @SignedByName + '!';
    END
  ELSE IF dbo.HasSignClinFormPrivilege( @ClinFormId, NULL ) = 0
    BEGIN
      SET @CanSign = -2;
      SET @ErrMsg = 'Du har ikke rettigheter til å signere dette skjemaet!';
    END
  ELSE
    BEGIN
      SET @CanSign = 1;
      SET @ErrMsg = '';
    END
  SELECT @CanSign AS CanSign, @ErrMsg AS ErrMsg;
END
GO

ALTER PROCEDURE CRF.DeleteClinFormItems( @ClinFormId INT )
AS
BEGIN
  DECLARE @PersonId INT;  
  DECLARE @EventId INT;
  DECLARE @FormId INT;
  SET XACT_ABORT ON;
  BEGIN TRANSACTION DeleteItems;
  -- Find person and event number for this form
  SELECT @EventId = ce.EventId, @PersonId = ce.PersonId, @FormId = cf.FormId
  FROM   dbo.ClinEvent ce
  JOIN   dbo.ClinForm cf ON cf.EventId = ce.EventId
  WHERE  ClinFormId = @ClinFormId;
  -- Find items unique to this form
  SELECT ItemId INTO #tempItems 
    FROM dbo.MetaFormItem WHERE FormId = @FormId
  EXCEPT
    SELECT mfi.ItemId 
      FROM dbo.ClinEvent ce 
      JOIN dbo.ClinForm cf ON ( cf.EventId = ce.EventId ) AND ( cf.DeletedAt IS NULL )
      JOIN dbo.MetaFormItem mfi ON mfi.FormId = cf.FormId 
    WHERE  ( ce.EventId=@EventId ) AND ( cf.ClinFormId <> @ClinFormId );
  -- Insert datapoints into deleted table
  INSERT INTO dbo.ClinDatapointDeleted ( RowId,ItemId,EventId,TouchId,ClinFormId,ObsDate,Quantity,DTVal,EnumVal,TextVal,ChangeCount,Locked,LockedAt,LockedBy,guid )
  SELECT RowId,ItemId,EventId,TouchId,@ClinFormId,ObsDate,Quantity,DTVal,EnumVal,TextVal,ChangeCount,Locked,LockedAt,LockedBy,guid 
  FROM dbo.ClinDatapoint WHERE EventId=@EventId AND ItemId IN (SELECT ItemId FROM #tempItems);
  --- Delete datapoints
  DELETE FROM dbo.ClinDatapoint WHERE EventId=@EventId AND ItemId IN (SELECT ItemId FROM #tempItems);
  COMMIT TRANSACTION DeleteItems;
END
GO

IF NOT object_id('Report.GetFormsAsPivotTable') IS NULL
  DROP PROCEDURE Report.GetFormsAsPivotTable
GO

CREATE PROCEDURE Report.GetFormsAsPivotTable ( @Forms NVARCHAR(MAX), @StudyName NVARCHAR(30), @OrderBy NVARCHAR(MAX) = '')
AS
BEGIN
  -- @Forms should only containt F's, ,'s and digits
  IF ISNUMERIC ( REPLACE(REPLACE(REPLACE(@Forms,'F',''),',',''),' ','')) = 0
  BEGIN
    RAISERROR( 'Invalid parameter-format!',16,1 )
    RETURN
  END

  -- @OrderBy should only contain 'DESC', 'ReverseName', 'GroupName', 'PersonId', and/or commas and 'F<num>'s
  DECLARE @TrimmedOrderBy NVARCHAR(MAX)
  SET @TrimmedOrderBy  = UPPER(@OrderBy)
  SET @TrimmedOrderBy  = REPLACE (@TrimmedOrderBy, 'DESC','')
  SET @TrimmedOrderBy  = REPLACE (@TrimmedOrderBy, 'REVERSENAME','')
  SET @TrimmedOrderBy  = REPLACE (@TrimmedOrderBy, 'GROUPNAME','')
  SET @TrimmedOrderBy  = REPLACE (@TrimmedOrderBy, 'PERSONID','')
  SET @TrimmedOrderBy  = REPLACE (@TrimmedOrderBy, 'F','')
  SET @TrimmedOrderBy  = REPLACE (@TrimmedOrderBy, ',','')
  IF @TrimmedOrderBy <> '' AND ISNUMERIC(@TrimmedOrderBy) = 0
  BEGIN
    RAISERROR( 'Invalid parameter-format!',16,1 )
    RETURN
  END

  DECLARE @stmt NVARCHAR(MAX)
  SET @stmt = 'SELECT PersonId, ReverseName, GroupName, ' + @Forms + ' FROM ' +
              '( SELECT c.PersonId,c.ReverseName,v.GroupName, ' + 
                        '''F''+Cast(a.FormId AS VARCHAR) AS [FormId], ' + 
                        'b.EventTime ' +
                  'FROM dbo.ClinForm a ' + 
                        'JOIN dbo.ClinEvent b ON b.EventId = a.EventId ' + 
                        'JOIN dbo.Person c ON c.PersonId = a.PersonId '+      
                        'JOIN dbo.ViewActiveCaseListStub v ON v.PersonId=a.PersonId ' + 
                        'JOIN dbo.Study s ON s.StudyId=v.StudyId AND s.StudName='''+ @StudyName +''' ' + 
                 'WHERE a.FormId IN ( ' + REPLACE(@Forms,'F','') + ') ' + 
                   'AND a.DeletedBy IS NULL) AS s ' +
              'PIVOT (MAX(EventTime) FOR [FormId] IN ( ' + @Forms + ')) AS b ' +
              CASE WHEN @OrderBy <> '' THEN 'ORDER BY ' + @OrderBy ELSE '' END;
  EXEC sys.sp_executesql  @stmt
END
GO

GRANT EXECUTE ON Report.GetFormsAsPivotTable TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('NDV.LabData') IS NULL DROP VIEW NDV.LabData
GO

EXECUTE dbo.DbFinalizeUpgrade 6058;
GO

COMMIT TRANSACTION UpgradeTo6058;
GO



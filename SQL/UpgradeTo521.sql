SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo521;
PRINT 'Starting upgrade to 521'
DELETE FROM DbUpgradeLog WHERE DbVer > 520;

EXEC DbCheckVersion 520;       
EXECUTE DbStartUpgrade 521;
GO

GRANT SELECT,UPDATE ON dbo.DrugTreatment TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('dbo.GetLastLabInThePast') IS NULL DROP FUNCTION dbo.GetLastLabInThePast
GO

CREATE FUNCTION dbo.GetLastLabInThePast( @PersonId INT, @VarName VARCHAR(24), @CutoffTime DateTime = NULL ) RETURNS FLOAT
AS
BEGIN
  DECLARE @RetVal FLOAT;
  IF @CutoffTime IS NULL SET @CutoffTime = getdate();
  SET @RetVal = ( SELECT TOP 1 ld.NumResult
    FROM LabData ld JOIN LabCode lc ON ( lc.labCodeId=ld.LabCodeId ) AND ( VarName=@VarName )
    WHERE ( PersonId=@PersonId ) AND ( ISNULL(NumResult,-1) <> -1 ) AND ( ld.LabDate < @CutoffTime )
    ORDER BY ld.LabDate DESC )
 RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetLastLabInThePast to [public] AS [dbo]
GO

EXEC DbLogChange 521, 'Feature','New function to retrieve labdata before specific date in the past (for research)'
GO

EXEC DbLogChange 521, 'Feature','New function to retrieve form quantities before specific date in the past (for research)'
GO


IF NOT OBJECT_ID('dbo.GetLastQuantityInThePast') IS NULL DROP FUNCTION dbo.GetLastQuantityInThePast
GO

CREATE FUNCTION dbo.GetLastQuantityInThePast( @PersonId INT, @VarName VARCHAR(24), @StatusDate DateTime ) RETURNS DECIMAL(18,4)
AS
BEGIN
 DECLARE @RetVal DECIMAL(18,4);
 DECLARE @EventNum INTEGER;
 SET @EventNum = dbo.FnEventTimeToNum( @StatusDate );
 SET @RetVal = ( SELECT TOP 1 co.Quantity FROM ClinObservation co
   JOIN dbo.ClinEvent ce ON ce.EventId=co.EventId
   JOIN dbo.ClinTouch ct ON ct.TouchId=co.TouchId
   JOIN dbo.ClinForm cf ON cf.EventId=ct.EventId AND cf.FormId=ct.FormId AND cf.DeletedAt IS NULL
   WHERE ( ce.PersonId=@PersonId ) AND (ce.EventNum <=@EventNum) AND ( co.VarName=@VarName ) AND ISNULL(co.Quantity,-1)>=0
   ORDER BY ce.EventNum DESC );
 RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetLastQuantityInThePast to [public] AS [dbo]
GO

IF NOT OBJECT_ID('dbo.GetLastEnumValInThePast') IS NULL DROP FUNCTION dbo.GetLastEnumValInThePast
GO

CREATE FUNCTION dbo.GetLastEnumValInThePast( @PersonId INT, @VarName VARCHAR(24), @Cutoff DateTime ) RETURNS INT
AS
BEGIN
 DECLARE @RetVal INT;
 SET @RetVal = ( SELECT TOP 1 co.EnumVal FROM ClinObservation co
   JOIN dbo.ClinEvent ce ON ce.EventId=co.EventId
   JOIN dbo.ClinTouch ct ON ct.TouchId=co.TouchId
   JOIN dbo.ClinForm cf ON cf.EventId=ct.EventId AND cf.FormId=ct.FormId AND cf.DeletedAt IS NULL
   WHERE ( ce.PersonId=@PersonId ) AND ( co.VarName=@VarName ) AND ISNULL(co.EnumVal,-1) >= 0
   AND ( ce.EventTime < @Cutoff )
   ORDER BY ce.EventNum DESC );
   RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetLastEnumValInThePast to [public] AS [dbo]
GO

EXEC DbLogChange 521, 'Feature','New function to retrieve form enum values before specific date in the past (for research)'
GO

IF NOT OBJECT_ID('dbo.GetFirstEvent') IS NULL DROP FUNCTION dbo.GetFirstEvent
GO

CREATE FUNCTION dbo.GetFirstEvent( @PersonId INT, @StudyName VARCHAR(24) ) RETURNS DateTime
AS
BEGIN
  DECLARE @RetVal DateTime;
  select @RetVal = min(ce.EventTime) FROM ClinEvent ce join Study s ON s.StudyId = ce.StudyId
  AND s.StudyName = @StudyName
  WHERE PersonId = @PersonId;
  RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetFirstEvent TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('dbo.GetLastEvent') IS NULL DROP FUNCTION dbo.GetLastEvent
GO

CREATE FUNCTION dbo.GetLastEvent( @PersonId INT, @StudyName VARCHAR(24) ) RETURNS DateTime
AS
BEGIN
  DECLARE @RetVal DateTime;
  select @RetVal = max(ce.EventTime) FROM ClinEvent ce join Study s ON s.StudyId = ce.StudyId
  AND s.StudyName = @StudyName
  WHERE PersonId = @PersonId;
  RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetLastEvent TO [public] AS [dbo]
GO

EXEC DbLogChange 521, 'Feature','New function to retrieve first/last event for person in specific study (for research)'
GO

IF NOT OBJECT_ID('dbo.GetCarePeriodStart') IS NULL DROP FUNCTION dbo.GetCarePeriodStart
GO

CREATE FUNCTION dbo.GetCarePeriodStart( @PersonId INTEGER, @StudyName VARCHAR(24), @SomeDate DateTime ) RETURNS DateTime
AS
BEGIN
  DECLARE @CarePeriodStart DateTime;
  SELECT TOP 1 @CarePeriodStart = scl.ChangedAt
  FROM StudCaseLog scl
  JOIN StudCase sc ON sc.StudCaseId=scl.StudCaseId
  JOIN Study s ON s.StudyId=sc.StudyId AND s.StudyName=@StudyName
  LEFT outer join StudyStatus ss1 ON ss1.StudyId=sc.StudyId and ss1.StatusId=scl.OldStatusId
  LEFT outer join StudyStatus ss2 ON ss2.StudyId=sc.StudyId and ss2.StatusId=scl.NewStatusId
  WHERE PersonId=@PersonId AND
   ( ss1.StatusActive=0 or scl.OldStatusId IS NULL ) AND
   ( ss2.StatusActive=1 or scl.NewStatusId IS NULL ) AND
   scl.ChangedAt < @SomeDate
  ORDER BY ChangedAt DESC;
  RETURN @CarePeriodStart;
END
GO

IF NOT OBJECT_ID('dbo.GetCarePeriodEnd') IS NULL DROP FUNCTION dbo.GetCarePeriodEnd
GO

CREATE FUNCTION dbo.GetCarePeriodEnd( @PersonId INTEGER, @StudyName VARCHAR(24), @SomeDate DateTime ) RETURNS DateTime
AS
BEGIN
  DECLARE @CarePeriodEnd DateTime;
  SELECT TOP 1 @CarePeriodEnd = scl.ChangedAt
  FROM StudCaseLog scl
  JOIN StudCase sc ON sc.StudCaseId=scl.StudCaseId
  JOIN Study s ON s.StudyId=sc.StudyId AND s.StudyName=@StudyName
  LEFT outer join StudyStatus ss1 ON ss1.StudyId=sc.StudyId and ss1.StatusId=scl.OldStatusId
  LEFT outer join StudyStatus ss2 ON ss2.StudyId=sc.StudyId and ss2.StatusId=scl.NewStatusId
  WHERE PersonId=@PersonId AND
   ( ss1.StatusActive=1 or scl.OldStatusId IS NULL ) AND
   ( ss2.StatusActive=0 or scl.NewStatusId IS NULL ) AND
   scl.ChangedAt > @SomeDate
  ORDER BY ChangedAt;
  RETURN @CarePeriodEnd;
END
GO

EXEC DbLogChange 521, 'Feature','New function to retrieve start/end of care period surrounding a given date (for research)'
GO

IF NOT OBJECT_ID('dbo.GetStatusOnDate') IS NULL DROP FUNCTION dbo.GetStatusOnDate
GO

CREATE FUNCTION dbo.GetStatusOnDate( @PersonId INT, @StudyName VARCHAR(24), @Cutoff DateTime ) RETURNS INT
AS
BEGIN
  DECLARE @StudCaseId INT;
  DECLARE @RetVal INT;
  SELECT @StudCaseId = sc.StudCaseId FROM StudCase sc
  JOIN Study s ON s.StudyId=sc.StudyId
  WHERE sc.PersonId=@PersonId AND s.StudName=@StudyName;
  SELECT TOP 1 @RetVal = NewStatusId FROM StudCaseLog WHERE StudCaseId=@StudCaseId AND ChangedAt < @Cutoff
  ORDER BY ChangedAt DESC;
  RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetStatusOnDate TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('dbo.GetGroupOnDate') IS NULL DROP FUNCTION dbo.GetGroupOnDate
GO

CREATE FUNCTION dbo.GetGroupOnDate( @PersonId INT, @StudyName VARCHAR(24), @Cutoff DateTime ) RETURNS INT
AS
BEGIN
  DECLARE @StudCaseId INT;
  DECLARE @RetVal INT;
  SELECT @StudCaseId = sc.StudCaseId FROM StudCase sc
  JOIN Study s ON s.StudyId=sc.StudyId
  WHERE sc.PersonId=@PersonId AND s.StudName=@StudyName;
  SELECT TOP 1 @RetVal = NewGroupId FROM StudCaseLog WHERE StudCaseId=@StudCaseId AND ChangedAt < @Cutoff
  ORDER BY ChangedAt DESC;
  RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetGroupOnDate TO [public] AS [dbo]
GO

EXEC DbLogChange 521, 'Feature','New functions to retrieve Group/Status on a given date (for research)'
GO

ALTER FUNCTION dbo.GetLastLab( @PersonId INT, @VarName VARCHAR(24) ) RETURNS FLOAT
AS
BEGIN
  DECLARE @RetVal FLOAT;
  SET @RetVal = ( SELECT TOP 1 ld.NumResult
    FROM LabData ld JOIN LabCode lc ON ( lc.labCodeId=ld.LabCodeId ) AND ( VarName=@VarName )
    WHERE ( PersonId=@PersonId ) AND ( ISNULL(NumResult,-1) <> -1 )
    ORDER BY ld.LabDate DESC )
 RETURN @RetVal;
END
GO

EXEC DbLogChange 521, 'Tweak','Changed formatting and parenthesis for GetLastLab (no functional change)'
GO


ALTER TABLE dbo.PIA ALTER COLUMN DrugName VARCHAR(128)
GO

EXEC DbLogChange 521, 'Tweak','Increased size of DrugName field in PIA to 128 (FEST data has up to 43)'
GO

ALTER TABLE dbo.PIA ALTER COLUMN DrugForm VARCHAR(64)
GO

EXEC DbLogChange 521, 'Tweak','Increased size of DrugForm field in PIA to 64 (FEST data has up to 57)'
GO

ALTER TABLE dbo.PIA ALTER COLUMN SubstanceName VARCHAR(128)
GO

EXEC DbLogChange 521, 'Tweak','Increased size of SubstanceName field in PIA to 128 (FEST data has up to 113)'
GO

ALTER TABLE dbo.PIA ALTER COLUMN PackName VARCHAR(64)
GO

EXEC DbLogChange 521, 'Tweak','Increased size of PackName field in PIA to 64 (FEST data has up to 54)'
GO

IF dbo.DbColumnExists( 'PIA', 'DrugNameFormStrength') = 0
  ALTER TABLE dbo.PIA ADD DrugNameFormStrength VARCHAR(128)
GO

EXEC DbLogChange 521, 'Feature','Added DrugNameFormStrength to table PIA, preparing for FEST (max size is 105)'
GO

ALTER VIEW dbo.ViewDrugList (ATC, DrugName, DrugForm, Strength, StrengthUnit, SubstanceName,DrugNameFormStrength) 
AS
SELECT
  ATC,DrugName,DrugForm,Strength,StrengthUnit,SubstanceName,DrugNameFormStrength
FROM dbo.PIA
GO

EXEC DbLogChange 521, 'Feature','Added DrugNameFormStrength to view ViewDrugList, preparing for FEST'
GO


IF NOT OBJECT_ID('FEST.GetMatchingDrugs') IS NULL DROP PROCEDURE FEST.GetMatchingDrugs
GO

CREATE PROCEDURE FEST.GetMatchingDrugs( @SearchText VARCHAR(32), @Strength FLOAT = NULL )
AS
BEGIN
  SET @SearchText=@SearchText + '%';   
  IF @Strength = 0 SET @Strength = NULL;
  SELECT ATC,DrugNameFormStrength,DrugName,DrugForm,Strength,StrengthUnit,SubstanceName 
  FROM dbo.PIA 
  WHERE ( ( SubstanceName LIKE @SearchText ) OR ( DrugName LIKE @SearchText ) OR ( ATC LIKE @SearchText) ) 
    AND ( ( @Strength IS NULL ) OR ( @Strength = Strength ) ); 
END
GO

GRANT EXECUTE ON FEST.GetMatchingDrugs TO [public] AS [dbo]
GO

EXEC DbLogChange 521, 'Feature','Added FEST.GetMatchingDrugs preparing for FEST'
GO

IF Dbo.DbColumnExists( 'DrugTreatment','SignedBy' ) = 0 
BEGIN
  ALTER TABLE dbo.DrugTreatment ADD SignedBy INT
  ALTER TABLE dbo.DrugTreatment ADD SignedAt DateTime        
  ALTER TABLE dbo.DrugTreatment ADD CONSTRAINT FK_DrugTreatmentSignedBy_UserList FOREIGN KEY(SignedBy)
    REFERENCES dbo.UserList(UserId)
END
GO

IF NOT OBJECT_ID('CanSignDrugTreatment') IS NULL DROP FUNCTION dbo.CanSignDrugTreatment
GO

CREATE FUNCTION dbo.CanSignDrugTreatment( @UserId INT = NULL ) RETURNS BIT
AS
BEGIN
  DECLARE @RetVal BIT;
  DECLARE @ProfType VARCHAR(3);    
  SET @UserId = ISNULL(@UserId,USER_ID());
  SET @RetVal=0;
  SELECT @ProfType = mp.ProfType FROM UserList ul 
  JOIN dbo.MetaProfession mp ON mp.ProfId=ul.ProfId
  WHERE ul.UserId=@UserId;
  IF @ProfType='LE' 
    SET @RetVal = 1;
  RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.CanSignDrugTreatment TO [public]
GO

UPDATE dbo.DrugTreatment SET SignedBy=CreatedBy,SignedAt=CreatedAt 
  WHERE dbo.CanSignDrugTreatment( CreatedBy )=1 AND SignedBy IS NULL 
GO

IF NOT OBJECT_ID('SignDrugTreatment') IS NULL DROP PROCEDURE dbo.SignDrugTreatment
GO

CREATE PROCEDURE dbo.SignDrugTreatment( @TreatId INT ) AS
BEGIN
  IF dbo.CanSignDrugTreatment( USER_ID() ) = 1  
    UPDATE dbo.DrugTreatment SET SignedBy=USER_ID(),SignedAt=GETDATE() WHERE TreatId=@TreatId AND SignedBy IS NULL
  ELSE
    RAISERROR( 'Du har ikke anledning til å signere medikamenter!', 16, 1 );
END
GO

GRANT EXECUTE ON dbo.SignDrugTreatment TO [public]
GO

ALTER PROCEDURE dbo.GetDrugs( @PersonId INTEGER, @OnGoing INTEGER = 0 )
AS
BEGIN
  SET NOCOUNT ON;
  -- Sign unsigned drugs
  UPDATE dbo.DrugTreatment SET SignedBy=CreatedBy,SignedAt=CreatedAt 
    WHERE PersonId=@PersonId AND dbo.CanSignDrugTreatment( CreatedBy )=1 AND SignedBy IS NULL;
  -- Get dataset  
  IF @OnGoing=1
    SELECT * FROM dbo.DrugTreatment WHERE PersonId=@PersonId AND ( StopAt>getdate() or StopAt IS NULL ) ORDER BY CreatedAt DESC
  ELSE
    SELECT * FROM dbo.DrugTreatment WHERE PersonId=@PersonId ORDER BY CreatedAt DESC
END
GO

EXEC DbLogChange 521, 'Feature','Added support for countersignature of drug orders'
GO

ALTER PROCEDURE dbo.GetDrugForMultidose( @PersonId INT, @ShowDate DateTime = NULL ) AS
BEGIN
  IF @ShowDate IS NULL SET @ShowDate = getdate();
  SELECT
    dt.TreatId,dt.StartAt,dt.DrugName,dbo.GetRxText( dt.TreatId ) as RxText,
    dt.StopAt,
    p2.Signature as StopSign, p1.Signature as StartSign, p3.Signature as CreateSign,
    dt.PackType,mp.PackDesc,
    mp.SortOrder, mtpg.GroupName,
    dt.TreatType,mt.TreatDesc,
      dbo.ConvertDoseHourText(dd.Dose07,7,dd.DoseHour) as Dose07,
      dbo.ConvertDoseHourText(dd.Dose08,8,dd.DoseHour) as Dose08,
      dbo.ConvertDoseHourText(dd.Dose13,13,dd.DoseHour) as Dose13,
      dbo.ConvertDoseHourText(dd.Dose18,18,dd.DoseHour) as Dose18,
      dbo.ConvertDoseHourText(dd.Dose21,21,dd.DoseHour) as Dose21,
      dbo.ConvertDoseHourText(dd.Dose23,23,dd.DoseHour) as Dose23,
    dt.DrugForm,
    dbo.GetDose24hText( dt.TreatId) as Dose24hText,
    dt.Strength,dt.StrengthUnit,dt.Dose24hDD,
    CONVERT(FLOAT,ISNULL(StopAt,@ShowDate+1) - @ShowDate) as DaysLeft, dt.PauseStatus
  FROM dbo.DrugTreatment dt
    JOIN dbo.MetaPackType mp on mp.PackType = dt.PackType
    JOIN dbo.MetaTreatType mt on mt.TreatType = dt.TreatType
    LEFT OUTER JOIN dbo.DrugDosing dd on dd.DoseId=dt.DoseId
    LEFT OUTER JOIN dbo.UserList u1 on u1.UserId=dt.SignedBy
    LEFT OUTER JOIN dbo.Person p1 on p1.PersonId=u1.PersonId
    LEFT OUTER JOIN dbo.UserList u2 on u2.UserId=dt.StopBy
    LEFT OUTER JOIN dbo.Person p2 on p2.PersonId=u2.PersonId
    LEFT OUTER JOIN dbo.UserList u3 on u3.UserId=dt.CreatedBy
    LEFT OUTER JOIN dbo.Person p3 on p3.PersonId=u3.PersonId
    LEFT OUTER JOIN dbo.MetaTreatPackGroup mtpg on dt.TreatType=mtpg.TreatType and dt.PackType=mtpg.PackType
  WHERE dt.PersonId=@PersonId
    AND (( dt.StopAt IS NULL ) OR ( @ShowDate < dt.StopAt ))
    AND ( dt.CreatedAt <= @ShowDate )
  ORDER BY mtpg.SortOrder,dt.StartAt
END;
GO

EXEC DbLogChange 521, 'Tweak','Changed GetDrugForMultidose to use SignedBy field instead of CreatedBy for signature'
GO

GRANT EXECUTE ON dbo.SignDrugTreatment TO [public]
GO

REVOKE SELECT,UPDATE ON dbo.DrugTreatment TO [public]
GO

GRANT SELECT ON dbo.StudyGroup to [public]
GO

GRANT SELECT ON dbo.StudyStatus to [public]
GO

EXECUTE DbFinalizeUpgrade 521;
GO

COMMIT TRANSACTION UpgradeTo521;
GO

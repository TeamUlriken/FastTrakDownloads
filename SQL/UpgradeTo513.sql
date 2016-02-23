SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo513;
PRINT 'Starting upgrade to 513'
GO

DELETE FROM DbUpgradeLog WHERE DbVer > 512;
EXEC DbCheckVersion 512;       
EXECUTE DbStartUpgrade 513;
GO

ALTER PROCEDURE GBD.AntibioticReport( @StartAt DateTime, @StopAt DateTime )
AS
BEGIN
  SET LANGUAGE Norwegian;
  SELECT 
    p.PersonId,p.GroupName,DATEPART(month,StartAt) as MonthNo,
    dbo.MonthYear(StartAt) as MonthName,StartAt,StopAt,
    dt.StartReason,dt.StopReason,dt.ATC,dt.DrugName,dt.DrugForm,dt.Dose24hDD,up.FullName 
  FROM DrugTreatment dt
    JOIN ViewActiveCaseListStub p ON p.PersonId=dt.PersonId
    JOIN Study s ON s.StudyId=p.StudyId AND s.StudyName='GBD'
    JOIN UserList ul ON ul.UserId=dt.CreatedBy
    JOIN UserList my ON my.UserId=USER_ID()
    JOIN Person up ON up.PersonId=ul.PersonId
  WHERE dt.ATC LIKE 'J01%' AND ATC<>'J01XX05'
    AND dt.StartAt >= @StartAt AND dt.StartAt < @StopAt 
    AND ABS(DATEDIFF(day,dt.StopAt,dt.StartAt )) > 1 
  ORDER BY MonthNo,MonthName,dt.StartAt
END
GO

IF NOT object_id('Report.LabClassOverview') IS NULL DROP VIEW Report.LabClassOverview
GO

CREATE VIEW Report.LabClassOverview AS
  SELECT ISNULL(lc.FriendlyName,'Uklassifiserte prøver') as FriendlyName,lc.FurstId,lc.LoincCode, count(*) as LabCount                                           
  FROM LabCode lc JOIN LabData ld ON ld.LabCodeId=lc.LabCodeId
  GROUP BY lc.FriendlyName,lc.FurstId,lc.LoincCode
GO

GRANT SELECT ON Report.LabClassOverview TO [public]
GO


IF NOT OBJECT_ID('dbo.GetDrugPauseStatus') IS NULL DROP FUNCTION dbo.GetDrugPauseStatus 
GO

CREATE FUNCTION dbo.GetDrugPauseStatus( @TreatId INT, @PauseDate DateTime ) RETURNS INT
AS
BEGIN
  DECLARE @PauseStatus INT;
  SELECT @PauseStatus = COUNT(PauseId) FROM DrugPause 
  WHERE ( TreatId=@TreatId )
  AND ( PausedAt <= @PauseDate ) AND ( ISNULL(RestartAt,@PauseDate ) >= @PauseDate );
  IF @PauseStatus > 1 SET @PauseStatus = 1;
  RETURN @PauseStatus;
END
GO

GRANT EXECUTE ON dbo.GetDrugPauseStatus TO [public]
GO

IF NOT OBJECT_ID('dbo.GetDrugForMultidoseHistoric') IS NULL DROP PROCEDURE GetDrugForMultidoseHistoric
GO

CREATE PROCEDURE dbo.GetDrugForMultidoseHistoric( @PersonId INT, @ShowDate DateTime = NULL ) AS
BEGIN
  SET NOCOUNT ON;
  IF @ShowDate IS NULL SET @ShowDate = getdate();
  SELECT
    dt.TreatId,dt.StartAt,dt.DrugName,dbo.GetRxText( dt.TreatId ) as RxText,
    dt.StopAt,p2.Signature as StopSign,p1.Signature as StartSign,dt.PackType,mp.PackDesc,
    mp.SortOrder, mtpg.GroupName,
    dt.TreatType,mt.TreatDesc,
      dbo.ConvertDoseText(dd.Dose07) as Dose07,
      dbo.ConvertDoseText(dd.Dose08) as Dose08,
      dbo.ConvertDoseText(dd.Dose13) as Dose13,
      dbo.ConvertDoseText(dd.Dose18) as Dose18,
      dbo.ConvertDoseText(dd.Dose21) as Dose21,
      dbo.ConvertDoseText(dd.Dose23) as Dose23,
    dt.DrugForm,
    dbo.GetDose24hText( dt.TreatId) as Dose24hText,
    dt.Strength,dt.StrengthUnit,dt.Dose24hDD,
    CONVERT(FLOAT,ISNULL(StopAt,@ShowDate+1) - @ShowDate) as DaysLeft, 
    dbo.GetDrugPauseStatus( dt.TreatId,@ShowDate) as PauseStatus
  FROM DrugTreatment dt
    JOIN MetaPackType mp on mp.PackType = dt.PackType
    JOIN MetaTreatType mt on mt.TreatType = dt.TreatType
    LEFT OUTER JOIN dbo.DrugDosing dd on dd.DoseId=dt.DoseId
    LEFT OUTER JOIN dbo.UserList u1 on u1.UserId=dt.CreatedBy
    LEFT OUTER JOIN dbo.Person p1 on p1.PersonId=u1.PersonId
    LEFT OUTER JOIN dbo.UserList u2 on u2.UserId=dt.StopBy
    LEFT OUTER JOIN dbo.Person p2 on p2.PersonId=u2.PersonId
    LEFT OUTER JOIN dbo.MetaTreatPackGroup mtpg on dt.TreatType=mtpg.TreatType and dt.PackType=mtpg.PackType
  WHERE dt.PersonId=@PersonId
    AND (( dt.StopAt IS NULL ) OR ( @ShowDate < dt.StopAt ))
    AND ( dt.CreatedAt <= @ShowDate )
  ORDER BY mtpg.SortOrder,dt.StartAt
END;
GO

GRANT EXECUTE ON dbo.GetDrugForMultidoseHistoric TO [public]
GO

ALTER PROCEDURE dbo.GetDrugRecentChange( @PersonId INT , @DaysAgo INT = 14, @ShowDate DateTime = NULL )
AS 
BEGIN
  SET NOCOUNT ON;
  IF @ShowDate IS NULL SET @ShowDate = getdate();
  SELECT
    dt.TreatId,dt.StartAt,p1.Signature as StartSign,
    dt.DrugName,dt.DrugForm,dt.Strength,dt.StrengthUnit,dt.StopReason,
    dt.StopAt,p2.Signature as StopSign,
    CONVERT(FLOAT,@ShowDate-dt.StopAt) as DaysAgo
  FROM DrugTreatment dt
    LEFT OUTER JOIN dbo.UserList u1 on u1.UserId=dt.CreatedBy
    LEFT OUTER JOIN dbo.Person p1 on p1.PersonId=u1.PersonId
    LEFT OUTER JOIN dbo.UserList u2 on u2.UserId=dt.StopBy
    LEFT OUTER JOIN dbo.Person p2 on p2.PersonId=u2.PersonId
  WHERE (dt.PersonId=@PersonId) AND (NOT dt.StopAt IS NULL)
   AND (@ShowDate > dt.StopAt ) 
   AND (@ShowDate < dt.StopAt + @DaysAgo)
   AND ( dt.CreatedAt <= @ShowDate )
  ORDER BY dt.StopAt DESC
END
GO

EXECUTE DbFinalizeUpgrade 513;
GO

COMMIT TRANSACTION UpgradeTo513;
GO
  


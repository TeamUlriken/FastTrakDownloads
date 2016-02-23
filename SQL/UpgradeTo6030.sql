BEGIN TRANSACTION UpgradeTo6030
PRINT 'Starting upgrade to 6030'

DELETE FROM DbUpgradeLog WHERE DbVer > 6029;

EXEC DbCheckVersion 6029;
EXECUTE DbStartUpgrade 6030;
GO

ALTER PROCEDURE dbo.GetLabReqTestPending( @PersonId INT ) AS
BEGIN
  SELECT lrt.LabCodeId, lc.LabName FROM dbo.LabReq lr
  JOIN dbo.LabReqTest lrt on lrt.LabReqId=lr.LabReqId
  JOIN dbo.LabCode lc ON lc.LabCodeId=lrt.LabCodeId
  WHERE lrt.LabDataId IS NULL AND lr.PersonId=@PersonId
END
GO

ALTER PROCEDURE dbo.DeleteDrugTemplate( @FriendlyName varchar(64) )
AS
BEGIN
  DELETE FROM dbo.DrugTemplate WHERE FriendlyName=@FriendlyName
END
GO

ALTER PROCEDURE dbo.AddAlertReminder( @AlertLevel INT,
 @AlertHeader varchar(64), @AlertMessage varchar(512), @UserId INT = NULL ) 
AS
BEGIN
  IF @UserId IS NULL SET @UserId=USER_ID();
  INSERT INTO dbo.Alert (PersonId,UserId,AlertLevel,AlertClass,AlertFacet, AlertHeader,AlertMessage,AlertButtons)
    VALUES (0,@UserId,@AlertLevel,'REMINDER','Undefined',@AlertHeader,@AlertMessage,'TWMHYF')
END
GO

IF NOT OBJECT_ID('GetDrugTextSuggestions') IS NULL 
  DROP PROCEDURE dbo.GetDrugTextSuggestions
GO

CREATE PROCEDURE dbo.GetDrugTextSuggestions( @TreatId INT, @LookBack INT = 3650, @MinCount INT = 2 ) AS
BEGIN
  SELECT ROW_NUMBER() OVER ( ORDER BY COUNT(*) DESC ),LTRIM(SUBSTRING(dtold.RxText,1,1024)),NULL, COUNT(*)
  FROM dbo.DrugTreatment dt JOIN dbo.DrugTreatment dtold 
  ON dtold.ATC=dt.ATC AND dtold.TreatPackType=dt.TreatPackType AND dtold.DoseCode=dt.DoseCode
    AND ISNULL(dtold.Dose24hCount,0) = ISNULL(dt.Dose24hCount,0)
    AND ISNULL(dtold.Strength,0) = ISNULL(dt.Strength,0)
    AND dtold.DrugForm = dt.DrugForm
    AND dtold.CreatedAt > GETDATE()- @LookBack
    AND SUBSTRING(dtold.RxText,1,1024) <> SUBSTRING(dt.RxText,1,1024)
    AND DATALENGTH( dtold.RxText ) > 5
    AND dt.TreatId=@TreatId
  GROUP BY LTRIM(SUBSTRING(dtold.RxText,1,1024))
  HAVING COUNT(*) >= @MinCount
  ORDER BY COUNT(*) DESC
END
GO

GRANT EXECUTE ON dbo.GetDrugTextSuggestions TO [public] AS [dbo]
GO

ALTER PROCEDURE dbo.GetRxTextSuggestions( @TreatId INT, @LookBack INT = 3650, @MinCount INT = 0 ) AS
BEGIN
  SELECT ROW_NUMBER() OVER ( ORDER BY COUNT(*) DESC ),LTRIM(SUBSTRING(pre.RxText,1,1024)), NULL,COUNT(*)
  FROM DrugTreatment dt JOIN DrugTreatment dtold 
  ON dtold.ATC=dt.ATC AND dtold.TreatPackType=dt.TreatPackType AND dtold.DoseCode=dt.DoseCode
    AND ISNULL(dtold.Dose24hCount,0) = ISNULL(dt.Dose24hCount,0)
    AND ISNULL(dtold.Strength,0) = ISNULL(dt.Strength,0)
    AND dtold.DrugForm = dt.DrugForm
  JOIN DrugPrescription pre ON pre.TreatId=dtold.TreatId  
  WHERE dtold.CreatedAt > GETDATE()- @LookBack
    AND DATALENGTH( pre.RxText ) > 5
    AND dt.TreatId=@TreatId
  GROUP BY LTRIM(SUBSTRING(pre.RxText,1,1024))
  HAVING COUNT(*) >= @MinCount
  ORDER BY COUNT(*) DESC
END
GO

ALTER FUNCTION dbo.GetStudyId( @SessId INT ) RETURNS INT
AS
BEGIN
  DECLARE @StudyId INT;
  SELECT @StudyId = StudyId FROM dbo.UserLog WHERE SessId=@SessId AND ClosedAt IS NULL AND UserId=USER_ID();
  RETURN (@StudyId);
END
GO

ALTER PROCEDURE dbo.AddLabCodeToGroup( @LabCodeId INT, @LabGroupId INT)
AS
BEGIN
  IF EXISTS( SELECT LabCodeId FROM dbo.LabCodeGroup WHERE LabGroupId=@LabGroupId AND LabCodeId=@LabCodeID)
     RETURN -1
  ELSE
    INSERT INTO dbo.LabCodeGroup (LabGroupId,LabCodeId) VALUES(@LabGroupId,@LabCodeId)
END
GO

IF NOT OBJECT_ID('RemoveProc') IS NULL
  DROP PROCEDURE dbo.RemoveProc
GO

CREATE PROCEDURE dbo.RemoveProc( @ProcName VARCHAR(128) ) AS
BEGIN
  EXECUTE( 'DELETE FROM dbo.DbProcList WHERE ProcName=''' + @ProcName + '''' );
  IF NOT OBJECT_ID( @ProcName ) IS NULL EXECUTE( 'DROP PROCEDURE '+ @ProcName );
END
GO

IF NOT OBJECT_ID('RunAtMidnight') IS NULL
  DROP PROCEDURE dbo.RunAtMidnight
GO

CREATE PROCEDURE dbo.RunAtMidnight
AS
BEGIN
  PRINT 'Put maintenance routines here.'
END
GO

ALTER PROCEDURE dbo.GetDrugsDispGIG( @PersonId INTEGER, @OnGoing INTEGER )
AS
BEGIN
  SELECT
    TreatId,StartAt,ATC,DrugName,TreatType,PackType,Strength,StrengthUnit,
    DoseCode,StartReason,StopAt,StopReason,PauseStatus
  FROM dbo.DrugTreatment 
  WHERE PersonId=@PersonId AND ( @OnGoing<>1 OR StopAt>getdate() OR StopAt IS NULL )
  ORDER BY CreatedAt DESC
END
GO

COMMIT TRANSACTION UpgradeTo6030;
GO

EXECUTE dbo.DbFinalizeUpgrade 6030;
GO

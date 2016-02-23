BEGIN TRANSACTION UpgradeTo6020
PRINT 'Starting upgrade to 6020'

DELETE FROM DbUpgradeLog WHERE DbVer > 6019;

EXEC DbCheckVersion 6019;
EXECUTE DbStartUpgrade 6020;
GO

IF NOT OBJECT_ID('UpdateLabTestGroup') IS NULL
  DROP PROCEDURE dbo.UpdateLabTestGroup
GO

CREATE PROCEDURE dbo.UpdateLabTestGroup( @LabCodeId INT, @AddToGroupId INT, @RemoveFromGroupId INT ) AS
BEGIN
  -- Delete from existing group
  DELETE FROM dbo.LabCodeGroup WHERE LabGroupId=@RemoveFromGroupId AND LabCodeId=@LabCodeId;
  -- Add to new group
  IF ( ISNULL( @AddToGroupId, 0 ) > 0 ) AND NOT 
  EXISTS( SELECT LabCodeId FROM dbo.LabCodeGroup WHERE LabCodeId=@LabCodeId AND LabGroupId=@AddToGroupId )
    INSERT INTO dbo.LabCodeGroup (LabGroupId,LabCodeId) VALUES( @AddToGroupId, @LabCodeId );
END
GO

GRANT EXECUTE ON dbo.UpdateLabTestGroup TO [superuser] AS [dbo]
GO

ALTER PROCEDURE dbo.UpdateLabCodeGroup( @LabName VARCHAR(40), @AddToGroupId INT, @RemoveFromGroupId INT ) AS
BEGIN
  DECLARE @LabCodeId INT;
  SELECT @LabCodeId=LabCodeId FROM dbo.LabCode WHERE LabName = @LabName;
  IF @LabCodeId IS NULL 
  BEGIN
    INSERT INTO dbo.LabCode (LabName) VALUES( @LabName );
    SET @LabCodeId=SCOPE_IDENTITY();
  END
  ELSE
    DELETE FROM dbo.LabCodeGroup WHERE LabGroupId=@RemoveFromGroupId AND LabCodeId=@LabCodeId;
  IF ISNULL( @AddToGroupId, 0 ) > 0
    INSERT INTO dbo.LabCodeGroup (LabGroupId,LabCodeId) VALUES( @AddToGroupId, @LabCodeId );
END
GO

ALTER PROCEDURE dbo.GetStudyAnswers( @StudyId INT ) AS
BEGIN
  SELECT mia.ItemId,mia.OrderNumber,mia.AnswerId,mia.OptionText, 
     mia.VerboseText,mia.ICD10, mia.Score, mia.ShortCode,mia.LastUpdate 
    FROM dbo.MetaItemAnswer mia
  WHERE ItemId IN 
   ( 
     SELECT DISTINCT ItemId FROM dbo.MetaFormItem mfi
     JOIN dbo.MetaStudyForm ms ON ms.FormId=mfi.FormId
     WHERE ms.StudyId=@StudyId
   )                                   
   ORDER BY mia.ItemId,mia.OrderNumber
END
GO

IF NOT OBJECT_ID('[Report].[GetPercentileRanksById]') IS NULL
   DROP PROCEDURE Report.GetPercentileRanksById
GO

CREATE PROCEDURE Report.GetPercentileRanksById(@LabCodeId INT )
AS
BEGIN
  WITH LabRankCount
  AS (SELECT ResultId, NumResult, rank() OVER (ORDER BY NumResult) AS RankOrder, count(*) OVER () AS TotalCount
      FROM dbo.LabData
      WHERE (LabCodeId = @LabCodeId)
        AND (NumResult > 0)
  )
  SELECT DISTINCT NumResult, 1. * (RankOrder - 1) / (TotalCount - 1) * 100 AS percentilerank
  FROM LabRankCount
  ORDER BY NumResult
END
GO

GRANT EXECUTE ON [Report].[GetPercentileRanksById] TO [public] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6020;
GO

COMMIT TRANSACTION UpgradeTo6020;
GO


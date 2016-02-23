SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6015
PRINT 'Starting upgrade to 6015'

DELETE FROM DbUpgradeLog WHERE DbVer > 6014;

EXEC DbCheckVersion 6014;
EXECUTE DbStartUpgrade 6015;
GO

-- Percentile ranks also present in QuickStatA upgrade

IF NOT object_id('Report.GetPercentileRanks') IS NULL
  DROP PROCEDURE Report.GetPercentileRanks
GO

CREATE PROCEDURE Report.GetPercentileRanks(@LabVarName VARCHAR(24))
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


GRANT EXECUTE ON Report.GetPercentileRanks to [public] AS [dbo]
GO

EXECUTE DbFinalizeUpgrade 6015;
GO

COMMIT TRANSACTION UpgradeTo6015;
GO


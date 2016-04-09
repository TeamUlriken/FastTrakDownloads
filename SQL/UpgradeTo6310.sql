SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6310
GO

PRINT 'Overall purpose: Add report for consent status NDV.'

--  CREATE function GetLastEnumValuesTable, useful for many reports.
--  CREATE table Report.TimePeriods, for a list of periods we can join to.
--  CREATE function NDV.GetConsentStatusTable.
--  CREATE function NDV.GetConsentSummaryTable.
--  CREATE procedure NDV.ReportConsentStatus for report Samtykkeinnhentinger.fr3
--  ALTER view Report.LabTestOverview to include NLK and Loinc fields.
--  ALTER view Report.LabClassOverview to include NLK field.
--  ALTER procedure CRF.GetFormItems to include FormItemId field.
--  ALTER procedure CRF.GetMetaForms to use tables directly and use HideComment field.
--  DROP view Meta.StudyForm and the Meta schema, where the view was the only object.

EXECUTE dbo.DbStartUpgrade 6309, 6310;
GO

PRINT '--  CREATE function GetLastEnumValuesTable, useful for many reports.'


IF NOT OBJECT_ID('dbo.GetLastEnumValuesTable') IS NULL
  DROP FUNCTION dbo.GetLastEnumValuesTable
GO

CREATE FUNCTION dbo.GetLastEnumValuesTable ( @ItemId INT, @EndTime DATETIME = NULL )
RETURNS @LastEnumVals TABLE (
  PersonId INT NOT NULL,
  EnumVal INT NOT NULL,
  ShortCode VARCHAR(5),
  OptionText VARCHAR(MAX)
) AS
BEGIN
  SELECT @EndTime = ISNULL(@EndTime, GETDATE() + 1);
  INSERT @LastEnumVals
    SELECT a.PersonId, a.EnumVal, ISNULL(mia.ShortCode, 'n/a') AS ShortCode, ISNULL(mia.OptionText, 'Ubesvart') AS OptionText
    FROM (SELECT ce.PersonId, cdp.EnumVal, RANK()
        OVER (
        PARTITION BY ce.PersonId
        ORDER BY ce.EventTime DESC) AS OrderNo
      FROM dbo.ClinEvent ce
      JOIN dbo.ClinDataPoint cdp
        ON cdp.EventId = ce.EventId AND ce.EventTime < @EndTime
      WHERE cdp.ItemId = @ItemId
      AND ISNULL(cdp.EnumVal, -1) >= 0) a
    LEFT JOIN dbo.MetaItemAnswer mia ON mia.ItemId = @ItemId AND mia.OrderNumber = a.EnumVal
    WHERE a.OrderNo = 1;
  RETURN;
END
GO

PRINT '--  CREATE table Report.TimePeriods, for a list of periods we can join to.'

-- Lag en tabell for måneder, brukes til rapportering
SET NOCOUNT ON;

IF NOT OBJECT_ID('Report.TimePeriods') IS NULL
  DROP TABLE Report.TimePeriods
GO

CREATE TABLE Report.TimePeriods (
  RowId INT IDENTITY (1, 1) NOT NULL,
  StartTime DATETIME NOT NULL,
  EndTime DATETIME NOT NULL,
  PeriodType CHAR(8) NOT NULL,
  CONSTRAINT PK_Report_TimePeriods PRIMARY KEY (RowId)
)
GO

CREATE UNIQUE INDEX IDX_Report_TimePeriods_StartTime_EndTime ON Report.TimePeriods (StartTime, EndTime)
GO

ALTER TABLE Report.TimePeriods ADD StartYear AS DATEPART(YYYY, StartTime)
GO

TRUNCATE TABLE Report.TimePeriods
GO

DECLARE @StartDate DATETIME
DECLARE @EndDate DATETIME
SET @StartDate = CAST('1900-01-01' AS DATETIME)
WHILE @StartDate < '2100-01-01'
BEGIN
  SET @EndDate = DATEADD(MILLISECOND, -100, DATEADD(MM, 1, @StartDate))
  INSERT INTO Report.TimePeriods (StartTime, EndTime, PeriodType)
    VALUES (@StartDate, @EndDate, 'MONTH')
  SET @StartDate = DATEADD(MM, 1, @StartDate);
END

SET @StartDate = CAST('1900-01-01' AS DATETIME)
WHILE @StartDate < '2100-01-01'
BEGIN
  SET @EndDate = DATEADD(MILLISECOND, -100, DATEADD(YEAR, 1, @StartDate))
  INSERT INTO Report.TimePeriods (StartTime, EndTime, PeriodType)
    VALUES (@StartDate, @EndDate, 'YEAR')
  SET @StartDate = DATEADD(YEAR, 1, @StartDate);
END

SET @StartDate = CAST('1900-01-01' AS DATETIME)
WHILE @StartDate < '2100-01-01'
BEGIN
  SET @EndDate = DATEADD(MILLISECOND, -100, DATEADD(MM, 3, @StartDate))
  INSERT INTO Report.TimePeriods (StartTime, EndTime, PeriodType)
    VALUES (@StartDate, @EndDate, 'QUARTER')
  SET @StartDate = DATEADD(MM, 3, @StartDate);
END

SET @StartDate = CAST('1900-01-01' AS DATETIME)
WHILE @StartDate < '2100-01-01'
BEGIN
  SET @EndDate = DATEADD(MILLISECOND, -100, DATEADD(MM, 4, @StartDate))
  INSERT INTO Report.TimePeriods (StartTime, EndTime, PeriodType)
    VALUES (@StartDate, @EndDate, 'TERTIAL')
  SET @StartDate = DATEADD(MM, 4, @StartDate);
END
GO

PRINT '--  CREATE function NDV.GetConsentStatusTable.'

-- Hent ut samtykkestatus for en person i en gitt periode.

IF NOT OBJECT_ID('NDV.GetConsentStatus') IS NULL
  DROP FUNCTION NDV.GetConsentStatus
GO

IF NOT OBJECT_ID('NDV.GetConsentStatusTable') IS NULL
  DROP FUNCTION NDV.GetConsentStatusTable
GO

CREATE FUNCTION NDV.GetConsentStatusTable ( @StartTime DATETIME, @EndTime DATETIME )
RETURNS @ConsentStatus TABLE (
  PersonId INT NOT NULL,
  EnumVal INT NOT NULL,
  ShortCode VARCHAR(8) NOT NULL
) AS
BEGIN
  INSERT @ConsentStatus
    SELECT PersonVisits.PersonId, ISNULL(st.EnumVal, -1) AS EnumVal, ISNULL(st.ShortCode, '?') AS ShortCode
    FROM (SELECT ce.PersonId, cdp.EnumVal, COUNT(*) AS n
      FROM dbo.ClinEvent ce
      JOIN dbo.ClinDataPoint cdp
        ON cdp.EventId = ce.EventId
      WHERE cdp.ItemId = 3196
      AND ce.EventTime >= @StartTime
      AND ce.EventTime < @EndTime
      GROUP BY ce.PersonId,
               cdp.EnumVal) PersonVisits
    LEFT JOIN dbo.GetLastEnumValuesTable(3389, @EndTime) st ON st.PersonId = PersonVisits.PersonId;
  RETURN
END
GO

PRINT '--  CREATE function NDV.GetConsentSummaryTable.'

-- Lag en oppsummering av samtykkene i periode

IF NOT OBJECT_ID('NDV.GetConsentSummary') IS NULL
  DROP FUNCTION NDV.GetConsentSummary
GO

IF NOT OBJECT_ID('NDV.GetConsentSummaryTable') IS NULL
  DROP FUNCTION NDV.GetConsentSummaryTable
GO

CREATE FUNCTION NDV.GetConsentSummaryTable ( @StartTime DATETIME, @EndAt DATETIME )
RETURNS @ConsentSummary TABLE (
  StartTime DATETIME NOT NULL,
  EndAt DATETIME NOT NULL,
  ShortCode VARCHAR(3) NOT NULL,
  Antall INT
) AS
BEGIN
  INSERT @ConsentSummary
    SELECT @StartTime, @EndAt, ShortCode, COUNT(*) Ant
    FROM NDV.GetConsentStatusTable(@StartTime, @EndAt)
    GROUP BY ShortCode;
  RETURN;
END
GO

PRINT '--  CREATE procedure NDV.ReportConsentStatus for report Samtykkeinnhentinger.fr3'

IF NOT OBJECT_ID('NDV.ReportConsentStatus') IS NULL
  DROP PROCEDURE NDV.ReportConsentStatus
GO

CREATE PROCEDURE NDV.ReportConsentStatus ( @StartTime DATETIME = NULL, @EndTime DATETIME = NULL, @PeriodType CHAR(8) = 'MONTH' ) AS
BEGIN
  SET NOCOUNT ON;
  SELECT @StartTime = ISNULL(@StartTime, DATEADD(YEAR, -2, GETDATE()));
  SELECT @EndTime = ISNULL(@EndTime, GETDATE());
  CREATE TABLE #ResData (
    StartTime DATETIME NOT NULL PRIMARY KEY,
    EndTime DATETIME NOT NULL,
    Ja INT NULL,
    Nei INT NULL,
    Trukket INT,
    Ukjent INT,
    Ubesvart INT NULL
  );
  ALTER TABLE #ResData ADD Totalt AS (ISNULL(Ubesvart, 0) + ISNULL(Ja, 0) + ISNULL(Nei, 0) + ISNULL(Trukket, 0) + ISNULL(Ukjent, 0));
  ALTER TABLE #ResData ADD JaProsent AS 100.0 * Ja / (ISNULL(Ubesvart, 0) + ISNULL(Ja, 0) + ISNULL(Nei, 0) + ISNULL(Trukket, 0) + ISNULL(Ukjent, 0));
  ALTER TABLE #ResData ADD NeiProsent AS 100.0 * Nei / (ISNULL(Ubesvart, 0) + ISNULL(Ja, 0) + ISNULL(Nei, 0) + ISNULL(Trukket, 0) + ISNULL(Ukjent, 0));
  ALTER TABLE #ResData ADD TrukketProsent AS 100.0 * Trukket / (ISNULL(Ubesvart, 0) + ISNULL(Ja, 0) + ISNULL(Nei, 0) + ISNULL(Trukket, 0) + ISNULL(Ukjent, 0));
  ALTER TABLE #ResData ADD UkjentProsent AS 100.0 * Ukjent / (ISNULL(Ubesvart, 0) + ISNULL(Ja, 0) + ISNULL(Nei, 0) + ISNULL(Trukket, 0) + ISNULL(Ukjent, 0));
  ALTER TABLE #ResData ADD UbesvartProsent AS 100.0 * Ubesvart / (ISNULL(Ubesvart, 0) + ISNULL(Ja, 0) + ISNULL(Nei, 0) + ISNULL(Trukket, 0) + ISNULL(Ukjent, 0));
  INSERT INTO #ResData (StartTime, EndTime, Ubesvart, Ja, Nei, Trukket, Ukjent)
    SELECT ml.StartTime, ml.EndTime, (SELECT Antall
        FROM NDV.GetConsentSummaryTable(ml.StartTime, ml.EndTime)
        WHERE ShortCode = '?')
      AS Ubesvart, (SELECT Antall
        FROM NDV.GetConsentSummaryTable(ml.StartTime, ml.EndTime)
        WHERE ShortCode = 'J')
      AS Ja, (SELECT Antall
        FROM NDV.GetConsentSummaryTable(ml.StartTime, ml.EndTime)
        WHERE ShortCode = 'N')
      AS Nei, (SELECT Antall
        FROM NDV.GetConsentSummaryTable(ml.StartTime, ml.EndTime)
        WHERE ShortCode = 'T')
      AS Trukket, (SELECT Antall
        FROM NDV.GetConsentSummaryTable(ml.StartTime, ml.EndTime)
        WHERE ShortCode = 'U')
      AS Ukjent
    FROM Report.TimePeriods ml
    WHERE (ml.StartTime >= @StartTime) AND (ml.StartTime < @EndTime AND ml.PeriodType = @PeriodType)
  SELECT *
  FROM #ResData
  ORDER BY StartTime DESC;
END
GO

PRINT '--  ALTER view Report.LabTestOverview to include NLK and Loinc fields.'
GO

ALTER VIEW Report.LabTestOverview AS
  SELECT LabStats.LabCodeId, lc.LabClassId, lc.LabName, cl.FriendlyName, cl.FurstId, cl.VarName, cl.NLK, cl.Loinc,
    LabStats.LabCount, LabStats.MinResult, LabStats.MaxResult, LabStats.AvgResult
  FROM (SELECT ld.LabCodeId,
      COUNT(*) AS LabCount, MIN(ld.NumResult) AS MinResult,
      MAX(ld.NumResult) AS MaxResult, AVG(ld.NumResult) AS AvgResult
    FROM dbo.LabData ld
    WHERE ld.NumResult >= 0
    GROUP BY ld.LabCodeId) LabStats
  JOIN LabCode lc ON lc.LabCodeId = LabStats.LabCodeId
  LEFT JOIN dbo.LabClass cl ON cl.LabClassId = lc.LabClassId
GO


PRINT '--  ALTER view Report.LabClassOverview to include NLK field.'
GO

ALTER VIEW Report.LabClassOverview AS
  SELECT cl.LabClassId, ISNULL(cl.FriendlyName, 'Uklassifiserte prøver') AS FriendlyName,
    cl.FurstId, cl.VarName, cl.NLK, cl.Loinc, LabStats.LabCount
  FROM (SELECT lc.LabClassId, COUNT(*) AS LabCount
    FROM dbo.LabCode lc
    JOIN dbo.LabData ld
      ON ld.LabCodeId = lc.LabCodeId
    GROUP BY lc.LabClassId) LabStats
  LEFT JOIN dbo.LabClass cl ON cl.LabClassId = LabStats.LabClassId
GO

PRINT '--  ALTER procedure CRF.GetFormItems to include FormItemId field.'
GO

ALTER PROCEDURE CRF.GetFormItems ( @FormId INT ) AS
BEGIN
  SELECT mfi.FormItemId, mfi.FormId, mfi.OrderNumber, mi.ItemId, mi.VarName, mi.LabName, mi.ItemType, mi.UnitStr,
    mi.MinNormal, mi.MaxNormal, mi.ThreadTypeId, mi.Multiline,
    mfi.ExcludeFromText, mfi.ExcludeCaption, mfi.ItemHeader, mfi.ItemText,
    mfi.ItemHelp, mfi.Optional, mfi.ReadOnly, mfi.CarryForward,
    mfi.MinExpression, mfi.MaxExpression, mfi.Decimals, mfi.Expression, mfi.FormatStr, mfi.Highlight,
    DefaultValue, ISNULL(Visibility, 1) AS Visibility, mfi.PageNumber, mfi.LastUpdate
  FROM dbo.MetaFormItem mfi
  JOIN dbo.MetaItem mi ON mi.ItemId = mfi.ItemId
  LEFT OUTER JOIN dbo.MetaFormPage mfp ON mfp.PageId = mfi.PageId
  WHERE mfi.FormId = @FormId
  ORDER BY mfi.PageNumber, mfi.OrderNumber
END
GO


PRINT '--  ALTER procedure CRF.GetMetaForms to use tables directly and use HideComment field.'
GO

IF NOT OBJECT_ID( 'dbo.GetMetaForms','P') IS NULL
  DROP PROCEDURE dbo.GetMetaForms
GO

IF NOT OBJECT_ID( 'dbo.GetMetaForms','SN') IS NULL
  DROP SYNONYM dbo.GetMetaForms
GO

IF NOT OBJECT_ID( 'CRF.GetMetaForms','P') IS NULL
  DROP PROCEDURE CRF.GetMetaForms
GO

CREATE PROCEDURE CRF.GetMetaForms( @StudyId INT ) AS
BEGIN
  SELECT msf.StudyId, mf.FormId, mf.FormName, mf.FormTitle, mf.Subtitle,
    mf.CalculateInvalid, mf.RatingScale, mf.Copyright, msf.HideComment,
    mf.ThreadTypeId, mf.Instructions,
    ISNULL(msf.Repeatable, mf.Repeatable) AS Repeatable,
    ISNULL(msf.SurveyStatus, mf.SurveyStatus) AS SurveyStatus,
    ISNULL(msf.FormActive, mf.FormActive) AS FormActive,
    msf.ParentId, msf.CreatedAt, msf.CreatedBy
  FROM dbo.MetaForm mf
  JOIN dbo.MetaStudyForm msf ON msf.FormId = mf.FormId
  WHERE msf.StudyId=@StudyId
END

CREATE SYNONYM dbo.GetMetaForms FOR CRF.GetMetaForms
GO

PRINT '--  DROP view Meta.StudyForm and the Meta schema, where the view was the only object.'
GO

IF NOT OBJECT_ID('Meta.StudyForm') IS NULL
  DROP VIEW Meta.StudyForm
GO

IF NOT SCHEMA_ID('Meta') IS NULL
  DROP SCHEMA Meta
GO

EXECUTE dbo.DbFinalizeUpgrade 6310;
GO

COMMIT TRANSACTION UpgradeTo6310;
GO
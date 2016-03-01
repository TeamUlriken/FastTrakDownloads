-- Upgrade type: Feature.
-- Purpose of this upgrade:
--- Added function dbo.GetLastQuantities as utility function for reporting and populations.
--- Added procedure ENDO.GetAddisonPatients as an improvement over dbo.GetAddisonPatients.

SET NOEXEC OFF;
SET NOCOUNT ON;
GO

ALTER PROCEDURE dbo.DbStartUpgrade (@ExpectedVersion INT, @TargetVersion INT) AS
BEGIN
  DECLARE @RetVal INT;
  IF dbo.DbVersion() = @TargetVersion
  BEGIN
    PRINT 'Reapplying database upgrade ' + CONVERT(VARCHAR, @TargetVersion) + '.';
    UPDATE dbo.DbUpgradeLog
    SET DbUpgradeStart = GETDATE(), DbUpgradeEnd = NULL, UpgradedBy = USER_ID()
    WHERE DbVer = @TargetVersion;
    SET @RetVal = 1;
  END
  ELSE
  IF dbo.DbVersion() = @ExpectedVersion
  BEGIN
    INSERT INTO dbo.DbUpgradeLog (DbVer, DbUpgradeStart)
      VALUES (@TargetVersion, GETDATE());
    PRINT 'Applying database upgrade ' + CONVERT(VARCHAR, @TargetVersion) + '.'
    SET @RetVal = 2;
  END
  ELSE
  BEGIN
    PRINT 'Unexpected database version: ' + CONVERT(VARCHAR, dbo.DbVersion()) + '!'
    SET @RetVal = -1;
  END;
  RETURN @RetVal;
END
GO

ALTER PROCEDURE dbo.DbFinalizeUpgrade (@DbVer INT) AS
BEGIN
  UPDATE dbo.DbUpgradeLog
  SET DbUpgradeEnd = GETDATE()
  WHERE DbVer = @DbVer;
  IF dbo.DbVersion() = @DbVer
    PRINT 'Upgrade to ' + CONVERT(VARCHAR, @DbVer) + ' was successful.'
  ELSE
    PRINT 'Upgrade was NOT successful, database version is ' + CONVERT(VARCHAR, dbo.DbVersion()) + '.'
END
GO

-- BEGIN start sequence (copy to future upgrade scripts)

DECLARE @RetVal INT;
EXEC @RetVal = dbo.DbStartUpgrade 6302, 6303;
IF @RetVal < 0
  SET NOEXEC ON
ELSE
  SET NOEXEC OFF
GO

-- END start sequence

BEGIN TRANSACTION UpgradeTo6303

IF NOT OBJECT_ID('dbo.GetLastQuantities') IS NULL
  DROP FUNCTION dbo.GetLastQuantities
GO

CREATE FUNCTION dbo.GetLastQuantities (@ItemId INT)
RETURNS @LastEnumVals TABLE (
  PersonId INT NOT NULL,
  Quantity DECIMAL(12, 4) NOT NULL
) AS
BEGIN
  INSERT @LastEnumVals
    SELECT a.PersonId, a.Quantity
    FROM (SELECT ce.PersonId, cdp.Quantity, RANK() OVER (PARTITION BY ce.PersonId ORDER BY ce.EventTime DESC) AS OrderNo
      FROM dbo.ClinEvent ce
      JOIN dbo.ClinDataPoint cdp
        ON cdp.EventId = ce.EventId
      WHERE cdp.ItemId = @ItemId
      AND NOT cdp.Quantity IS NULL) a
    WHERE a.OrderNo = 1;
  RETURN;
END
GO

IF NOT OBJECT_ID('ENDO.GetAddisonPatients') IS NULL
  DROP PROCEDURE ENDO.GetAddisonPatients
GO

CREATE PROCEDURE ENDO.GetAddisonPatients (@StudyId INT) AS
BEGIN
  SELECT v.PersonId, v.DOB, v.FullName, v.GroupName, v.GenderId,
    'Diagnoseår ' + ISNULL(CONVERT(VARCHAR, CONVERT(INT, T6089.Quantity)), 'mangler') + ', ' +
    ISNULL(T6090.OptionText, '(subtype mangler)') + '.' AS InfoText
  FROM dbo.ViewActiveCaseListStub v
  LEFT JOIN dbo.GetLastEnumValues(6090) AS T6090 ON T6090.PersonId = v.PersonId
  LEFT JOIN dbo.GetLastEnumValues(6299) AS T6299 ON T6299.PersonId = v.PersonId
  LEFT JOIN dbo.GetLastQuantities(6089) AS T6089 ON T6089.PersonId = v.PersonId
  WHERE v.StudyId = @StudyId AND (T6090.EnumVal = 1 OR T6299.EnumVal = 1 OR T6089.Quantity > 1900)
END
GO

GRANT EXECUTE ON ENDO.GetAddisonPatients TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('dbo.GetAddisonPatients') IS NULL
  DROP PROCEDURE dbo.GetAddisonPatients
GO

EXECUTE dbo.DbFinalizeUpgrade 6303;
GO

COMMIT TRANSACTION UpgradeTo6303;
GO
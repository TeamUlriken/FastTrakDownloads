-- Upgrade type: Feature.
-- Purpose of this upgrade:
--- Added view ViewFullCaseListStub, needed for NDV.GetGravide.
--- Added table values function dbo.GetLastEnumValues for easier selections based on EnumVal variables.
--- Added procedure NDV.GetType1WithoutConsent to illustrate dbo.GetLastEnumValues (is also downloaded with DbProcList.asp)

SET NOEXEC OFF;
SET NOCOUNT ON;

IF dbo.DbVersion() = 6302
BEGIN
  PRINT 'Reapplying database upgrade 6302.'
  DELETE FROM dbo.DbUpgradeLog
  WHERE DbVer = 6302
END
ELSE
IF dbo.DbVersion() = 6301
  PRINT 'Applying database upgrade 6301.'
ELSE
BEGIN
  PRINT 'Unexpected database version: ' + CONVERT(VARCHAR, dbo.DbVersion()) + '!'
  SET NOEXEC ON;
END
GO

BEGIN TRANSACTION UpgradeTo6302

EXECUTE dbo.DbStartUpgrade 6302;
GO

IF NOT OBJECT_ID('ViewFullCaseListStub') IS NULL
  DROP VIEW dbo.ViewFullCaseListStub
GO

CREATE VIEW dbo.ViewFullCaseListStub AS
  SELECT p.PersonId, p.DOB, p.ReverseName AS FullName, a.StudyId, ISNULL(sg.GroupName, '(ingen)') AS GroupName, p.GenderId, ISNULL(ss.StatusText, '(ukjent)') AS InfoText
  FROM (SELECT DISTINCT sc.StudyId, sc.PersonId
    FROM dbo.StudCase sc
    JOIN dbo.StudyGroup sg
      ON sg.StudyId = sg.StudyId AND sg.GroupId = sc.GroupId
    JOIN dbo.UserList ul
      ON ul.CenterId = sg.CenterId AND ul.UserId = USER_ID()
    UNION
    SELECT DISTINCT sc.StudyId, sc.PersonId
    FROM dbo.StudCase sc
    JOIN dbo.StudCaseLog scl
      ON scl.StudCaseId = sc.StudCaseId
    JOIN dbo.StudyGroup sg
      ON sg.StudyId = sc.StudyId AND sg.GroupId = scl.OldGroupId
    JOIN dbo.UserList ul
      ON ul.CenterId = sg.CenterId AND ul.UserId = USER_ID()) a
  JOIN dbo.StudCase sc ON sc.StudyId = a.StudyId AND sc.PersonId = a.PersonId
  JOIN dbo.Person p ON p.PersonId = sc.PersonId
  LEFT JOIN dbo.StudyGroup sg ON sg.StudyId = sc.StudyId AND sg.GroupId = sc.GroupId
  LEFT JOIN dbo.StudyStatus ss ON ss.StudyId = sc.StudyId AND ss.StatusId = sc.StatusId
GO

GRANT SELECT ON dbo.ViewFullCaseListStub TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('dbo.GetLastEnumValues') IS NULL
  DROP FUNCTION dbo.GetLastEnumValues
GO

CREATE FUNCTION dbo.GetLastEnumValues (@ItemId INT)
RETURNS @LastEnumVals TABLE (
  PersonId INT NOT NULL,
  EnumVal INT NOT NULL,
  ShortCode VARCHAR(5),
  OptionText VARCHAR(MAX)
) AS
BEGIN
  INSERT @LastEnumVals
    SELECT a.PersonId, a.EnumVal, mia.ShortCode, mia.OptionText
    FROM (SELECT ce.PersonId, cdp.EnumVal, RANK()
        OVER (
        PARTITION BY ce.PersonId
        ORDER BY ce.EventTime DESC) AS OrderNo
      FROM dbo.ClinEvent ce
      JOIN dbo.ClinDataPoint cdp
        ON cdp.EventId = ce.EventId
      WHERE cdp.ItemId = @ItemId
      AND ISNULL(cdp.EnumVal, -1) >= 0) a
    JOIN dbo.MetaItemAnswer mia ON mia.ItemId = @ItemId AND mia.OrderNumber = a.EnumVal
    WHERE a.OrderNo = 1;
  RETURN;
END
GO

IF NOT OBJECT_ID('NDV.GetType1WithoutConsent') IS NULL
  DROP PROCEDURE NDV.GetType1WithoutConsent
GO

CREATE PROCEDURE NDV.GetType1WithoutConsent (@StudyId INT) AS
BEGIN
  SET NOCOUNT ON;
  SELECT v.*, ISNULL(Samtykke.OptionText, 'Ubesvart') AS InfoText
  FROM dbo.GetLastEnumValues(3196) DiaType
  LEFT JOIN dbo.GetLastEnumValues(3389) Samtykke ON Samtykke.PersonId = DiaType.PersonId
  JOIN dbo.ViewActiveCaseListStub v ON v.PersonId = DiaType.PersonId AND v.StudyId = @StudyId
  WHERE (DiaType.EnumVal = 1) AND (NOT ISNULL(Samtykke.EnumVal, -1) IN (1, 2, 3))
END
GO

GRANT EXECUTE ON NDV.GetType1WithoutConsent TO [public] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6302;
GO

COMMIT TRANSACTION UpgradeTo6302;
GO

IF dbo.DbVersion() = 6302
  PRINT 'Upgrade was applied successfully.'
ELSE
  PRINT 'Upgrade was NOT successful, database version is ' + CONVERT(VARCHAR, dbo.DbVersion()) + '.'
GO
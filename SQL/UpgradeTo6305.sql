SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6305
GO

PRINT 'Overall purpose: Bugfixes and performance improvements.'
PRINT 'Includes ReadOnly role, which is a feature requested from Bergen Kommune.'

--  ALTER dbo.DbStartUpgrade with SET NOCOUNT ON for cleaner output, @IsRepeatable to remove logged updates.
--  ALTER dbo.DbFinalizeUpgrade with SET NOCOUNT ON for cleaner messages results for update scripts.
--  CREATE dbo.GetLastSignedFormList table function to return last signed form of a specific type.
--  CREATE dbo.GetLastGroupCaseList table function to return the last group a person is/was in given a StudyId
--  ALTER GBD.GetCaseListDiedHere, a population of patients who died at the same site the user is logged in.
--  ALTER dbo.GetMDRD, using a larger decimal data type and only labdata before specified cutoff date.
--  GRANT EXECUTE ON dbo.UpdateDrugReaction TO public, has not been granted to anybody.
--  ALTER dbo.UpdateCAVE, Logging of changes to CAVE field is now handled by trigger, to dbo.PersonDocumentLog.

EXECUTE dbo.DbStartUpgrade 6304, 6305;
GO

-- -----------------------------------------------------------------------------
-- END Start sequence. Copy statements above this to subsequent upgrade scripts.
-- -----------------------------------------------------------------------------

PRINT '--  ALTER dbo.DbStartUpgrade with SET NOCOUNT ON for cleaner output, @IsRepeatable to remove logged updates.';
GO

ALTER PROCEDURE dbo.DbStartUpgrade (@ExpectedVersion INT, @TargetVersion INT, @IsRepeatable BIT = 1) AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @InfoText VARCHAR(65);
  SET @InfoText = CONVERT(VARCHAR, @TargetVersion) + ' for ' + DB_NAME() + ' on ' + @@servername + '.' + CHAR(13);
  IF @IsRepeatable = 1
    DELETE FROM DbUpgradeLog
    WHERE DbVer > @TargetVersion;
  DECLARE @RetVal INT;
  IF dbo.DbVersion() = @TargetVersion
  BEGIN
    PRINT 'Reapplying database upgrade ' + @InfoText;
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
    PRINT 'Applying database upgrade ' + @InfoText;
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

PRINT '--  ALTER dbo.DbFinalizeUpgrade with SET NOCOUNT ON for cleaner messages results for update scripts.';
GO

ALTER PROCEDURE dbo.DbFinalizeUpgrade (@DbVer INT) AS
BEGIN
  SET NOCOUNT ON;
  UPDATE dbo.DbUpgradeLog
  SET DbUpgradeEnd = GETDATE()
  WHERE DbVer = @DbVer;
  IF dbo.DbVersion() = @DbVer
    PRINT CHAR(13) + 'Upgrade to ' + CONVERT(VARCHAR, @DbVer) + ' was successful.'
  ELSE
    PRINT CHAR(13) + 'Upgrade was NOT successful, database version is ' + CONVERT(VARCHAR, dbo.DbVersion()) + '.'
END
GO

IF USER_ID('ReadOnly') IS NULL
BEGIN
  CREATE ROLE ReadOnly
  INSERT INTO dbo.UserRoleInfo (RoleName, RoleCaption, RoleInfo, IsActive, SortOrder)
    VALUES ('ReadOnly', 'Lesetilgang', 'Gir tilgang til lesing av journalinformasjon, men ingen skriving.', 1, 19)
END
GO

IF NOT OBJECT_ID('GetLastSignedFormList') IS NULL
  DROP FUNCTION dbo.GetLastSignedFormList;
GO

PRINT '--  CREATE dbo.GetLastSignedFormList table function to return last signed form of a specific type.';
GO

CREATE FUNCTION dbo.GetLastSignedFormList (@StudyId INT, @FormName VARCHAR(24))
RETURNS @FormList TABLE (
  PersonId INT NOT NULL PRIMARY KEY,
  ClinFormId INT NOT NULL,
  EventTime DATETIME NOT NULL
) AS
BEGIN
  INSERT INTO @FormList
    SELECT a.PersonId, a.ClinFormId, a.EventTime
    FROM (SELECT ce.PersonId, cf.ClinFormId, ce.EventTime,
        RANK() OVER (PARTITION BY ce.PersonId ORDER BY ce.EventNum DESC) AS OrderNo
      FROM dbo.ClinForm cf
      JOIN dbo.ClinEvent ce
        ON ce.EventId = cf.EventId
      JOIN dbo.MetaForm mf
        ON mf.FormId = cf.FormId
      WHERE ce.StudyId = @StudyId
      AND mf.FormName = @Formname
      AND cf.FormStatus = 'L') a
    WHERE a.OrderNo = 1;
  RETURN;
END
GO

PRINT '--  CREATE dbo.GetLastGroupCaseList table function to return the last group a person is/was in given a StudyId';
GO

IF NOT OBJECT_ID('GetLastGroupCaseList') IS NULL
  DROP FUNCTION dbo.GetLastGroupCaseList;
GO

CREATE FUNCTION dbo.GetLastGroupCaseList (@StudyId INT)
RETURNS @CenterCaseList TABLE (
  PersonId INT NOT NULL,
  DOB DATETIME NOT NULL,
  GenderId INT NOT NULL,
  FullName VARCHAR(93) NOT NULL,
  StudyId INT NOT NULL,
  GroupName VARCHAR(24),
  FinState INT
) AS
BEGIN
  INSERT INTO @CenterCaseList (PersonId, DOB, FullName, StudyId, GroupName, GenderId, FinState)
    SELECT v.PersonId, p.DOB, p.ReverseName AS FullName, v.StudyId, sg.GroupName, p.GenderId, v.FinState
    FROM dbo.StudCase v
    JOIN dbo.Person p ON p.PersonId = v.PersonId
    JOIN (SELECT PersonId, NewGroupId
      FROM (SELECT sc.PersonId, scl.NewGroupId, RANK() OVER (PARTITION BY sc.PersonId ORDER BY scl.ChangedAt DESC) AS OrderNo
        FROM dbo.StudCase sc
        JOIN dbo.StudCaseLog scl
          ON scl.StudCaseId = sc.StudCaseId
        WHERE sc.StudyId = @StudyId
        AND scl.NewGroupId IS NOT NULL) a
      WHERE a.OrderNo = 1) lsg ON lsg.PersonId = v.PersonId
    JOIN dbo.StudyGroup sg ON sg.StudyId = v.StudyId AND sg.GroupId = ISNULL(v.GroupId, lsg.NewGroupId)
    JOIN dbo.UserList ul ON ul.CenterId = sg.CenterId AND ul.UserId = USER_ID();
  RETURN;
END;
GO

PRINT '--  ALTER GBD.GetCaseListDiedHere, a population of patients who died at the same site the user is logged in.';
GO

ALTER PROCEDURE GBD.GetCaseListDiedHere (@StudyId INT) AS
BEGIN
  SELECT v.PersonId, v.DOB, v.FullName, v.GroupName, v.StudyId, v.GenderId,
    'LCP3:  ' + ISNULL(dbo.LongTime(f.EventTime), 'Ikke utfylt') + '. Data til ' + dbo.ShortTime(sc.LastWrite) + '.' AS InfoText,
    sc.LastWrite, f.EventTime
  FROM dbo.GetLastGroupCaseList(@StudyId) v
  JOIN dbo.StudCase sc ON sc.StudyId = @StudyId AND sc.PersonId = v.PersonId
  LEFT JOIN dbo.GetLastSignedFormList(@StudyId, 'LCP3') f ON f.PersonId = v.PersonId
  WHERE v.FinState = 5
  ORDER BY sc.LastWrite DESC;
END
GO


PRINT '--  ALTER dbo.GetMDRD, using a larger decimal data type and only labdata before specified cutoff date.';
GO

ALTER FUNCTION dbo.GetMDRD (@PersonId INT, @CalcAt DATETIME)
RETURNS DECIMAL(9, 1) AS
BEGIN
  -- IDMS-Traceable MDRD Study Equation
  DECLARE @Age FLOAT;
  DECLARE @Sex INT;
  DECLARE @Creat FLOAT;
  DECLARE @k FLOAT;
  DECLARE @GFR FLOAT;
  DECLARE @BSA FLOAT;
  /* Find age for person at time @CalcAt */
  SELECT @Age = CONVERT(FLOAT, @CalcAt - DOB) / 365.25
  FROM Person
  WHERE PersonId = @PersonId;
  SELECT @Sex = GenderId
  FROM Person
  WHERE PersonId = @PersonId;
  /* Set up constants for sex male/female */
  IF @Sex = 2
    SET @k = 0.742
  ELSE
    SET @k = 1.0;
  SET @Creat = dbo.GetLastLabInPeriod(@PersonId, 49, 0, @CalcAt);
  /* Calculate GFR if everything is good, make sure @Creat is not too low */
  IF ((@Creat IS NULL)
    OR (@Age IS NULL)
    OR (@Creat < 10.0))
    SET @GFR = NULL
  ELSE
    SET @GFR = 175 * POWER(@Creat / 88.4, -1.154) * POWER(@Age, -0.203) * @k;
  RETURN @GFR;
END
GO

PRINT '--  GRANT EXECUTE ON dbo.UpdateDrugReaction TO public, has not been granted to anybody.'
GO

GRANT EXECUTE ON dbo.UpdateDrugReaction TO [public] AS [dbo]
GO

PRINT '--  ALTER dbo.UpdateCAVE, Logging of changes to CAVE field is now handled by trigger, to dbo.PersonDocumentLog.';
GO

ALTER PROCEDURE dbo.UpdateCAVE (@PersonId INT, @CAVE VARCHAR(MAX)) AS
BEGIN
  UPDATE dbo.Person
  SET CAVE = @CAVE
  WHERE PersonId = @PersonId;
  INSERT INTO dbo.CaseLog (PersonId, LogType, LogText)
    VALUES (@PersonId, 'CAVE', 'CAVE redigert  av ' + USER_NAME());
END
GO

-- -----------------------------------------------------------------------------
-- Finalization sequence (copy to subsequent upgrade scripts)
-- -----------------------------------------------------------------------------

EXECUTE dbo.DbFinalizeUpgrade 6305;
GO

COMMIT TRANSACTION UpgradeTo6305;
GO
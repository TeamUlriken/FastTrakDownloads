SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6046
PRINT 'Starting upgrade to 6046'

-- Purpose of this update:
--   Add some functions for reporting of labdata
--   Needed in Hoftebruddregister, Sykehuset Innlandet.

DELETE FROM DbUpgradeLog
WHERE  DbVer > 6045;

EXEC DbCheckVersion 6045;
EXECUTE DbStartUpgrade 6046;
GO

IF NOT OBJECT_ID('GetLastLabInPeriod') IS NULL DROP FUNCTION dbo.GetLastLabInPeriod
GO
IF NOT OBJECT_ID('GetFirstLabInPeriod') IS NULL DROP FUNCTION dbo.GetFirstLabInPeriod
GO
IF NOT OBJECT_ID('GetMaxLabInPeriod') IS NULL DROP FUNCTION dbo.GetMaxLabInPeriod
GO
IF NOT OBJECT_ID('GetMinLabInPeriod') IS NULL DROP FUNCTION dbo.GetMinLabInPeriod
GO
IF NOT OBJECT_ID('GetLastLabDateInPeriod') IS NULL DROP FUNCTION dbo.GetLastLabDateInPeriod
GO
IF NOT OBJECT_ID('GetFirstLabDateInPeriod') IS NULL DROP FUNCTION dbo.GetFirstLabDateInPeriod
GO
IF NOT OBJECT_ID('GetMaxLabDateInPeriod') IS NULL DROP FUNCTION dbo.GetMaxLabDateInPeriod
GO
IF NOT OBJECT_ID('GetMinLabDateInPeriod') IS NULL DROP FUNCTION dbo.GetMinLabDateInPeriod
GO

CREATE FUNCTION dbo.GetLastLabInPeriod( @PersonId INT, @LabClassId INT, @StartAt DateTime, @StopAt DateTime ) RETURNS FLOAT
AS
BEGIN
  DECLARE @RetVal FLOAT;
  SET @RetVal = ( SELECT TOP 1 NumResult
  FROM dbo.LabData ld JOIN LabCode lc ON lc.LabCodeId=ld.LabCodeId
  WHERE ld.PersonId = @PersonId AND lc.LabClassId=@LabClassId
  AND ( ld.LabDate >= @StartAt ) AND ( ld.LabDate < @StopAt ) AND ISNULL(ld.NumResult,-1) >= 0 
  ORDER BY ld.LabDate DESC );
  RETURN @RetVal; 
END
GO

GRANT EXECUTE ON dbo.GetLastLabInPeriod TO [public] as [dbo]
GO

CREATE FUNCTION dbo.GetFirstLabInPeriod( @PersonId INT, @LabClassId INT, @StartAt DateTime, @StopAt DateTime ) RETURNS FLOAT
AS
BEGIN
  DECLARE @RetVal FLOAT;
  SET @RetVal = ( SELECT TOP 1 NumResult
  FROM dbo.LabData ld JOIN LabCode lc ON lc.LabCodeId=ld.LabCodeId
  WHERE ld.PersonId = @PersonId AND lc.LabClassId=@LabClassId
  AND ( ld.LabDate >= @StartAt ) AND ( ld.LabDate < @StopAt ) AND ISNULL(ld.NumResult,-1) >= 0 
  ORDER BY ld.LabDate ASC );
  RETURN @RetVal; 
END
GO

GRANT EXECUTE ON dbo.GetFirstLabInPeriod TO [public] as [dbo]
GO

CREATE FUNCTION dbo.GetMaxLabInPeriod( @PersonId INT, @LabClassId INT, @StartAt DateTime, @StopAt DateTime ) RETURNS FLOAT
AS
BEGIN
  DECLARE @RetVal FLOAT;
  SET @RetVal = ( SELECT TOP 1 NumResult
  FROM dbo.LabData ld JOIN LabCode lc ON lc.LabCodeId=ld.LabCodeId
  WHERE ld.PersonId = @PersonId AND lc.LabClassId=@LabClassId
  AND ( ld.LabDate >= @StartAt ) AND ( ld.LabDate < @StopAt ) AND ISNULL(ld.NumResult,-1) >= 0 
  ORDER BY ld.NumResult DESC );
  RETURN @RetVal; 
END
GO

GRANT EXECUTE ON dbo.GetMaxLabInPeriod TO [public] as [dbo]
GO

CREATE FUNCTION dbo.GetMinLabInPeriod( @PersonId INT, @LabClassId INT, @StartAt DateTime, @StopAt DateTime ) RETURNS FLOAT
AS
BEGIN
  DECLARE @RetVal FLOAT;
  SET @RetVal = ( SELECT TOP 1 NumResult
  FROM dbo.LabData ld JOIN LabCode lc ON lc.LabCodeId=ld.LabCodeId
  WHERE ld.PersonId = @PersonId AND lc.LabClassId=@LabClassId
  AND ( ld.LabDate >= @StartAt ) AND ( ld.LabDate < @StopAt ) AND ISNULL(ld.NumResult,-1) >= 0 
  ORDER BY ld.NumResult ASC );
  RETURN @RetVal; 
END
GO

GRANT EXECUTE ON dbo.GetMinLabInPeriod TO [public] as [dbo]
GO

CREATE FUNCTION dbo.GetLastLabDateInPeriod( @PersonId INT, @LabClassId INT, @StartAt DateTime, @StopAt DateTime ) RETURNS DateTime
AS
BEGIN
  DECLARE @RetVal DateTime;
  SET @RetVal = ( SELECT TOP 1 LabDate
  FROM dbo.LabData ld JOIN LabCode lc ON lc.LabCodeId=ld.LabCodeId
  WHERE ld.PersonId = @PersonId AND lc.LabClassId=@LabClassId
  AND ( ld.LabDate >= @StartAt ) AND ( ld.LabDate < @StopAt ) AND ISNULL(ld.NumResult,-1) >= 0 
  ORDER BY ld.LabDate DESC );
  RETURN @RetVal; 
END
GO

GRANT EXECUTE ON dbo.GetLastLabDateInPeriod TO [public] as [dbo]
GO

CREATE FUNCTION dbo.GetFirstLabDateInPeriod( @PersonId INT, @LabClassId INT, @StartAt DateTime, @StopAt DateTime ) RETURNS DateTime
AS
BEGIN
  DECLARE @RetVal DateTime;
  SET @RetVal = ( SELECT TOP 1 LabDate
  FROM dbo.LabData ld JOIN LabCode lc ON lc.LabCodeId=ld.LabCodeId
  WHERE ld.PersonId = @PersonId AND lc.LabClassId=@LabClassId
  AND ( ld.LabDate >= @StartAt ) AND ( ld.LabDate < @StopAt ) AND ISNULL(ld.NumResult,-1) >= 0 
  ORDER BY ld.LabDate ASC );
  RETURN @RetVal; 
END
GO

GRANT EXECUTE ON dbo.GetFirstLabDateInPeriod TO [public] as [dbo]
GO

CREATE FUNCTION dbo.GetMaxLabDateInPeriod( @PersonId INT, @LabClassId INT, @StartAt DateTime, @StopAt DateTime ) RETURNS DateTime
AS
BEGIN
  DECLARE @RetVal DateTime;
  SET @RetVal = ( SELECT TOP 1 LabDate
  FROM dbo.LabData ld JOIN LabCode lc ON lc.LabCodeId=ld.LabCodeId
  WHERE ld.PersonId = @PersonId AND lc.LabClassId=@LabClassId
  AND ( ld.LabDate >= @StartAt ) AND ( ld.LabDate < @StopAt ) AND ISNULL(ld.NumResult,-1) >= 0 
  ORDER BY ld.NumResult DESC );
  RETURN @RetVal; 
END
GO

GRANT EXECUTE ON dbo.GetMaxLabDateInPeriod TO [public] as [dbo]
GO

CREATE FUNCTION dbo.GetMinLabDateInPeriod( @PersonId INT, @LabClassId INT, @StartAt DateTime, @StopAt DateTime ) RETURNS DateTime
AS
BEGIN
  DECLARE @RetVal DateTime;
  SET @RetVal = ( SELECT TOP 1 LabDate
  FROM dbo.LabData ld JOIN LabCode lc ON lc.LabCodeId=ld.LabCodeId
  WHERE ld.PersonId = @PersonId AND lc.LabClassId=@LabClassId
  AND ( ld.LabDate >= @StartAt ) AND ( ld.LabDate < @StopAt ) AND ISNULL(ld.NumResult,-1) >= 0 
  ORDER BY ld.NumResult ASC );
  RETURN @RetVal; 
END
GO

GRANT EXECUTE ON dbo.GetMinLabDateInPeriod TO [public] as [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6046;
GO

COMMIT TRANSACTION UpgradeTo6046;
GO 

IF dbo.FnEventTimeToNum( '1900-01-01' ) = 24
  SET NOEXEC OFF
ELSE  
  SET NOEXEC ON
GO

ALTER TABLE dbo.ClinEvent ADD EventTimeOld DATETIME
GO

UPDATE dbo.ClinEvent
SET EventTimeOld = EventTime
GO

ALTER FUNCTION dbo.FnEventNumToDate (@EventNum INT)
RETURNS DATETIME AS
BEGIN
  DECLARE @RetVal DATETIME;
  SET @RetVal = CONVERT(DATETIME, (CONVERT(FLOAT, (@EventNum - 1440.0)) / 1440.0 + 1.0 / 24 / 60 / 60));
  RETURN @RetVal
END
GO

ALTER FUNCTION dbo.FnEventTimeToNum (@EventTime DATETIME)
RETURNS INT AS
BEGIN
  RETURN ROUND(CONVERT(FLOAT, @EventTime) * 1440.0 + 1440.0, 0);
END
GO

ALTER PROCEDURE dbo.GetDatabaseInfo AS
BEGIN
  SET DATEFORMAT YMD;
  SELECT USER_ID() AS UserId, USER_NAME() AS UserName, DB_NAME() AS DatabaseName,
    MAX(dbVer) AS DatabaseVersion, 1 AS ServerType,
    GETDATE() AS ServerTime,
    @@VERSION AS ServerVersion,
    1440 AS EventScale, dbo.FnEventNumToDate(0) AS NullDateTime
  FROM dbo.DbUpgradeLog
  WHERE NOT DbUpgradeEnd IS NULL;
END
GO

ALTER TABLE dbo.ClinEvent DROP COLUMN EventTime
GO

ALTER TABLE dbo.ClinEvent ADD EventTime AS CONVERT(DATETIME, CONVERT(FLOAT, EventNum - 1440.0) / 1440.0 + 1.0 / 24 / 60 / 60 / 1000)
GO

UPDATE dbo.ClinEvent
SET EventNum = EventNum * 60
GO



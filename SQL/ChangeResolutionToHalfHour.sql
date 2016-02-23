ALTER FUNCTION dbo.FnEventNumToDate( @EventNum INT ) RETURNS DateTime
AS
BEGIN
  DECLARE @RetVal DateTime;
  SET @RetVal = convert(datetime,(convert(float,(@EventNum - 48)) / 48 + 0.00000002));
  RETURN @RetVal
END
GO

ALTER FUNCTION dbo.FnEventTimeToNum( @EventTime DateTime ) RETURNS INT
AS
BEGIN
  RETURN ROUND( CONVERT(float,@EventTime)*48+48, 0 );
END
GO

ALTER PROCEDURE dbo.GetDatabaseInfo AS
BEGIN
  SET DATEFORMAT YMD;
  SELECT user_id() AS UserId,user_name() AS UserName,DB_NAME() as DatabaseName,
    Max(dbVer) AS DatabaseVersion,1 as ServerType,getdate() as ServerTime, @@VERSION as ServerVersion, 
    48 as EventScale,dbo.FnEventNumToDate(0) as NullDateTime
    FROM DbUpgradeLog WHERE NOT DbUpgradeEnd IS NULL;
END
GO

ALTER TABLE dbo.ClinEvent DROP COLUMN EventTime
GO

ALTER TABLE dbo.ClinEvent ADD EventTime AS (CONVERT([datetime],CONVERT([float],[EventNum]-(48),0)/(48)+(0.00000002),0))
GO

UPDATE ClinEvent SET EventNum = EventNum * 2
GO

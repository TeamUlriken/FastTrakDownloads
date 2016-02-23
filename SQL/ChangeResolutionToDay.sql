UPDATE dbo.ClinEvent SET EventNum = EventNum / 24 where EventNum > 100000
GO

ALTER TABLE dbo.ClinEvent DROP COLUMN EventTime
ALTER TABLE dbo.ClinEvent ADD EventTime AS CONVERT( DateTime, (EventNum - 1) )
GO

ALTER FUNCTION dbo.FnEventNumToDate( @EventNum INT ) RETURNS DateTime
AS
BEGIN
  RETURN DATEADD( hour, -24, convert( datetime,( convert( float, ( @EventNum ) ) ) ) );
END
GO

ALTER FUNCTION [dbo].[FnEventTimeToNum]( @EventTime DateTime ) RETURNS INT
AS
BEGIN
  RETURN ROUND( CONVERT( float, DATEADD( hour, 12, @EventTime) ), 0 );
END
GO

ALTER PROCEDURE dbo.GetDatabaseInfo AS
BEGIN
  SET DATEFORMAT YMD;
  SELECT user_id() AS UserId,user_name() AS UserName,DB_NAME() as DatabaseName,
    Max(dbVer) AS DatabaseVersion,1 as ServerType,getdate() as ServerTime, @@VERSION as ServerVersion, 
    1 as EventScale,dbo.FnEventNumToDate(0) as NullDateTime
    FROM dbo.DbUpgradeLog WHERE NOT DbUpgradeEnd IS NULL;
END
GO

-- To Verify succesfull conversion:
-- SELECT EventNum,EventTime,dbo.FnEventTimeToNum(EventTime),dbo.FnEventNumToDate(EventNum) from ClinEvent
-- EXEC GetDatabaseInfo

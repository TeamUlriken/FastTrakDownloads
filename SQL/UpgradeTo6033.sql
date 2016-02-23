BEGIN TRANSACTION UpgradeTo6033
PRINT 'Starting upgrade to 6033'

DELETE FROM DbUpgradeLog WHERE DbVer > 6032;

EXEC DbCheckVersion 6032;
EXECUTE DbStartUpgrade 6033;
GO

ALTER PROCEDURE dbo.ReportSessionsPerWeek( @CenterId INT = 0 )
AS
BEGIN
  SELECT ServYear,ServWeek,count(*) AS SessCount FROM dbo.UserLog lg
  JOIN dbo.UserList usr ON lg.UserId=usr.UserId
  WHERE ( usr.CenterId=@CenterId ) OR ( @CenterId=0)
  GROUP BY ServYear,ServWeek
  ORDER BY ServYear,ServWeek
END
GO

IF NOT OBJECT_ID('Report.CaseCountByCenterAndGroup') IS NULL
  DROP VIEW Report.CaseCountByCenterAndGroup
GO

CREATE VIEW Report.CaseCountByCenterAndGroup 
AS
  SELECT sc.StudyId,sg.CenterId,c.CenterName,sg.GroupName,count(*) as GroupCount 
  FROM dbo.StudCase sc
  JOIN dbo.StudyGroup sg on sg.StudyId=sc.StudyId and sg.GroupId=sc.GroupId AND sg.GroupActive=1
  JOIN dbo.StudyStatus ss on ss.StudyId=sc.StudyId AND sc.FinState=ss.StatusId AND ss.StatusActive=1
  JOIN dbo.StudyCenter c ON c.CenterId=sg.CenterId
  GROUP BY sc.StudyId,sg.CenterId,c.CenterName,sg.GroupName
GO

IF NOT OBJECT_ID('Report.DrugUseStatistics') IS NULL
  DROP VIEW Report.DrugUseStatistics
GO

CREATE VIEW Report.DrugUseStatistics  
AS
SELECT ac.StudyId,k.AtcCode,k.AtcName,
  COUNT(*) as n,
  CAST(100.00 * count(*) /(select count(distinct personid) from dbo.Person )
    AS DECIMAL(9,2)) as pct,
    
  MIN(Dose24hDD) as [MinDD],
  CAST( AVG(Dose24hDD) AS DECIMAL(9,2) ) as [AvgDD],
  MAX(Dose24hDD) as [MaxDD],

  MIN(Dose24hCount) AS MinN,
  CAST( AVG(Dose24hCount) AS DECIMAL(9,2) ) AS AvgN,
  MAX(Dose24hCount) AS MaxN,

  VAR(Dose24hDD) AS VarDD,
  VARP(Dose24hDD) AS VarPDD,
  STDEV(Dose24hDD) AS StdDD,
  STDEVP(Dose24hDD) AS StdPDD,

  VAR(Dose24hCount) AS VarN,
  VARP(Dose24hCount) AS VarPN,
  STDEV(Dose24hCount) AS StdN,
  STDEVP(Dose24hCount) AS StdPN

FROM dbo.DrugTreatment dt
JOIN dbo.AllActiveCases ac on ac.PersonId=dt.PersonId
JOIN dbo.KBAtcIndex k ON k.AtcCode=dt.ATC
  WHERE( StopAt IS NULL ) OR ( StopAt > getdate())
 AND ( NOT ATC IS NULL )
 AND ( NOT Dose24hDD IS NULL )
 AND ( NOT Dose24hCount IS NULL )
GROUP BY ac.StudyId,k.AtcCode,k.AtcName
GO

COMMIT TRANSACTION UpgradeTo6033;
GO

EXECUTE dbo.DbFinalizeUpgrade 6033;
GO



SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6010
PRINT 'Starting upgrade to 6010'

DELETE FROM DbUpgradeLog WHERE DbVer > 6009;

EXEC DbCheckVersion 6009;
EXECUTE DbStartUpgrade 6010;
GO

ALTER VIEW Report.LabTestOverview (LabCodeId, LabClassId, LabName, FriendlyName, FurstId, VarName, LabCount, MinResult, MaxResult, AvgResult) 
AS
SELECT
    lc.LabCodeId,cl.LabClassId,lc.LabName,cl.FriendlyName,cl.FurstId,cl.VarName, count(*) as LabCount, 
      min(ld.NumResult),max(ld.NumResult),avg(ld.NumResult)                                           
  FROM LabCode lc 
  JOIN LabData ld ON ld.LabCodeId=lc.LabCodeId
  LEFT OUTER JOIN LabClass cl ON cl.LabClassId=lc.LabClassId
  GROUP BY
    lc.LabCodeId,cl.LabClassId,lc.LabName,cl.FriendlyName,cl.FurstId,cl.VarName
GO


ALTER VIEW Report.LabClassOverview (LabClassId,FriendlyName, FurstId, LoincCode, VarName, LabCount) 
AS
SELECT cl.LabClassId,ISNULL(cl.FriendlyName,'Uklassifiserte prøver') as FriendlyName,cl.FurstId,cl.Loinc as LoincCode,cl.VarName, count(*) as LabCount                                           
  FROM LabCode lc 
  JOIN LabData ld ON ld.LabCodeId=lc.LabCodeId
  LEFT OUTER JOIN LabClass cl ON cl.LabClassId=lc.LabClassId
  GROUP BY cl.LabClassId,cl.FriendlyName,cl.FurstId,cl.Loinc,cl.VarName
GO

EXECUTE DbFinalizeUpgrade 6010;
GO

COMMIT TRANSACTION UpgradeTo6010;
GO

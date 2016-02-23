SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6017
PRINT 'Starting upgrade to 6017'

DELETE FROM DbUpgradeLog WHERE DbVer > 6016;

EXEC DbCheckVersion 6016;
EXECUTE DbStartUpgrade 6017;
GO

IF NOT OBJECT_ID('dbo.GetFormDiagnosesICD10') IS NULL DROP PROCEDURE dbo.GetFormDiagnosesICD10
GO

CREATE PROCEDURE dbo.GetFormDiagnosesICD10( @PersonId INT )
AS
BEGIN
  SELECT ce.EventTime,co.EnumVal,mi.ItemId,mia.AnswerId,mia.ICD10,4 as ListId 
  FROM ClinEvent ce 
  JOIN ClinObservation co ON co.EventId=ce.EventId 
  JOIN MetaItem mi ON mi.VarName=co.VarName
  JOIN MetaItemAnswer mia ON mia.ItemId=mi.ItemId and co.EnumVal=mia.OrderNumber 
  WHERE ce.PersonId=@PersonId
  AND NOT mia.ICD10 IS NULL
  ORDER BY mia.ICD10,ce.EventTime DESC
END
GO

GRANT EXECUTE ON dbo.GetFormDiagnosesICD10 TO [public] AS [dbo]
GO


IF NOT OBJECT_ID('dbo.GetDiagnoseMapICD10') IS NULL DROP PROCEDURE dbo.GetDiagnoseMapICD10
GO

CREATE PROCEDURE dbo.GetDiagnoseMapICD10 AS
BEGIN
  SELECT mia.AnswerId,mia.OrderNumber,mia.ICD10,mi.VarName,mia.OrderNumber as EnumVal  
  FROM dbo.MetaItemAnswer mia JOIN dbo.MetaItem mi ON mi.ItemId=mia.ItemId 
  WHERE NOT mia.ICD10 IS NULL;
END
GO

GRANT EXECUTE ON dbo.GetDiagnoseMapICD10 TO [public] AS [dbo]
GO

GRANT SELECT ON dbo.MetaProblemType TO [public] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6017;
GO

COMMIT TRANSACTION UpgradeTo6017;
GO

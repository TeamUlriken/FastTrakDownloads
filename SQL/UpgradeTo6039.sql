BEGIN TRANSACTION UpgradeTo6039
PRINT 'Starting upgrade to 6039'

DELETE FROM DbUpgradeLog WHERE DbVer > 6038;

EXEC DbCheckVersion 6038;
EXECUTE DbStartUpgrade 6039;
GO

IF NOT OBJECT_ID('GetDrugPauses') IS NULL
  DROP PROCEDURE dbo.GetDrugPauses
GO

CREATE PROCEDURE dbo.GetDrugPauses( @PersonId INT ) AS
BEGIN
  SELECT dp.PauseId,dt.ATC,dt.DrugName,dt.DrugForm,dt.Strength,dt.StrengthUnit,
    dp.PauseReason, 
    dp.PausedAt, dp.PausedBy, pp.Signature as PausedBySign,  
    dp.RestartAt, dp.RestartBy, pr.Signature as RestartBySign,
    dt.StopAt, dt.StopBy, ps.Signature as StopBySign 
  FROM dbo.DrugPause dp
  JOIN dbo.DrugTreatment dt ON dp.TreatId=dt.TreatId                   
  JOIN dbo.UserList up ON up.UserId=dp.PausedBy
  LEFT OUTER JOIN dbo.UserList ur ON ur.UserId=dp.RestartBy
  LEFT OUTER JOIN dbo.UserList us ON us.UserId=dt.StopBy
  LEFT OUTER JOIN dbo.Person pp ON pp.PersonId=up.PersonId
  LEFT OUTER JOIN dbo.Person pr ON pr.PersonId=ur.PersonId
  LEFT OUTER JOIN dbo.Person ps ON ps.PersonId=us.PersonId
  WHERE dt.PersonId=@PersonId
END
GO

GRANT EXECUTE ON dbo.GetDrugPauses TO [public] AS [dbo]
GO

ALTER PROCEDURE dbo.GetClinProblems( @PersonId INT ) AS
BEGIN
  SELECT cp.ProbId,mi.ItemCode,mi.ItemName,cp.ProbType,cp.ProbSummary,
    cp.CreatedAt,cp.CreatedBy,
    cp.ProbDebut,cp.Priority,
    ml.DxSystem,cp.FamilyStatus
  FROM dbo.ClinProblem cp
  JOIN dbo.MetaNomListItem mli ON mli.ListItem=cp.ListItem
  JOIN dbo.MetaNomList ml ON ml.ListId=mli.ListId
  JOIN dbo.MetaNomItem mi on mi.ItemId=mli.ItemId
  WHERE cp.PersonId=@PersonId;
END
GO
 
EXECUTE dbo.DbFinalizeUpgrade 6039;
GO

COMMIT TRANSACTION UpgradeTo6039;
GO


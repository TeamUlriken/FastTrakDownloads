BEGIN TRANSACTION UpgradeTo6022
PRINT 'Starting upgrade to 6022'

DELETE FROM DbUpgradeLog WHERE DbVer > 6021;

EXEC DbCheckVersion 6021;
EXECUTE DbStartUpgrade 6022;
GO

EXEC UtilDropObject 'GetStudyRules'
GO

CREATE PROCEDURE dbo.GetStudyRules( @StudyId INT ) AS
BEGIN
SELECT r.RuleId,r.Title,r.Description,r.RuleClass 
  FROM dbo.DSSRule r
  JOIN dbo.DSSStudyRule sr ON sr.RuleId=r.RuleId
  JOIN dbo.Study s ON s.StudyName=sr.StudyName
  WHERE s.StudyId=@StudyId;  
END
GO

GRANT EXECUTE ON dbo.GetStudyRules TO [public] as [dbo]
GO

ALTER PROCEDURE CRF.GetOldData( @StudyId INT, @PersonId INT, @EventNum INT, @FormId INT )
AS
BEGIN
  SELECT mi.ItemId, co.VarName, co.Quantity, co.EnumVal, co.DTVal, co.TextVal, mi.ItemType 
  FROM dbo.ClinObservation co
  JOIN dbo.ClinEvent ce ON ce.EventId=co.EventId
  JOIN dbo.ClinForm cf ON cf.EventId=ce.EventId
  JOIN dbo.MetaFormItem mfi ON mfi.FormId=cf.FormId
  JOIN dbo.MetaItem mi ON mi.ItemId=mfi.ItemId AND mi.VarName=co.VarName
  WHERE ( ce.StudyId=@StudyId ) AND ( ce.PersonId=@PersonId ) AND ( ce.EventNum=@EventNum ) AND ( cf.FormId=@FormId )
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6022;
GO

COMMIT TRANSACTION UpgradeTo6022;
GO


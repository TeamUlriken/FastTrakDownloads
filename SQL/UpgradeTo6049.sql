BEGIN TRANSACTION UpgradeTo6049
PRINT 'Starting upgrade to 6049'

DELETE FROM DbUpgradeLog WHERE DbVer > 6048;

EXEC DbCheckVersion 6048;
EXECUTE DbStartUpgrade 6049;
GO

-- Drops procedures that have been moved to GBD schema

IF NOT OBJECT_ID( 'dbo.RuleLabData') IS NULL 
  DROP PROCEDURE dbo.RuleLabData
GO

IF NOT OBJECT_ID( 'dbo.RuleInfectionForm') IS NULL 
  DROP PROCEDURE dbo.RuleInfectionForm
GO

IF NOT OBJECT_ID( 'dbo.RuleReminder') IS NULL 
  DROP PROCEDURE dbo.RuleReminder
GO

IF NOT OBJECT_ID( 'dbo.RuleBerger') IS NULL 
  DROP PROCEDURE dbo.RuleBerger
GO

IF NOT OBJECT_ID( 'dbo.RuleHulten') IS NULL 
  DROP PROCEDURE dbo.RuleHulten
GO

IF NOT OBJECT_ID( 'dbo.RuleWarfarinAdjust') IS NULL 
  DROP PROCEDURE dbo.RuleWarfarinAdjust
GO

IF NOT OBJECT_ID( 'dbo.RuleWeight30Days') IS NULL 
  DROP PROCEDURE dbo.RuleWeight30Days
GO

EXECUTE dbo.DbFinalizeUpgrade 6049;
GO

COMMIT TRANSACTION UpgradeTo6049;
GO


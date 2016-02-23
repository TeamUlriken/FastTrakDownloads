SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6045
PRINT 'Starting upgrade to 6045'

-- Purpose of this update:
--   To add TestCase flag to Person, for simpler exclusion in reporting.
--   Add DoseUnit for safer prescription of drugs.

DELETE FROM DbUpgradeLog
WHERE  DbVer > 6044;

EXEC DbCheckVersion 6044;
EXECUTE DbStartUpgrade 6045;
GO

IF dbo.DbColumnExists( 'Person', 'TestCase') = 0 
  ALTER TABLE dbo.Person add TestCase BIT NOT NULL DEFAULT 0
GO

IF dbo.DbColumnExists( 'PIA', 'DoseUnit' ) = 0
  ALTER TABLE dbo.PIA ADD DoseUnit VARCHAR(24)
GO

ALTER PROCEDURE FEST.GetMatchingDrugs( @SearchText VARCHAR(32), @Strength FLOAT = NULL )
AS
BEGIN
  SET @SearchText=@SearchText + '%';   
  IF @Strength = 0 SET @Strength = NULL;
  SELECT ATC,DrugNameFormStrength,DrugName,DrugForm,Strength,StrengthUnit,SubstanceName 
  FROM dbo.PIA 
  WHERE ( ( SubstanceName LIKE @SearchText ) OR ( DrugName LIKE @SearchText ) OR ( ATC LIKE @SearchText) ) 
    AND ( ( @Strength IS NULL ) OR ( @Strength = Strength ) ); 
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6045;
GO

COMMIT TRANSACTION UpgradeTo6045;
GO 

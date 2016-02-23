BEGIN TRANSACTION UpgradeTo6042
PRINT 'Starting upgrade to 6042'

DELETE FROM DbUpgradeLog WHERE DbVer > 6041;

EXEC DbCheckVersion 6041;
EXECUTE DbStartUpgrade 6042;
GO

ALTER FUNCTION dbo.FnDSSRulesAreDirty( @StudyId INT, @PersonId INT ) RETURNS INT AS
BEGIN
  DECLARE @RuleLag FLOAT;
  DECLARE @RetVal INT;
  SELECT @RuleLag = RuleLag FROM dbo.StudCase WHERE StudyId=@StudyId AND PersonId=@PersonId;
  IF ( @RuleLag IS NULL ) OR ( @RuleLag > 0 )
    SET @RetVal = 1
  ELSE
    SET @RetVal = 0;
  RETURN @RetVal;
END
GO

IF dbo.DbCheckConstraintExists( 'C_PersonNoMatchGenderId' ) = 1
  ALTER TABLE dbo.Person DROP CONSTRAINT C_PersonNoMatchGenderId
GO

IF dbo.DbCheckConstraintExists( 'C_Person_DOB' ) = 1
  ALTER TABLE dbo.Person DROP CONSTRAINT C_Person_DOB
GO

IF dbo.DbCheckConstraintExists( 'C_NationalIdMatchesGenderId' ) = 1
  ALTER TABLE dbo.Person DROP CONSTRAINT C_NationalIdMatchesGenderId
GO

IF dbo.DbCheckConstraintExists( 'C_NationalIdMatchesDOB' ) = 1
  ALTER TABLE dbo.Person DROP CONSTRAINT C_NationalIdMatchesDOB
GO

ALTER TABLE dbo.Person WITH CHECK ADD CONSTRAINT C_NationalIdMatchesGenderId CHECK (CONVERT(INT,SUBSTRING([NationalId],9,1)) % 2 = [GenderId] % 2 OR DATALENGTH([NationalId]) = 0)
GO

ALTER TABLE dbo.Person WITH CHECK ADD CONSTRAINT C_NationalIdMatchesDOB CHECK (DATALENGTH([NationalId]) = 0 OR REPLACE(CONVERT(VARCHAR,[DOB],4),'.','') = SUBSTRING([NationalId],1,6) OR CONVERT(INT,REPLACE(CONVERT(VARCHAR,[DOB],4),'.','')) + 400000 = CONVERT(INT,SUBSTRING([NationalId],1,6)) OR CONVERT(INT,REPLACE(CONVERT(VARCHAR,[DOB],4),'.','')) + 4000 = CONVERT(INT,SUBSTRING([NationalId],1,6)))
GO

-- Remove unused procedures

IF NOT OBJECT_ID('GetBodySurfaceArea') IS NULL DROP FUNCTION dbo.GetBodySurfaceArea
GO

IF NOT OBJECT_ID('GetCockcroftGault') IS NULL DROP FUNCTION dbo.GetCockcroftGault
GO

IF NOT OBJECT_ID('GetClinFormData') IS NULL DROP PROCEDURE dbo.GetClinFormData
GO

-- Remove procedure made obsolete in 6020

IF NOT OBJECT_ID('[Report].[GetPercentileRanks]') IS NULL
   DROP PROCEDURE Report.GetPercentileRanks
GO

-- Remove unused functions introduced in 6027

IF NOT OBJECT_ID('StudyCaseAtCenterNow' ) IS NULL 
  DROP FUNCTION dbo.StudyCaseAtCenterNow
GO 

IF NOT OBJECT_ID('StudyCaseAtCenterBefore' ) IS NULL 
  DROP FUNCTION dbo.StudyCaseAtCenterBefore
GO 

IF NOT OBJECT_ID('StudyCaseAtCenterEver' ) IS NULL 
  DROP FUNCTION dbo.StudyCaseAtCenterEver
GO

-- Remove procedure from 518, not used in version 6

IF NOT OBJECT_ID('[Report].[GetClassifiedLabdata]') IS NULL
   DROP PROCEDURE Report.GetClassifiedLabdata
GO

IF NOT OBJECT_ID('[Report].[GetStudyVariables]') IS NULL
   DROP PROCEDURE Report.GetStudyVariables
GO

-- Remove some unused procedures

IF NOT OBJECT_ID('[GBD].[GetCaseListDiedHere]') IS NULL
  DROP PROCEDURE GBD.GetCaseListDiedHere
GO

IF NOT OBJECT_ID('AddDiabetesPatientsToNdv') IS NULL
  DROP PROCEDURE dbo.AddDiabetesPatientsToNdv
GO

IF NOT OBJECT_ID('GetDrugTextSuggestions') IS NULL
  DROP PROCEDURE dbo.GetDrugTextSuggestions
GO

-- Remove unused synonym

IF EXISTS( SELECT * FROM sys.synonyms  WHERE name='PatientWard' )
  DROP SYNONYM PatientWard
GO


-- Remove some unused procedures, moved to GBD schema (rules)

IF NOT OBJECT_ID('RuleMust' ) IS NULL 
  DROP PROCEDURE dbo.RuleMust
GO

IF NOT OBJECT_ID('GetCaseListMUST' ) IS NULL 
  DROP PROCEDURE dbo.GetCaseListMUST
GO

IF NOT OBJECT_ID('UpdateMustScoreForAll' ) IS NULL 
  DROP PROCEDURE dbo.UpdateMustScoreForAll
GO

IF NOT OBJECT_ID('dbo.SignClinFormItems' ) IS NULL DROP PROCEDURE dbo.SignClinFormItems
GO

ALTER FUNCTION dbo.GetLastQuantity( @PersonId INT, @VarName VARCHAR(64) ) RETURNS DECIMAL(18,4)
AS
BEGIN
 DECLARE @RetVal DECIMAL(18,4);
 SET @RetVal = ( SELECT TOP 1 cd.Quantity FROM dbo.ClinDatapoint cd 
   JOIN dbo.MetaItem mi ON mi.ItemId=cd.ItemId
   JOIN dbo.ClinEvent ce ON ce.EventId=cd.EventId 
   WHERE ( ce.PersonId=@PersonId ) AND ( mi.VarName=@VarName ) AND ISNULL(cd.Quantity,-1)>=0 
   ORDER BY ce.EventNum DESC );
 RETURN @RetVal;
END
GO

ALTER FUNCTION dbo.GetLastEnumVal( @PersonId INT, @VarName VARCHAR(64) ) RETURNS INT
AS
BEGIN
 DECLARE @RetVal INT;
 SET @RetVal = ( SELECT TOP 1 cd.EnumVal FROM dbo.ClinDatapoint cd 
   JOIN dbo.MetaItem mi ON mi.ItemId=cd.ItemId
   JOIN dbo.ClinEvent ce ON ce.EventId=cd.EventId 
   WHERE ( ce.PersonId=@PersonId ) AND ( mi.VarName=@VarName ) AND ISNULL(cd.EnumVal,-1) >= 0 
   ORDER BY ce.EventNum DESC );
   RETURN @RetVal;
END
GO

ALTER FUNCTION dbo.GetLastEnumValInThePast( @PersonId INT, @VarName VARCHAR(64), @Cutoff DateTime ) RETURNS INT
AS
BEGIN
 DECLARE @RetVal INT;
 SET @RetVal = ( SELECT TOP 1 cd.EnumVal FROM dbo.ClinDatapoint cd
   JOIN dbo.MetaItem mi ON mi.ItemId=cd.ItemId
   JOIN dbo.ClinEvent ce ON ce.EventId=cd.EventId
   WHERE ( ce.PersonId=@PersonId ) AND ( mi.VarName=@VarName ) AND ISNULL(cd.EnumVal,-1) >= 0
   AND ( ce.EventTime < @Cutoff )
   ORDER BY ce.EventNum DESC );
   RETURN @RetVal;
END
GO

ALTER FUNCTION dbo.GetLastTextVal( @PersonId INT, @VarName VARCHAR(64) ) RETURNS VARCHAR(MAX)
AS
BEGIN
 DECLARE @RetVal VARCHAR(MAX);
 SET @RetVal = ( SELECT TOP 1 cd.TextVal FROM dbo.ClinDatapoint cd 
   JOIN dbo.MetaItem mi ON mi.ItemId=cd.ItemId
   JOIN dbo.ClinEvent ce ON ce.EventId=cd.EventId 
   WHERE ( ce.PersonId=@PersonId ) AND ( mi.VarName=@VarName ) AND DATALENGTH(cd.TextVal) > 0 
   ORDER BY ce.EventNum DESC );
 RETURN @RetVal;
END
GO

ALTER FUNCTION dbo.GetLastDTVal( @PersonId INT, @VarName VARCHAR(64) ) RETURNS DateTime
AS
BEGIN
 DECLARE @RetVal DateTime;
 SET @RetVal = ( SELECT TOP 1 cd.DTVal FROM dbo.ClinDatapoint cd 
   JOIN dbo.MetaItem mi ON mi.ItemId=cd.ItemId
   JOIN dbo.ClinEvent ce ON ce.EventId=cd.EventId 
   WHERE ( ce.PersonId=@PersonId ) AND ( mi.VarName=@VarName ) AND ( NOT cd.DTVal IS NULL) 
   ORDER BY ce.EventNum DESC );
 RETURN @RetVal;
END
GO

ALTER FUNCTION dbo.GetLastValue( @PersonId INT, @VarName VARCHAR(64) ) RETURNS DECIMAL(18,4)
AS
BEGIN
  DECLARE @RetVal DECIMAL(18,4);
  SET @RetVal = ( SELECT TOP 1 a.Quantity FROM   
  (  
  SELECT ce.EventTime,cd.Quantity 
    FROM dbo.ClinEvent ce 
    JOIN dbo.ClinDatapoint cd ON cd.EventId=ce.EventId
    JOIN dbo.MetaItem mi ON mi.ItemId=cd.ItemId
    WHERE ( ce.PersonId=@PersonId ) AND ( mi.VarName=@VarName ) AND ( cd.Quantity >= 0 )
  UNION
    SELECT ld.LabDate,ld.NumResult 
    FROM dbo.LabData ld
    JOIN dbo.LabCode lc ON lc.LabCodeId=ld.LabCodeId
    WHERE ( ld.PersonId=@PersonId ) AND ( lc.VarName=@VarName ) AND ( ld.NumResult >= 0 ) 
  ) a ORDER BY a.EventTime DESC ); 
  RETURN @RetVal;
END
GO

COMMIT TRANSACTION UpgradeTo6042;
GO

EXECUTE dbo.DbFinalizeUpgrade 6042;
GO

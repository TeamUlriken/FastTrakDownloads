SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6008
PRINT 'Starting upgrade to 6008'

DELETE FROM DbUpgradeLog WHERE DbVer > 6007;

EXEC DbCheckVersion 6007;
EXECUTE DbStartUpgrade 6008;
GO

ALTER VIEW NDV.LabData  
AS
  SELECT 1 AS Tag, NULL AS Parent,
    p.NationalId AS [labtest!1!pasientid],
    NULL AS [variabel!2!loinc],
    NULL AS [variabel!2!navn],
    NULL AS [variabel!2!komparator],
    NULL AS [variabel!2!original],
    NULL AS [variabel!2!verdi!element],
    NULL AS [variabel!2!enhet!element],
    NULL AS [variabel!2!tekst!element],
    NULL AS [variabel!2!analysedato!element] 
  FROM dbo.Person p JOIN dbo.StudCase sc ON sc.PersonId=p.PersonId AND sc.MarkedForExport=1 
    JOIN dbo.Study s ON s.StudyId=sc.StudyId 
  UNION ALL
  SELECT 2 AS Tag, 1 AS Parent,p.NationalId,lc.LoincCode,lc.VarName,ld.ArithmeticComp,lc.LabName,ld.NumResult,NULLIF(ld.UnitStr,''), NULLIF(ld.TxtResult,''),ld.LabDate 
    FROM dbo.LabData ld 
    JOIN dbo.Person p ON p.personId=ld.PersonId 
    JOIN dbo.LabCode lc ON lc.LabCodeId=ld.LabCodeId
	JOIN dbo.StudCase sc ON sc.PersonId=p.PersonId AND sc.MarkedForExport=1 JOIN Study s ON s.StudyId=sc.StudyId 
  WHERE  lc.VarName IN ( 'HBA1C','CREAT','UACR','CHOL','LDL','HDL','TRIG','UMALB','UALB','UPROT24' );
GO


EXECUTE DbFinalizeUpgrade 6008;
GO

COMMIT TRANSACTION UpgradeTo6008;
GO

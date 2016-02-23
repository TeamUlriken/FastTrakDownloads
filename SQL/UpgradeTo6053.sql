BEGIN TRANSACTION UpgradeTo6053
PRINT 'Starting upgrade to 6053'

DELETE FROM DbUpgradeLog WHERE DbVer > 6052;

EXEC DbCheckVersion 6052;
EXECUTE DbStartUpgrade 6053;
GO

IF object_id('Report.QuickStat') IS NULL
BEGIN

  CREATE TABLE Report.QuickStat(
    RowId INTEGER IDENTITY (1, 1) NOT NULL,
    StudyId INT,
    ProcId INT,
    Title VARCHAR(80),
    DataElements VARCHAR(MAX),
    Comment VARCHAR(MAX),
    CONSTRAINT PK_ReportQuickStat PRIMARY KEY (RowId))
    
  ALTER TABLE Report.QuickStat ADD CONSTRAINT FK_QuickStat_Study FOREIGN KEY (StudyId) REFERENCES dbo.Study (StudyId)
  CREATE UNIQUE INDEX IDX_Report_StudyTitle ON Report.QuickStat (StudyId, Title)
  
END
GO

IF NOT object_id('Report.AddQuickStat') IS NULL
  DROP PROCEDURE Report.AddQuickStat
IF NOT object_id('Report.SaveQuickStat') IS NULL
  DROP PROCEDURE Report.SaveQuickStat
GO

CREATE PROCEDURE Report.AddQuickStat(@StudyId INT, @ProcId INT, @Title VARCHAR(80), @DataElements VARCHAR(MAX), @Comment VARCHAR(MAX))
AS
BEGIN
  DECLARE @RowId INT;
  SELECT @RowId = RowId
  FROM Report.QuickStat
  WHERE StudyId = @StudyId
    AND Title = @Title;
  IF @RowId IS NULL
  BEGIN
    INSERT INTO Report.QuickStat(StudyId, ProcId, Title, DataElements, Comment) VALUES (@StudyId, @ProcId, @Title, @DataElements, @Comment)
    SET @RowId = scope_identity();
  END
  ELSE
    UPDATE Report.QuickStat SET ProcId = @ProcId, DataElements = @DataElements, Comment = @Comment
    WHERE RowId = @RowId;
  SELECT @RowId AS RowId;
END
GO

GRANT EXECUTE ON Report.AddQuickStat TO [superuser] as [dbo]
GO

IF NOT object_id('Report.ColumnCaption') IS NULL
  DROP TABLE Report.ColumnCaption
GO

CREATE TABLE Report.ColumnCaption(
  CaptionId INT,
  VarSpec VARCHAR(64),
  Caption VARCHAR(8),
  ColWidth INTEGER)
GO


IF NOT object_id('Report.AddVarCaption') IS NULL
  DROP PROCEDURE Report.AddVarCaption
GO

CREATE PROCEDURE Report.AddVarCaption(@VarSpec VARCHAR(60), @Caption VARCHAR(8))
AS
BEGIN
  DECLARE @CaptionId INT;
  SELECT @CaptionId = CaptionId
  FROM Report.ColumnCaption
  WHERE VarSpec = @VarSpec;
  IF @CaptionId IS NULL
  BEGIN
    SELECT @CaptionId = isnull(max(CaptionId), 1)
    FROM Report.ColumnCaption;
    SET @CaptionId = @CaptionId + 1;
    INSERT INTO Report.ColumnCaption(CaptionId, VarSpec, Caption) VALUES (@CaptionId, @VarSpec, @Caption);
  END
  ELSE
    UPDATE Report.ColumnCaption SET Caption = @Caption
    WHERE CaptionId = @CaptionId;
END
GO

GRANT EXECUTE ON Report.AddVarCaption TO [superuser] AS [dbo]
GO

-- Patient data
EXEC Report.AddVarCaption 'PATIENT.AGE', 'Alder'
-- Lipider 
EXEC Report.AddVarCaption 'LAB.CHOL', 'Kol'
EXEC Report.AddVarCaption 'LAB.LDL', 'LDL'
EXEC Report.AddVarCaption 'LAB.HDL', 'HDL'
EXEC Report.AddVarCaption 'LAB.TRIG', 'TG'
-- Jernstatus 
EXEC Report.AddVarCaption 'LAB.S_FERRITIN', 'Ferritin'
EXEC Report.AddVarCaption 'LAB.S_TIBC', 'TIBC'
EXEC Report.AddVarCaption 'LAB.S_JERNMETNING', 'JernMetn'
EXEC Report.AddVarCaption 'LAB.S_FE_ION', 'Jern'
-- Annet 
EXEC Report.AddVarCaption 'LAB.S_METYLMALONAT', 'MMA'
EXEC Report.AddVarCaption 'LAB.S_HOMOCYSTEINE', 'HCY'
-- Antistoffer 
EXEC Report.AddVarCaption 'LAB.S_IGA', 'IGA'
EXEC Report.AddVarCaption 'LAB.S_IGM', 'IGM'
EXEC Report.AddVarCaption 'LAB.S_IGG', 'IGG'
EXEC Report.AddVarCaption 'LAB.S_IGE', 'IGE'
-- Thyroidea 
EXEC Report.AddVarCaption 'LAB.S_FT4', 'FT4'
EXEC Report.AddVarCaption 'LAB.S_FT3', 'FT3'
EXEC Report.AddVarCaption 'LAB.S_T4', 'T4'
EXEC Report.AddVarCaption 'LAB.S_T3', 'T3'
EXEC Report.AddVarCaption 'LAB.S_TSH', 'TSH'
EXEC Report.AddVarCaption 'LAB.S_TPO_AS', 'TPO'
EXEC Report.AddVarCaption 'LAB.S_TRAS', 'TRAS'
-- Hormoner 
EXEC Report.AddVarCaption 'LAB.S_SHBG', 'SHBG'
EXEC Report.AddVarCaption 'LAB.S_FSH', 'FSH'
EXEC Report.AddVarCaption 'LAB.S_LH', 'LH'
-- Elektrolytter 
EXEC Report.AddVarCaption 'LAB.S_NA_ION', 'Natr'
EXEC Report.AddVarCaption 'LAB.S_CL_ION', 'Klor'
EXEC Report.AddVarCaption 'LAB.S_CA_ION', 'Ca'
EXEC Report.AddVarCaption 'LAB.S_K_ION', 'Kalium'
EXEC Report.AddVarCaption 'LAB.S_MG_ION', 'Mg'
EXEC Report.AddVarCaption 'LAB.S_PHOSPHATE', 'Fosfat'
-- Nyrefunksjon 
EXEC Report.AddVarCaption 'LAB.GFR_ESTIMATED', 'eGFR'
EXEC Report.AddVarCaption 'LAB.URATE', 'Urat'
EXEC Report.AddVarCaption 'LAB.S_UREA', 'Urea'
EXEC Report.AddVarCaption 'LAB.CREAT', 'Kreat'
EXEC Report.AddVarCaption 'LAB.UACR', 'ACR'
EXEC Report.AddVarCaption 'LAB.UMALB', 'MicAlb'
-- Cancer 
EXEC Report.AddVarCaption 'LAB.PSA', 'PSA'
EXEC Report.AddVarCaption 'LAB.INR', 'INR'
EXEC Report.AddVarCaption 'LAB.ProBNP', 'proBNP'
-- Vitaminer 
EXEC Report.AddVarCaption 'LAB.S_B12', 'B12'
EXEC Report.AddVarCaption 'LAB.S_FOLAT', 'Folat'
-- Leverprøver 
EXEC Report.AddVarCaption 'LAB.ANTI_HIV', 'HIV'
EXEC Report.AddVarCaption 'LAB.S_BILIRUBIN', 'ALP'
EXEC Report.AddVarCaption 'LAB.ALP', 'ALP'
EXEC Report.AddVarCaption 'LAB.GT', 'GGT'
EXEC Report.AddVarCaption 'LAB.CK', 'CK'
EXEC Report.AddVarCaption 'LAB.S_CK_MB', 'CKMB'
EXEC Report.AddVarCaption 'LAB.S_LD', 'LD'
EXEC Report.AddVarCaption 'LAB.S_CK', 'CK'
EXEC Report.AddVarCaption 'LAB.ALAT', 'ALAT'
EXEC Report.AddVarCaption 'LAB.ASAT', 'ASAT'
EXEC Report.AddVarCaption 'LAB.S_AMYLASE', 'Amylase'
-- Autoimmunitet 
EXEC Report.AddVarCaption 'LAB.S_ANA', 'ANA'
-- Hematologi 
EXEC Report.AddVarCaption 'LAB.B_HGB', 'Hb'
EXEC Report.AddVarCaption 'LAB.ESR', 'SR'
EXEC Report.AddVarCaption 'LAB.B_EVF', 'EVF'
EXEC Report.AddVarCaption 'LAB.B_MCV', 'MCV'
EXEC Report.AddVarCaption 'LAB.B_MCH', 'MCH'
EXEC Report.AddVarCaption 'LAB.B_MCHC', 'MCHC'
EXEC Report.AddVarCaption 'LAB.RBC', 'EPK'
EXEC Report.AddVarCaption 'LAB.B_TPC', 'TPK'
EXEC Report.AddVarCaption 'LAB.WBC', 'LPK'
-- Glukose 
EXEC Report.AddVarCaption 'LAB.HBA1C', 'HBA1c'
EXEC Report.AddVarCaption 'LAB.INSULINE', 'Insulin'
EXEC Report.AddVarCaption 'LAB.INSULINE_C_PEPTIDE', 'CPeptid'
EXEC Report.AddVarCaption 'LAB.SP_GLUCOSE_RANDOM', 'Glukose'
-- Antropometrics 
EXEC Report.AddVarCaption 'ITEM.SBP_UNSPEC', 'SysBT'
EXEC Report.AddVarCaption 'ITEM.DBP_UNSPEC', 'DiaBT'
EXEC Report.AddVarCaption 'ITEM.WEIGHT', 'Vekt'
EXEC Report.AddVarCaption 'ITEM.HEIGHT', 'Høyde'
EXEC Report.AddVarCaption 'ITEM.BMI', 'BMI'
-- Annet 
EXEC Report.AddVarCaption 'LAB.CRP', 'CRP'
EXEC Report.AddVarCaption 'LAB.S_TOTALPROT', 'Prot'
EXEC Report.AddVarCaption 'LAB.S_ALBUMIN', 'Albu'
EXEC Report.AddVarCaption 'LAB.WEIGHT', 'Vekt'
-- Diabetes registry 
EXEC Report.AddVarCaption 'ITEM.NDV_CONSENT', 'Samt'
EXEC Report.AddVarCaption 'ITEM.NDV_TYPE', 'Type'
EXEC Report.AddVarCaption 'ITEM.NDV_DIAGNOSE_YYYY', 'Debut'
EXEC Report.AddVarCaption 'ITEM.NDV_SMOKING', 'Debut'
GO

IF NOT object_id('Report.GetColumnCaptions') IS NULL
  DROP PROCEDURE Report.GetColumnCaptions
GO

CREATE PROCEDURE Report.GetColumnCaptions
AS
BEGIN
  SELECT VarSpec, Caption, isnull(ColWidth, 100) AS ColWidth
  FROM Report.ColumnCaption
END

GRANT EXECUTE ON Report.GetColumnCaptions TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('Report.GetFormData') IS NULL DROP PROCEDURE Report.GetFormData
GO

CREATE PROCEDURE Report.GetFormData( @PersonId INT, @FormName VARCHAR(32) ) AS
BEGIN
  SELECT DISTINCT ce.PersonId,mi.VarName,dp.Quantity,ce.EventTime,dp.RowId
  FROM dbo.ClinDatapoint dp 
  JOIN dbo.ClinEvent ce ON ce.EventId = dp.EventId
  JOIN dbo.ClinForm cf ON cf.EventId = ce.EventId
  JOIN dbo.MetaItem mi ON mi.ItemId=dp.ItemId
  JOIN dbo.MetaFormItem mfi ON mfi.FormId=cf.FormId AND mfi.ItemId=mi.ItemId
  JOIN dbo.MetaForm mf ON mf.FormId=mfi.FormId 
  WHERE mf.FormName=@FormName AND ce.PersonId=@PersonId
  ORDER BY dp.RowId
END
GO

GRANT EXECUTE ON Report.GetFormData to [superuser] AS [dbo]
GO

IF NOT OBJECT_ID('Report.GetFormInstances') IS NULL DROP PROCEDURE Report.GetFormInstances
GO

CREATE PROCEDURE Report.GetFormInstances( @PersonId INT ) AS
BEGIN
  SELECT ce.PersonId,mf.FormName,COUNT(cf.ClinFormId) as FormCount,MAX(cf.CreatedAt) AS LastForm,MAX(cf.FormId) as LastFormId
  FROM dbo.ClinForm cf JOIN dbo.MetaForm mf ON mf.FormId=cf.FormId     
  JOIN dbo.ClinEvent ce ON ce.EventId=cf.EventId 
  WHERE ce.PersonId=@PersonId
  GROUP BY ce.PersonId,mf.FormName;
END
GO

GRANT EXECUTE ON Report.GetFormInstances to [superuser] AS [dbo]
GO

IF NOT OBJECT_ID('Report.GetFormClasses') IS NULL DROP PROCEDURE Report.GetFormClasses
GO

CREATE PROCEDURE Report.GetFormClasses( @StudyId INT ) AS
BEGIN
  SELECT DISTINCT mf.FormName,msf.FormTitle 
  FROM dbo.MetaForm mf JOIN dbo.MetaStudyForm msf ON msf.FormId=mf.FormId 
  WHERE NOT FormName LIKE 'FORM%'
  AND msf.StudyId=@StudyId;
END
GO

GRANT EXECUTE ON Report.GetFormClasses TO [superuser] AS [dbo]
GO

IF NOT OBJECT_ID('Report.GetLabData') IS NULL DROP PROCEDURE Report.GetLabData
GO

CREATE PROCEDURE Report.GetLabData ( @PersonId INT ) AS
BEGIN
  SELECT ld.PersonId,ISNULL(lc.VarName,'ANNET') as VarName,ld.NumResult,ld.LabDate,ld.ResultId
  FROM dbo.LabData ld
    JOIN dbo.LabCode lc on lc.LabCodeId=ld.LabCodeId
  WHERE ld.PersonId=@PersonId 
  ORDER BY ld.LabDate
END
GO

GRANT EXECUTE ON Report.GetLabData to [superuser] AS [dbo]
GO

IF OBJECT_ID('Report.Selection') IS NULL 
BEGIN
 
  CREATE TABLE Report.Selection ( 
    SelId INTEGER IDENTITY(1,1) NOT NULL, 
    StudyId INT NOT NULL, 
    SelTitle VARCHAR(80) NOT NULL,
    SelDescription VARCHAR(MAX) NULL,
    CreatedAt DateTime NOT NULL DEFAULT getdate(),
    CreatedBy INT NOT NULL DEFAULT USER_ID() )

  ALTER TABLE Report.Selection ADD CONSTRAINT PK_ReportSelection PRIMARY KEY( SelId )

  ALTER TABLE Report.Selection ADD CONSTRAINT FK_ReportSelection_Study FOREIGN KEY( StudyId ) 
    REFERENCES dbo.Study( StudyId )

  CREATE UNIQUE INDEX IDX_ReportSelection_StudyTitle ON Report.Selection(StudyId,CreatedBy,SelTitle)

END
GO

IF NOT OBJECT_ID('Report.AddSelection') IS NULL DROP PROCEDURE Report.AddSelection
GO

CREATE PROCEDURE Report.AddSelection( @StudyId INT, @SelTitle VARCHAR(80), @SelDescription VARCHAR(MAX) ) 
AS
BEGIN
  INSERT INTO Report.Selection( StudyId, SelTitle, SelDescription ) VALUES( @StudyId, @SelTitle, @SelDescription );
  SELECT SCOPE_IDENTITY() AS SelId;
END
GO

GRANT EXECUTE ON Report.AddSelection TO [superuser] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6053;
GO

COMMIT TRANSACTION UpgradeTo6053;
GO



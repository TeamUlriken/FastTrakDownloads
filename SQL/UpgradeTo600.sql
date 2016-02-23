SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo600;
PRINT 'Starting upgrade to 600'

DELETE FROM DbUpgradeLog WHERE DbVer > 540;

EXEC DbCheckVersion 540;       
EXECUTE DbStartUpgrade 600;
GO

ALTER PROCEDURE dbo.AddSchema( @SchemaName NVARCHAR(16) )
AS
BEGIN
  DECLARE @SqlString NVARCHAR(64);
  IF SCHEMA_ID(@SchemaName) IS NULL
  BEGIN
    SET @SqlString = 'CREATE SCHEMA ' + @SchemaName + ' AUTHORIZATION dbo';
    EXEC sp_executesql @SqlString;
  END
END
GO

EXEC AddSchema 'ENDO'
GO

IF NOT OBJECT_ID('DSSRuleError') IS NULL DROP TABLE dbo.DSSRuleError
GO

CREATE TABLE dbo.DSSRuleError( RowId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, 
  StudyId INT, PersonId INT, RuleProc NVARCHAR(128),
  ErrorNumber INT, ErrorSeverity INT, ErrorLine INT, ErrorMessage NTEXT, CreatedAt DateTime NOT NULL, CreatedBy INT NOT NULL )
GO

ALTER TABLE dbo.DSSRuleError
 ADD CONSTRAINT DF_DSSRuleError_CreatedAt DEFAULT getdate() FOR CreatedAt
 , CONSTRAINT DF_DSSRuleError_CreatedBy DEFAULT user_id() FOR CreatedBy
 , CONSTRAINT FK_DSSRuleError_StudyId FOREIGN KEY (StudyId) REFERENCES dbo.Study(StudyId)
 , CONSTRAINT FK_DSSRuleError_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.UserList(UserId)
GO

ALTER PROCEDURE dbo.UpdateDSSAlerts( @StudyId INT, @PersonId INT )
AS
BEGIN
  DECLARE @RuleProc nvarchar(128);
  DECLARE @StartTime DateTime;
  DECLARE @CallTime DateTime;
  DECLARE @StudyRuleId INT;
  UPDATE StudCase SET LastRuleExecute=GetDate() WHERE StudyId=@StudyId AND PersonId=@PersonId;
  SET @CallTime = GetDate();
  DECLARE rule_list CURSOR FOR
    SELECT sr.StudyRuleId,RuleProc FROM DSSRule r
     JOIN DSSStudyRule sr ON sr.RuleId=r.RuleId
     JOIN Study s ON s.StudyName=sr.StudyName
     WHERE s.StudyId=@StudyId AND sr.RuleActive=1;
  OPEN rule_list;
  FETCH NEXT FROM rule_list INTO @StudyRuleId,@RuleProc
  WHILE @@FETCH_STATUS = 0 BEGIN
    SET @StartTime = GetDate();       
    BEGIN TRY
    EXEC @RuleProc @StudyId,@PersonId;
    INSERT INTO DSSRuleExecute (PersonId,StudyRuleId,MsElapsed)
      VALUES (@PersonId,@StudyRuleId,DATEDIFF(ms,@StartTime,GetDate()) )
    END TRY
    BEGIN CATCH  
      INSERT INTO dbo.DSSRuleError (StudyId,PersonId,RuleProc,ErrorNumber,ErrorSeverity,ErrorLine,ErrorMessage) 
      VALUES (@StudyId,@PersonId,@RuleProc,ERROR_NUMBER(),ERROR_SEVERITY(),ERROR_LINE(),ERROR_MESSAGE())
    END CATCH
    FETCH NEXT FROM rule_list INTO @StudyRuleId,@RuleProc;
  END;
  CLOSE rule_list;
  DEALLOCATE rule_list;
END
GO

IF NOT object_id('dbo.DbViewExists') IS NULL
  DROP FUNCTION dbo.DbViewExists
GO

CREATE FUNCTION dbo.DbViewExists(@SchemaName SYSNAME, @ViewName SYSNAME)
RETURNS TINYINT
AS
BEGIN
  DECLARE @RetVal TINYINT
  SELECT @RetVal = count(*)
  FROM INFORMATION_SCHEMA.VIEWS
  WHERE table_name = @ViewName
    AND table_schema = @SchemaName
  RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.DbViewExists TO [public] AS [dbo]
GO

TRUNCATE TABLE dbo.MetaItemAnswer
GO

ALTER TABLE dbo.MetaItemAnswer DROP CONSTRAINT PK_MetaItemAnswer
GO

ALTER TABLE dbo.MetaItemAnswer DROP COLUMN AnswerId
GO

ALTER TABLE dbo.MetaItemAnswer ADD AnswerId INT NOT NULL
GO

ALTER TABLE dbo.MetaItemAnswer ADD CONSTRAINT PK_MetaItemAnswer PRIMARY KEY(AnswerId)
GO
    
TRUNCATE TABLE dbo.MetaStudyForm
GO

ALTER TABLE dbo.MetaStudyForm DROP CONSTRAINT PK_MetaStudyForm
GO

ALTER TABLE dbo.MetaStudyForm DROP COLUMN StudyFormId
GO

ALTER TABLE dbo.MetaStudyForm ADD StudyFormId INT NOT NULL
GO

ALTER TABLE dbo.MetaStudyForm ADD CONSTRAINT PK_MetaStudyForm PRIMARY KEY(StudyFormId)
GO

-- Add subtitle column to MetaForm

IF dbo.DbColumnExists( 'MetaForm', 'Subtitle') = 0 
  ALTER TABLE dbo.MetaForm ADD Subtitle VARCHAR(MAX)
GO

-- Add shortcode and to MetaItemAnswer

IF dbo.DbColumnExists( 'MetaItemAnswer', 'ShortCode' ) = 0
  ALTER TABLE MetaItemAnswer ADD ShortCode VARCHAR(5)
GO

IF dbo.DbColumnExists( 'MetaItemAnswer', 'ICD10' ) = 0 
  ALTER TABLE dbo.MetaItemAnswer ADD ICD10 VARCHAR(16)
GO

-- Add Exclude Caption to MetaFormItem

IF dbo.DbColumnExists( 'MetaFormItem', 'ExcludeCaption' ) = 0
  ALTER TABLE MetaFormItem ADD ExcludeCaption BIT
GO

-- Add more CAVE fields

IF dbo.DbColumnExists( 'Person','NB') = 0
  ALTER TABLE dbo.Person ADD NB VARCHAR(MAX)
GO

IF dbo.DbColumnExists( 'Person','Reservations') = 0
  ALTER TABLE dbo.Person ADD Reservations VARCHAR(MAX)
GO

IF dbo.DbColumnExists( 'Person','Allergies') = 0
  ALTER TABLE dbo.Person ADD Allergies VARCHAR(MAX)
GO

ALTER PROCEDURE dbo.GetCAVE( @PersonId INT )
AS
BEGIN
  SELECT CAVE,NB,Reservations,Allergies FROM dbo.Person WHERE PersonId=@PersonId
END
GO

-- Add possibility to hide comments

IF dbo.DbColumnExists( 'MetaStudyForm', 'HideComment' ) = 0
  ALTER TABLE dbo.MetaStudyForm ADD HideComment TINYINT
GO

UPDATE MetaStudyForm SET HideComment = 1 WHERE FormId IN (379 )
GO

UPDATE MetaStudyForm SET HideComment = 2 WHERE FormId IN (667, 666, 689 )
GO

EXEC AddSchema 'CRF'
GO

IF dbo.DbColumnExists( 'ClinProblem', 'FamilyStatus') = 0
  ALTER TABLE ClinProblem ADD FamilyStatus CHAR(1)
GO 

ALTER PROCEDURE dbo.GetClinProblems( @PersonId INT ) AS
BEGIN
 SELECT cp.ProbId,mi.ItemCode,mi.ItemName,cp.ProbType,cp.ProbSummary,cp.CreatedAt,cp.ProbDebut,cp.Priority,ml.DxSystem,cp.FamilyStatus
   FROM dbo.ClinProblem cp
   JOIN dbo.MetaNomListItem mli ON mli.ListItem=cp.ListItem
   JOIN dbo.MetaNomList ml ON ml.ListId=mli.ListId
   JOIN dbo.MetaNomItem mi on mi.ItemId=mli.ItemId
 WHERE cp.PersonId=@PersonId;
END
GO

ALTER TABLE dbo.MetaItemAnswer ALTER COLUMN ShortCode VARCHAR(5)
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'PageNo') = 1
  ALTER TABLE MetaFormItem DROP COLUMN PageNo
GO 

IF NOT OBJECT_ID('FK_MetaFormItem_PageId') IS NULL
  ALTER TABLE MetaFormItem DROP CONSTRAINT FK_MetaFormItem_PageId
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'PageId') = 1
  ALTER TABLE MetaFormItem DROP COLUMN PageId
GO 


IF dbo.DbViewExists( 'Meta', 'StudyForm' ) = 1
  DROP VIEW Meta.StudyForm
GO

ALTER TABLE dbo.MetaForm ALTER COLUMN Repeatable BIT NULL
GO

CREATE VIEW Meta.StudyForm  
WITH SCHEMABINDING
AS
SELECT msf.StudyId,mf.FormId,mf.FormName,mf.FormTitle,mf.Subtitle,
  mf.CalculateInvalid, mf.RatingScale, mf.Copyright,
  mf.ThreadTypeId, mf.Instructions, 
  ISNULL(msf.Repeatable,mf.Repeatable) as Repeatable,
  ISNULL(msf.SurveyStatus,mf.SurveyStatus) AS SurveyStatus, 
  ISNULL(msf.FormActive,mf.FormActive ) AS FormActive,
  msf.ParentId, msf.CreatedAt,msf.CreatedBy
  FROM dbo.MetaForm mf JOIN dbo.MetaStudyForm msf ON msf.FormId=mf.FormId
GO

-- Add Guid field to Alert

IF dbo.DbColumnExists( 'Alert','guid') = 0 
  ALTER TABLE Alert ADD guid uniqueidentifier NOT NULL DEFAULT newid()
GO

EXEC dbo.UtilRenameDefault 'dbo.Alert','guid'
GO

IF NOT OBJECT_ID('AddAlert') IS NULL DROP PROCEDURE dbo.AddAlert
GO

CREATE PROCEDURE dbo.AddAlert( @StudyId INT, @PersonId INT, @AlertLevel INT, @AlertClass varchar(12),
 @AlertFacet varchar(16), @AlertHeader varchar(64), @AlertMessage varchar(512), @HideUntil DateTime )
AS
BEGIN
  INSERT INTO Alert (StudyId,PersonId,AlertLevel,AlertClass,AlertFacet,AlertHeader,AlertMessage,HideUntil,AlertButtons)
    VALUES ( @StudyId,@PersonId,@AlertLevel,@AlertClass,@AlertFacet,@AlertHeader,@AlertMessage,@HideUntil,'*');
  SELECT SCOPE_IDENTITY() AS AlertId;
END
GO

GRANT EXECUTE ON dbo.AddAlert TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('DF_MetaForm_Repeatable') IS NULL
  ALTER TABLE dbo.MetaForm DROP CONSTRAINT DF_MetaForm_Repeatable
GO

IF NOT OBJECT_ID('UpdateAlertResponse' ) IS NULL DROP PROCEDURE dbo.UpdateAlertResponse
GO

CREATE PROCEDURE dbo.UpdateAlertResponse( @AlertId INT, @HideUntil DateTime )
AS
BEGIN
 INSERT INTO AlertResponse (AlertId,ActionId,HideUntil) VALUES(@AlertId,'N',@HideUntil);
 UPDATE Alert SET HideUntil=@HideUntil WHERE AlertId=@AlertId;
END
GO

GRANT EXECUTE ON dbo.UpdateAlertResponse TO [public] AS [dbo]
GO

ALTER PROCEDURE dbo.GetDrugReactions( @PersonId INT )
AS
BEGIN
  SELECT DrId,DRDate,ATC,DrugName,DescriptiveText,Resolved,RiskScore,mr.*,ms.*,r.*
  FROM DrugReaction dr
    JOIN MetaSeverity ms on ms.SevId=dr.Severity
    JOIN MetaRelatedness mr ON mr.RelId=dr.Relatedness
    JOIN MetaResolution r ON r.ResId=dr.Resolved
  WHERE PersonId=@PersonId AND DeletedAt IS NULL AND mr.RelId > 0;
END
GO

IF dbo.DbColumnExists( 'MetaItem', 'LabName' ) = 0
  ALTER TABLE dbo.MetaItem ADD LabName VARCHAR(40)
GO

IF NOT OBJECT_ID('GetStudyItems') IS NULL DROP PROCEDURE dbo.GetStudyItems
GO

CREATE PROCEDURE dbo.GetStudyItems( @StudyId INT ) AS
BEGIN
  SELECT DISTINCT mi.ItemId,mi.VarName,mi.ItemType,mi.UnitStr,mi.LabName,mi.ThreadTypeId 
    FROM MetaItem mi 
    JOIN MetaFormItem mfi ON mfi.ItemId=mi.ItemId 
	JOIN MetaStudyForm ms ON ms.FormId=mfi.FormId AND ms.StudyId=@StudyId
	ORDER BY mi.ItemId
END
GO

GRANT EXECUTE ON dbo.GetStudyItems TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('GetStudyAnswers') IS NULL 
  DROP PROCEDURE dbo.GetStudyAnswers
GO

CREATE PROCEDURE dbo.GetStudyAnswers( @StudyId INT ) AS
BEGIN
  SELECT DISTINCT mia.ItemId,mia.OrderNumber,mia.AnswerId,mia.OptionText, 
     mia.VerboseText,mia.ICD10, mia.Score, mia.ShortCode,mia.LastUpdate 
    FROM MetaItemAnswer mia 
    JOIN MetaFormItem mfi ON mfi.ItemId=mia.ItemId 
	JOIN MetaStudyForm ms ON ms.FormId=mfi.FormId AND ms.StudyId=@StudyId 
    ORDER BY mia.ItemId,mia.OrderNumber
END
GO

GRANT EXECUTE ON dbo.GetStudyAnswers TO [public] AS [dbo]
GO

ALTER VIEW dbo.ViewActiveCaseListStub (PersonId, DOB, FullName, StudyId, GroupName, GenderId ) 
AS
SELECT DISTINCT p.PersonId,p.DOB,p.ReverseName AS FullName,sc.StudyId,sg.GroupName,p.GenderId
  FROM Person p
  JOIN StudCase sc on sc.PersonId=p.PersonId
  JOIN StudyStatus ss on ss.StudyId=sc.StudyId and ss.StatusId=sc.FinState and ss.StatusActive=1
  JOIN StudyGroup sg ON sg.GroupId=sc.GroupId AND sg.StudyId=sc.StudyId AND sg.GroupActive=1
  JOIN UserList ul ON ul.CenterId=sg.CenterId AND ul.UserId=USER_ID()
  LEFT OUTER JOIN StudyUser su ON su.UserId=USER_ID() AND su.StudyId=sc.StudyId
  WHERE ( su.GroupId=sc.GroupId ) OR ( su.UserId IS NULL ) OR ( su.GroupId IS NULL ) OR ( su.ShowMyGroup = 0 )
GO

IF NOT OBJECT_ID('UtilResetUpdate') IS NULL DROP PROCEDURE dbo.UtilResetUpdate
GO

CREATE PROCEDURE dbo.UtilResetUpdate AS
BEGIN
  UPDATE MetaFormItem SET LastUpdate = '2000-01-01'
  UPDATE MetaForm SET LastUpdate = '2000-01-01'
  UPDATE MetaItemAnswer SET LastUpdate = '2000-01-01'
  UPDATE MetaItem SET LastUpdate = '2000-01-01'
END
GO

GRANT EXECUTE ON dbo.UtilResetUpdate TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('MetaFormAction') IS NULL DROP TABLE dbo.MetaFormAction
GO

CREATE TABLE dbo.MetaFormAction( OrderNumber INT NOT NULL, FormId INT NOT NULL, PageConditionId INT NOT NULL, MasterId INT NOT NULL, DetailId INT NOT NULL,
  ComparisonType INT, MasterEnumVal INT, LastUpdate DateTime NOT NULL )
GO

ALTER TABLE dbo.MetaFormAction ADD CONSTRAINT PK_MetaFormAction PRIMARY KEY(OrderNumber)
GO

ALTER TABLE dbo.MetaFormAction ADD CONSTRAINT FK_MetaFormAction_Form FOREIGN KEY (FormId) REFERENCES dbo.MetaForm(FormId)
GO

IF NOT OBJECT_ID('MetaFormPage') IS NULL DROP TABLE dbo.MetaFormPage
GO

CREATE TABLE dbo.MetaFormPage( PageId INT NOT NULL, FormId INT NOT NULL, PageNumber INT NOT NULL, PageTitle VARCHAR(MAX), PageIntroduction VARCHAR(MAX), LastUpdate DateTime NOT NULL,
  CONSTRAINT PK_MetaFormPage PRIMARY KEY CLUSTERED (PageId) )
GO

ALTER TABLE dbo.MetaFormPage ADD CONSTRAINT FK_MetaFormPage_FormId FOREIGN KEY (FormId) 
  REFERENCES dbo.MetaForm( FormId )
GO


-- Add missing columns to MetaItem table


IF dbo.DbColumnExists( 'MetaItem', 'Multiline') = 0 
  ALTER TABLE MetaItem ADD Multiline BIT
GO

--  Force update

TRUNCATE TABLE dbo.MetaFormItem
GO

--  Add missing columns to MetaFormItem table

ALTER TABLE dbo.MetaFormItem DROP CONSTRAINT  PK_MetaFormItem
GO

ALTER TABLE dbo.MetaFormItem DROP COLUMN FormItemId
GO

ALTER TABLE dbo.MetaFormItem ADD FormItemId INT NOT NULL
GO

ALTER TABLE dbo.MetaFormItem ADD CONSTRAINT PK_MetaFormItem PRIMARY KEY (FormItemId)
GO           

IF dbo.DbColumnExists( 'dbo.MetaFormItem', 'CarryForward') = 0 
  ALTER TABLE dbo.MetaFormItem ADD CarryForward TINYINT
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'ExcludeFromText') = 0 
  ALTER TABLE dbo.MetaFormItem ADD ExcludeFromText BIT
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'Optional') = 0 
  ALTER TABLE dbo.MetaFormItem ADD Optional BIT
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'ReadOnly') = 0 
  ALTER TABLE dbo.MetaFormItem ADD ReadOnly BIT
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'DefaultValue') = 0 
  ALTER TABLE dbo.MetaFormItem ADD DefaultValue VARCHAR(MAX)
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'Visibility') = 0 
  ALTER TABLE dbo.MetaFormItem ADD Visibility INT
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'PageId') = 0 
  ALTER TABLE dbo.MetaFormItem ADD PageId INT
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'PageNumber') = 0 
  ALTER TABLE dbo.MetaFormItem ADD PageNumber INT NULL
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'LastUpdate') = 0 
  ALTER TABLE dbo.MetaFormItem ADD LastUpdate DateTime
GO

UPDATE dbo.MetaFormItem SET LastUpdate = '2000-01-01' WHERE LastUpdate IS NULL
GO

ALTER TABLE dbo.MetaFormItem ADD CONSTRAINT FK_MetaFormItem_PageId FOREIGN KEY (PageId) 
  REFERENCES dbo.MetaFormPage(PageId)
GO

ALTER TABLE dbo.MetaFormItem ALTER COLUMN ItemHeader VARCHAR(80)
GO


IF NOT OBJECT_ID('dbo.GetStudyForm' ) IS NULL DROP PROCEDURE dbo.GetStudyForm
IF NOT OBJECT_ID('CRF.GetForm' ) IS NULL DROP PROCEDURE CRF.GetForm
IF NOT OBJECT_ID('Meta.GetForm' ) IS NULL DROP PROCEDURE Meta.GetForm
GO

CREATE PROCEDURE CRF.GetForm( @FormId INT ) AS
BEGIN 
  SELECT msf.StudyId,mf.FormId,mf.FormName,mf.FormTitle,mf.Subtitle,
    mf.CalculateInvalid, mf.RatingScale, mf.Copyright,
    mf.ThreadTypeId, mf.Instructions, 
    ISNULL(msf.Repeatable,mf.Repeatable) as Repeatable,
    ISNULL(msf.SurveyStatus,mf.SurveyStatus) AS SurveyStatus, 
    ISNULL(msf.FormActive,mf.FormActive ) AS FormActive,
    msf.HideComment,
    msf.ParentId, msf.CreatedAt,msf.CreatedBy           
    FROM dbo.MetaForm mf 
    JOIN dbo.MetaStudyForm msf ON msf.FormId=mf.FormId
    WHERE mf.FormId=@FormId;
END
GO

GRANT EXECUTE ON CRF.GetForm TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('dbo.GetMetaFormPages' ) IS NULL DROP PROCEDURE dbo.GetMetaFormPages
IF NOT OBJECT_ID('Meta.GetFormPages' ) IS NULL DROP PROCEDURE Meta.GetFormPages
IF NOT OBJECT_ID('CRF.GetFormPages' ) IS NULL DROP PROCEDURE CRF.GetFormPages
GO

CREATE PROCEDURE CRF.GetFormPages( @FormId INT )
AS
BEGIN
  SELECT * FROM dbo.MetaFormPage WHERE FormId=@FormId ORDER BY PageNumber
END
GO

GRANT EXECUTE ON CRF.GetFormPages TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('dbo.GetMetaFormActions' ) IS NULL DROP PROCEDURE dbo.GetMetaFormActions
IF NOT OBJECT_ID('Meta.GetFormActions' ) IS NULL DROP PROCEDURE Meta.GetFormActions
IF NOT OBJECT_ID('CRF.GetFormActions' ) IS NULL DROP PROCEDURE CRF.GetFormActions
GO

CREATE PROCEDURE CRF.GetFormActions( @FormId INT )
AS
BEGIN
  SELECT * FROM dbo.MetaFormAction WHERE FormId=@FormId
END
GO

GRANT EXECUTE ON CRF.GetFormActions TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('dbo.GetMetaFormItems' ) IS NULL DROP PROCEDURE dbo.GetMetaFormItems
IF NOT OBJECT_ID('Meta.GetFormItems' ) IS NULL DROP PROCEDURE Meta.GetFormItems
IF NOT OBJECT_ID('CRF.GetFormItems' ) IS NULL DROP PROCEDURE CRF.GetFormItems
GO

CREATE PROCEDURE CRF.GetFormItems( @FormId INT ) AS
BEGIN
  SELECT mfi.OrderNumber,mi.ItemId,mi.VarName,mi.LabName,mi.ItemType,mi.UnitStr,
    mi.MinNormal,mi.MaxNormal,mi.ThreadTypeId, mi.Multiline,
    mfi.ExcludeFromText,mfi.ExcludeCaption, mfi.ItemHeader,mfi.ItemText,
    mfi.ItemHelp,mfi.Optional,mfi.ReadOnly,mfi.CarryForward,
    mfi.MinExpression,mfi.MaxExpression,mfi.Decimals,mfi.Expression,
    DefaultValue,ISNULL(Visibility,1) as Visibility,mfi.PageNumber,mfi.LastUpdate 
    FROM dbo.MetaFormItem mfi 
    JOIN dbo.MetaItem mi ON mi.ItemId=mfi.ItemId 
    LEFT OUTER JOIN dbo.MetaFormPage mfp ON mfp.PageId=mfi.PageId 
    WHERE mfi.FormId=@FormId 
    ORDER BY mfi.PageNumber,mfi.OrderNumber
END
GO

GRANT EXECUTE ON CRF.GetFormItems TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('CRF.GetMetaFormItems' ) IS NULL DROP PROCEDURE CRF.GetMetaFormItems
IF NOT OBJECT_ID('CRF.GetStudyFormItems' ) IS NULL DROP PROCEDURE CRF.GetStudyFormItems
GO

CREATE PROCEDURE CRF.GetStudyFormItems( @StudyId INT )
AS
BEGIN
  SELECT mfi.FormId,mfi.ItemId,mfi.OrderNumber,mfi.ItemHeader,mfi.ItemText,mi.VarName,mi.UnitStr,mi.ItemType,
    mfi.MinExpression,mfi.MaxExpression, mfi.Decimals, mfi.FormItemId  
  FROM MetaFormItem mfi 
  JOIN MetaItem mi ON mi.ItemId=mfi.ItemId
  JOIN MetaStudyForm msf ON msf.FormId=mfi.FormId
  WHERE msf.StudyId=@StudyId
END
GO

GRANT EXECUTE ON CRF.GetStudyFormItems TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('ORM.MetaForm') IS NULL DROP VIEW ORM.MetaForm
GO
IF NOT OBJECT_ID('ORM.MetaFormItem') IS NULL DROP VIEW ORM.MetaFormItem
GO
IF NOT OBJECT_ID('ORM.MetaItem') IS NULL DROP VIEW ORM.MetaItem
GO
IF NOT OBJECT_ID('ORM.MetaItemAnswer') IS NULL DROP VIEW ORM.MetaItemAnswer
GO

ALTER VIEW dbo.OngoingTreatment (TreatId, PersonId, ATC, ATCVersion, DrugName, DrugForm, TreatType, PackType, TreatPackType, Strength, StrengthUnit, Dose24hCount, Dose24hDD, StartAt, StartFuzzy, StartReason, RxText, StopAt, StopFuzzy, StopReason, DoseCode, PauseStatus, CreatedAt, DoseId, StartedBy, CreatedBy, StopBy ) 
AS
  SELECT TreatId, PersonId, ATC, ATCVersion, DrugName, DrugForm, TreatType, PackType, TreatPackType, Strength, StrengthUnit, Dose24hCount, Dose24hDD, StartAt, StartFuzzy, StartReason, RxText, StopAt, StopFuzzy, StopReason, DoseCode, PauseStatus, CreatedAt, DoseId, StartedBy, CreatedBy, StopBy 
  FROM DrugTreatment WHERE (StopAt IS NULL OR StopAt > getdate())
GO

IF NOT OBJECT_ID('GetCaseListDruidLevel') IS NULL
  DROP PROCEDURE GetCaseListDruidLevel
GO
 
CREATE PROCEDURE dbo.GetCaseListDruidLevel( @StudyId INT, @AlertLevel INT ) AS
BEGIN
  SET NOCOUNT ON;
  SELECT vcl.PersonId,vcl.DOB,vcl.FullName,sg.GroupName, l.LevelDesc + ': ' + a.AlertHeader AS InfoText
  FROM dbo.Alert a
    JOIN ViewActiveCaseListStub vcl ON vcl.PersonId=a.PersonId
    JOIN StudCase sc ON (sc.PersonId=vcl.PersonId) AND (sc.StudyId=a.StudyId)
    JOIN MetaAlertLevel l ON (l.AlertLevel=a.AlertLevel)
    LEFT OUTER JOIN dbo.StudyGroup sg ON sg.GroupId=sc.GroupId and sg.StudyId=sc.StudyId
  WHERE ( a.StudyId=@StudyId) AND ( a.AlertLevel = @AlertLevel ) AND (AlertClass LIKE 'DRUID#%')
  ORDER BY a.AlertLevel DESC,vcl.PersonId
END;
GO

GRANT EXECUTE ON GetCaseListDruidLevel TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('MergeVariables') IS NULL 
  DROP PROCEDURE dbo.MergeVariables
GO

IF NOT OBJECT_ID('report.OrphanedVariables') IS NULL 
  DROP VIEW report.OrphanedVariables
GO

IF NOT OBJECT_ID('GBD.GetCaseListDiedHere') IS NULL 
  DROP PROCEDURE GBD.GetCaseListDiedHere
GO

IF NOT OBJECT_ID('GBD.Tvangsvedtak') IS NULL
  DROP VIEW GBD.Tvangsvedtak
GO

IF NOT OBJECT_ID('NDV.FormData') IS NULL
  DROP VIEW NDV.FormData
GO

CREATE VIEW NDV.FormData 
AS
SELECT ce.EventTime as dato,p.NationalId as pasientid,co.VarName as navn,ISNULL(CONVERT(VARCHAR,co.DTVal,126),ISNULL(CONVERT(VARCHAR,co.EnumVal),CONVERT(VARCHAR,co.Quantity) ) ) as verdi
  FROM dbo.ClinObservation co 
  JOIN dbo.ClinEvent ce ON ce.EventId=co.EventId
  JOIN dbo.Person p ON p.PersonId=ce.PersonId
  JOIN dbo.StudCase sc ON sc.PersonId=p.PersonId AND sc.MarkedForExport=1
  WHERE (( co.VarName LIKE 'NDV_%' ) OR ( co.VarName IN ('SYSBP','DIABP','WEIGHT','HEIGHT','WAIST','BMI','HBA1C','DIABETESKOMPLIKASJONER')) OR ( co.VarName LIKE 'ATC_%' ));
GO

GRANT SELECT ON NDV.FormData TO [public]
GO

CREATE VIEW GBD.Tvangsvedtak AS
  SELECT ce.StudyId,ce.PersonId,ce.EventTime,cpstart.DTVal AS StartDate,cpstop.DTVal as StopDate,
    ISNULL(cpaction.EnumVal,1) AS StopAction,CONVERT(INT,getdate()-cpstop.DTVal) AS DaysPastDue,
    cf.ClinFormId
  FROM dbo.ClinEvent ce
  JOIN dbo.ClinForm cf ON cf.EventId=ce.EventId AND cf.DeletedAt IS NULL
  JOIN dbo.MetaForm mf ON mf.FormId=cf.FormId AND mf.FormName='TVANGSVEDTAK'
  LEFT OUTER JOIN dbo.ClinDatapoint cpstart ON cpstart.EventId=ce.EventId AND cpstart.ItemId=4496 
  LEFT OUTER JOIN dbo.ClinDatapoint cpstop ON cpstop.EventId=ce.EventId AND cpstop.ItemId=4497 
  LEFT OUTER JOIN dbo.ClinDatapoint cpaction ON cpaction.EventId=ce.EventId AND cpaction.ItemId=6888
GO

GRANT SELECT ON GBD.Tvangsvedtak TO [public]
GO

IF NOT OBJECT_ID('UpdateMustScoreForAll') IS NULL 
  DROP PROCEDURE UpdateMustScoreForAll
GO

CREATE PROCEDURE dbo.UpdateMustScoreForAll( @StudyId INT)
AS
  DECLARE @PersonId INT;
BEGIN
  DECLARE studcase_cursor CURSOR FOR SELECT PersonId FROM StudCase WHERE StudyId=@StudyId;
  OPEN studcase_cursor;
  FETCH NEXT FROM studcase_cursor INTO @PersonId;
  WHILE @@FETCH_STATUS = 0 BEGIN
    EXECUTE RuleMUST @StudyId,@PersonId;
    FETCH NEXT FROM studcase_cursor INTO @PersonId;
  END
  CLOSE studcase_cursor;
  DEALLOCATE studcase_cursor;
END
GO

GRANT EXECUTE ON dbo.UpdateMustScoreForAll TO [public] AS [dbo]
GO

ALTER PROCEDURE dbo.RunHourly AS
BEGIN
  PRINT 'Nothing to do';
END
GO

ALTER TABLE KB.InteractionNorGEP DROP COLUMN AlertClass 
GO

ALTER TABLE KB.InteractionNorGEP ADD AlertClass AS ('DRUID#'+CONVERT([varchar],[IntId],0))
GO

EXEC sp_refreshview 'KB.ViewNorGEPInteractions'
EXEC sp_refreshview 'NDV.Variabler'
EXEC sp_refreshview 'dbo.UtilMissingPeople'
GO

IF NOT OBJECT_ID('FK_ClinForm_MetaForm') IS NULL
  ALTER TABLE ClinForm DROP CONSTRAINT FK_ClinForm_MetaForm
GO

IF NOT OBJECT_ID('FK_DrugReason_MetaReasonType') IS NULL
  ALTER TABLE DrugReason DROP CONSTRAINT FK_DrugReason_MetaReasonType
GO

IF NOT OBJECT_ID('UtilRenameObject') IS NULL DROP PROCEDURE dbo.UtilRenameObject
GO

CREATE PROCEDURE dbo.UtilRenameObject( @ObjectName NVARCHAR(128), @NewName NVARCHAR(128) ) AS
BEGIN
  IF NOT OBJECT_ID(@ObjectName) IS NULL
    EXEC sp_rename @ObjectName,@NewName,'OBJECT'
END
GO

GRANT UPDATE ON dbo.Person TO [public] AS [dbo]
GO
 
EXECUTE DbFinalizeUpgrade 600;
GO

COMMIT TRANSACTION UpgradeTo600;
GO



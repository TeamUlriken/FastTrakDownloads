SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo511;
PRINT 'Starting upgrade to 511'

DELETE FROM DbUpgradeLog WHERE DbVer > 510;
GO
EXEC DbCheckVersion 510;           
EXECUTE DbStartUpgrade 511;
GO

IF NOT OBJECT_ID('Report.LabTestOverview') IS NULL DROP VIEW Report.LabTestOverview
GO

CREATE VIEW Report.LabTestOverview (LabCodeId, LabName, FriendlyName, FurstId, LabCount, MinResult,MaxResult,AvgResult ) 
AS
  SELECT
    lc.LabCodeId,lc.LabName,lc.FriendlyName,lc.FurstId, count(*) as LabCount, min(ld.NumResult),max(ld.NumResult),avg(ld.NumResult)                                           
  FROM LabCode lc JOIN LabData ld ON ld.LabCodeId=lc.LabCodeId
  GROUP BY
    lc.LabCodeId,lc.LabName,lc.FriendlyName,lc.FurstId
GO

GRANT SELECT ON report.LabTestOverview TO [public]
GO

ALTER TABLE Comm.OutBox ALTER COLUMN MessageText VARCHAR(MAX) NOT NULL
GO

ALTER TABLE Comm.OutBox ALTER COLUMN StatusMessage VARCHAR(MAX)
GO

ALTER TABLE dbo.CaveLog ALTER COLUMN CAVE VARCHAR(MAX)
GO

ALTER TABLE dbo.ClinForm ALTER COLUMN Comment VARCHAR(MAX)
GO

ALTER TABLE dbo.ClinForm ALTER COLUMN CachedText VARCHAR(MAX)
GO

ALTER TABLE dbo.ClinFormLog ALTER COLUMN Comment VARCHAR(MAX)
GO

ALTER TABLE dbo.ClinProblem ALTER COLUMN ProbSummary VARCHAR(MAX)
GO

ALTER TABLE dbo.DbProcList ALTER COLUMN ProcSourceCode VARCHAR(MAX)
GO

ALTER TABLE dbo.DbProcList ALTER COLUMN HelpText VARCHAR(MAX)
GO

ALTER TABLE dbo.DrugPrescription ALTER COLUMN RxText VARCHAR(MAX)
GO

ALTER TABLE dbo.DrugTreatment ALTER COLUMN RxText VARCHAR(MAX)
GO

ALTER TABLE dbo.ImportBatch ALTER COLUMN ErrorMessages VARCHAR(MAX)
GO

GRANT UPDATE ON dbo.MetaAlertFacet TO [public]
GO

ALTER TABLE dbo.MetaAlertFacet ALTER COLUMN FacetDesc VARCHAR(64) NOT NULL
GO

REVOKE UPDATE,INSERT,DELETE ON dbo.MetaAlertFacet TO [public]
GO

ALTER TABLE dbo.MetaForm ALTER COLUMN FormXML VARCHAR(MAX)
GO

IF dbo.DbColumnExists( 'MetaForm','HelpText') = 1
  ALTER TABLE dbo.MetaForm ALTER COLUMN HelpText VARCHAR(MAX)
GO

ALTER TABLE dbo.MetaForm ALTER COLUMN Copyright VARCHAR(MAX)
GO

ALTER TABLE dbo.MetaForm ALTER COLUMN Instructions VARCHAR(MAX)
GO

ALTER TABLE dbo.MetaFormItem ALTER COLUMN ItemText VARCHAR(MAX)
GO

ALTER TABLE dbo.MetaFormItem ALTER COLUMN MinExpression VARCHAR(MAX)
GO

ALTER TABLE dbo.MetaFormItem ALTER COLUMN MaxExpression VARCHAR(MAX)
GO

ALTER TABLE dbo.MetaFormItem ALTER COLUMN Expression VARCHAR(MAX)
GO

ALTER TABLE dbo.MetaFormItem ALTER COLUMN ItemHelp VARCHAR(MAX)
GO

GRANT UPDATE ON dbo.MetaRelatedness TO [public]
GO

ALTER TABLE dbo.MetaRelatedness ALTER COLUMN RelText VARCHAR(MAX) NOT NULL
GO

REVOKE UPDATE,INSERT,DELETE ON dbo.MetaRelatedness TO [public]
GO

GRANT UPDATE ON dbo.MetaSeverity TO [public]
GO

ALTER TABLE dbo.MetaSeverity ALTER COLUMN SevText VARCHAR(MAX) NOT NULL
GO

REVOKE UPDATE,INSERT,DELETE ON dbo.MetaSeverity TO [public]
GO

ALTER TABLE dbo.Person ALTER COLUMN CAVE VARCHAR(MAX)
GO

ALTER TABLE dbo.MetaNomItem ALTER COLUMN ItemName VARCHAR(MAX)
GO

IF dbo.DbColumnExists( 'UserLog', 'DirtyClose') = 0
  ALTER TABLE UserLog ADD DirtyClose BIT
GO

ALTER PROCEDURE dbo.CloseSession( @SessId INT, @Updates INT, @Inserts INT ) AS
BEGIN
  UPDATE UserLog SET ClosedAt = GetDate(),Updates=@Updates,Inserts=@Inserts,ClosedBy=user_id(),DirtyClose=0
    WHERE SessId=@SessId AND ClosedAt IS NULL AND UserId=user_id();
  UPDATE UserLog SET ClosedAt = GetDate(),ClosedBy=user_id(),DirtyClose=1 
  WHERE ( ClosedAt IS NULL ) AND ( UserId=user_id() ) AND ( ServTime < getdate()-1 );
  EXEC RunHourly;
END
GO

ALTER PROCEDURE dbo.RulePeriodicForm( @StudyId INT, @PersonId INT, @FormName VarChar(24),
 @DaysBetween INT, @AlertLevel tinyint ) AS
BEGIN
  DECLARE @LastFormDate DateTime;
  DECLARE @DaysAgo DECIMAL(6,1);
  DECLARE @AlertFacet varchar(16);
  DECLARE @ActualLevel INT;
  SELECT @LastFormDate = dbo.GetLastCompleteForm( @StudyId,@PersonId,@FormName );
  IF @LastFormDate IS NULL BEGIN
    SET @ActualLevel = @AlertLevel;
    SET @AlertFacet = 'DataMissing';
  END
  ELSE BEGIN
    SET @DaysAgo=CONVERT(FLOAT,GetDate())-CONVERT(FLOAT,@LastFormDate);
    IF @DaysAgo>@DaysBetween BEGIN
      SET @ActualLevel = @AlertLevel;
      SET @AlertFacet = 'DataOld';
    END
    ELSE BEGIN
      SET @ActualLevel = 0;
      SET @AlertFacet = 'DataFound';
    END
  END
  EXEC AddAlertForDSSRule @StudyId,@PersonId,@ActualLevel,@FormName,@AlertFacet
END;
GO

ALTER PROCEDURE GBD.InfectionReport( @StartAt DateTime = NULL, @StopAt DateTime = NULL )
AS
BEGIN
  SET LANGUAGE Norwegian;
  IF @StartAt IS NULL SET @StartAt = getdate()-90;
  IF @StopAt IS NULL SET @StopAt = getdate();
  SELECT ce.PersonId,ce.EventId,ce.EventTime,
    dbo.MonthYear( ce.EventTime) as MonthName,
    c.CenterId,c.CenterName,
    sg.GroupId,sg.GroupName,
    mia1.OptionText as InfeksjonsType,
    mia7.OptionText as KjentAgens, 
    co6.TextVal as Agens,
    mia8.OptionText as GittMedisin,        
    co9.TextVal as MedisinNavn,
    co2.DTVal as StartDato,co3.DTVal as SluttDato,
    mia4.OptionText as SykehusInnleggelse, mia5.OptionText as [PasientDøde],
    ul.UserId,up.PersonId as UserPersonId,up.ReverseName as Brukernavn
  INTO #temp
  FROM ClinEvent ce 
  JOIN ClinForm cf ON cf.EventId=ce.EventId AND cf.DeletedAt IS NULL 
  JOIN MetaForm mf ON mf.FormId=cf.FormId AND mf.FormName='GBD_INFECTION'
  LEFT OUTER JOIN ClinObservation co1 ON co1.EventId=ce.EventId AND co1.VarName='INFECT_TYPE'
  LEFT OUTER JOIN MetaItemAnswer mia1 ON mia1.ItemId=769 and mia1.OrderNumber=co1.EnumVal
  LEFT OUTER JOIN ClinObservation co2 ON co2.EventId=ce.EventId AND co2.VarName='INFECT_DATE_START'
  LEFT OUTER JOIN ClinObservation co3 ON co3.EventId=ce.EventId AND co3.VarName='INFECT_DATE_END'
  LEFT OUTER JOIN ClinObservation co4 ON co4.EventId=ce.EventId AND co4.VarName='INFEKSJON_INNLEGGELSE'
  LEFT OUTER JOIN MetaItemAnswer mia4 ON mia4.ItemId=777 and mia4.OrderNumber=co4.EnumVal
  LEFT OUTER JOIN ClinObservation co5 ON co5.EventId=ce.EventId AND co5.VarName='INFEKSJON_DØD'
  LEFT OUTER JOIN MetaItemAnswer mia5 ON mia5.ItemId=778 and mia5.OrderNumber=co5.EnumVal
  LEFT OUTER JOIN ClinObservation co6 ON co6.EventId=ce.EventId AND co6.VarName='INFECT_AGENT_NAMES'
  LEFT OUTER JOIN ClinObservation co7 ON co7.EventId=ce.EventId AND co7.VarName='INFECT_AGENT_KNOWN'
  LEFT OUTER JOIN MetaItemAnswer mia7 ON mia7.ItemId=3498 and mia7.OrderNumber=co7.EnumVal
  LEFT OUTER JOIN ClinObservation co8 ON co8.EventId=ce.EventId AND co8.VarName='INFECT_DRUG_GIVEN'
  LEFT OUTER JOIN MetaItemAnswer mia8 ON mia8.ItemId=3499 and mia8.OrderNumber=co8.EnumVal
  LEFT OUTER JOIN ClinObservation co9 ON co9.EventId=ce.EventId AND co9.VarName='INFECT_DRUG_NAMES'
  JOIN UserList ul ON ul.UserId=cf.CreatedBy
  JOIN UserList my ON my.UserId=USER_ID()
  JOIN Person up ON up.PersonId=ul.PersonId
  JOIN StudCase sc ON sc.StudyId=ce.StudyId AND sc.PersonId=ce.PersonId
  JOIN Study s ON s.StudyId=sc.StudyId AND s.StudyName='GBD'
  JOIN StudyGroup sg ON sg.StudyId=sc.StudyId AND sg.GroupId=sc.GroupId
  JOIN StudyCenter c ON c.CenterId=sg.CenterId AND c.CenterId=my.CenterId
  LEFT OUTER JOIN StudyUser su ON su.UserId=USER_ID() AND su.StudyId=sc.StudyId
  WHERE ( ce.EventTime > @StartAt AND ce.EventTime < @StopAt )
  AND (( su.GroupId=sc.GroupId ) OR ( su.UserId IS NULL ) OR ( su.GroupId IS NULL ) OR ( su.ShowMyGroup = 0 ));
  SELECT * FROM #temp ORDER BY EventTime;
END
GO

IF EXISTS( SELECT * FROM syscolumns WHERE ( name = 'DeletedBy' ) AND ( object_name(id) = 'DrugPrescription' ) AND ( usertype <> 7 ) )
BEGIN
  ALTER TABLE DrugPrescription DROP COLUMN DeletedBy
  ALTER TABLE DrugPrescription ADD DeletedBy INT NULL
END
GO

EXECUTE DbFinalizeUpgrade 511;

COMMIT TRANSACTION UpgradeTo511;
GO

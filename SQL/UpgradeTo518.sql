SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo518;
PRINT 'Starting upgrade to 518'
DELETE FROM DbUpgradeLog WHERE DbVer > 517;

EXEC DbCheckVersion 517;       
EXECUTE DbStartUpgrade 518;
GO

ALTER PROCEDURE dbo.DbCheckVersion( @DbVer INT )
AS
BEGIN
  DECLARE @CurrVersion INT;
  SET @CurrVersion = dbo.DbVersion();
  IF @CurrVersion <> @DbVer
   RAISERROR( 'Upgrade requires version %d. Your version is %d!',18,1,@DbVer,@CurrVersion)
END
GO

GRANT UPDATE,DELETE ON Dash.CaseListHistory TO [public] AS [dbo]
GO

DELETE FROM Dash.CaseListHistory WHERE NOT StudyId IN ( SELECT StudyId FROM dbo.Study )
GO

IF NOT EXISTS( select uid FROM sysobjects WHERE name='FK_Outbox_Person' )
 ALTER TABLE Comm.Outbox ADD CONSTRAINT FK_Outbox_Person FOREIGN KEY (PersonId) REFERENCES dbo.Person(PersonId)
GO
 
IF NOT EXISTS( select uid FROM sysobjects WHERE name='FK_Outbox_ClinForm' )
 ALTER TABLE Comm.Outbox ADD CONSTRAINT FK_Outbox_ClinForm FOREIGN KEY (ClinFormId) REFERENCES dbo.ClinForm(ClinFormId)
GO

IF NOT EXISTS( select uid FROM sysobjects WHERE name='FK_CaseListHistory_Study' )
 ALTER TABLE Dash.CaseListHistory ADD CONSTRAINT FK_CaseListHistory_Study FOREIGN KEY (StudyId) REFERENCES dbo.Study(StudyId)
GO

IF NOT EXISTS( select uid FROM sysobjects WHERE name='FK_CaseListHistory_Person' )
 ALTER TABLE Dash.CaseListHistory ADD CONSTRAINT FK_CaseListHistory_Person FOREIGN KEY (PersonId) REFERENCES dbo.Person(PersonId)
GO

GRANT SELECT,DELETE ON dbo.ClinDrugIndication TO public
GRANT SELECT ON dbo.DrugTreatment TO public
GO

DELETE FROM dbo.ClinDrugIndication WHERE NOT TreatId IN ( SELECT TreatId FROM DrugTreatment )
GO

REVOKE SELECT,DELETE ON dbo.ClinDrugIndication TO public
REVOKE SELECT ON dbo.DrugTreatment TO public
GO

IF NOT EXISTS( select uid FROM sysobjects WHERE name='FK_ClinDrugIndication_DrugTreatment' )
 ALTER TABLE dbo.ClinDrugIndication ADD CONSTRAINT FK_ClinDrugIndication_DrugTreatment FOREIGN KEY (TreatId) REFERENCES dbo.DrugTreatment(TreatId) ON DELETE CASCADE ON UPDATE NO ACTION 
GO

IF dbo.DbColumnExists( 'Person','CreatedAt' ) = 0 
  ALTER TABLE Person ADD CreatedAt DateTime CONSTRAINT DF_Person_CreatedAt DEFAULT getdate()
GO

IF NOT EXISTS( select uid FROM sysobjects WHERE name='FK_ClinDrugIndication_CreatedBy' )
 ALTER TABLE dbo.ClinDrugIndication ADD CONSTRAINT FK_ClinDrugIndication_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.UserList(UserId) 
GO

IF dbo.DbColumnExists( 'Person','CreatedBy' ) = 0 
BEGIN
  ALTER TABLE dbo.Person ADD CreatedBy INT CONSTRAINT DF_Person_CreatedBy DEFAULT USER_ID()
  ALTER TABLE dbo.Person ADD CONSTRAINT FK_Person_CreatedBy_UserList FOREIGN KEY (CreatedBy) REFERENCES UserList(UserId)
END
GO

IF dbo.DbColumnExists( 'Person','guid' ) = 0
  ALTER TABLE dbo.Person ADD guid UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_PersonGuid DEFAULT NEWID()
GO

IF dbo.DbColumnExists( 'UserList','guid' ) = 0
  ALTER TABLE UserList ADD guid UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_UserListGuid DEFAULT NEWID() 
GO

IF NOT EXISTS( select * FROM sysobjects WHERE name='C_Person_DOB_First' ) 
  ALTER TABLE Person WITH CHECK ADD CONSTRAINT C_Person_DOB_First CHECK ( DOB >= '1890-01-01' )
GO

IF NOT EXISTS( select * FROM sysobjects WHERE name='C_Person_DOB_Last' ) 
  ALTER TABLE Person WITH CHECK ADD CONSTRAINT C_Person_DOB_Last CHECK ( DOB <= '2013-06-30' )
GO

GRANT UPDATE ON ClinEvent TO [public]
GO

IF dbo.DbColumnExists( 'ClinEvent','guid' ) = 0
  ALTER TABLE ClinEvent ADD guid UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ClinEventGuid DEFAULT NEWID() 
GO

REVOKE UPDATE ON ClinEvent TO [public]
GO
 
ALTER PROCEDURE dbo.UpdateDrugTreatmentMultidoseDetails( @TreatId INT,
 @Dose07 decimal(8,2), @Dose08 decimal(8,2), @Dose13 decimal(8,2),
 @Dose18 decimal(8,2), @Dose21 decimal(8,2), @Dose23 decimal(8,2),
 @ChangedAt DateTime = NULL )
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Dose24hCount DECIMAL(12,4);
  DECLARE @CalcDose DECIMAL(12,4);
  DECLARE @DoseId INT;
  DECLARE @MsgText VARCHAR(255);
  DECLARE @TreatType CHAR(1);
  DECLARE @PackType CHAR(1);
  SELECT @TreatType=TreatType,@PackType=PackType FROM dbo.DrugTreatment WHERE TreatId=@TreatId;
  IF @ChangedAt IS NULL SET @ChangedAt=GetDate();
  SET @DoseId = NULL;
  SELECT @Dose24hCount = Dose24hCount FROM dbo.DrugTreatment
    WHERE ( TreatId=@TreatId ) AND (StopAt IS NULL ) AND ( TreatType = @TreatType );
  IF @Dose24hCount IS NULL
    SET @MsgText = 'Treatment does not exists, is not active, or of the wrong type.'
  ELSE BEGIN
    /* Calculate the dose based on given information */
    IF @Dose24hCount=0 
      SET @CalcDose = 0
    ELSE
      SET @CalcDose=@Dose07+@Dose08+@Dose13+@Dose18+@Dose21+@Dose23;
    /* Make sure the existing dose is equivalent to what we are adding here */
    IF ( @CalcDose<>@Dose24hCount )
      SET @MsgText = 'Daily dose mismatch.  Could not set dose details.'
    ELSE BEGIN
      /* Stop all earlier dosing schemes, regardless of type */
      EXEC DisableDrugDosingSchemes @TreatId,@ChangedAt;
      /* Add a new dosing scheme to DrugDosing */
      INSERT INTO dbo.DrugDosing (TreatId,PackType,ValidFrom,Dose07,Dose08,Dose13,Dose18,Dose21,Dose23,
        DoseMon,DoseTue,DoseWed,DoseThu,DoseFri,DoseSat,DoseSun,TreatType)
        VALUES (@TreatId,@PackType,@ChangedAt,@Dose07,@Dose08,@Dose13,@Dose18,@Dose21,@Dose23,
          @CalcDose,@CalcDose,@CalcDose,@CalcDose,@CalcDose,@CalcDose,@CalcDose,@TreatType);
      SET @DoseId=SCOPE_IDENTITY();
      UPDATE dbo.DrugTreatment SET DoseId=@DoseId WHERE TreatId=@TreatId;
      SET @MsgText='OK';
    END;
  END;
  IF @DoseId IS NULL 
  BEGIN
    RAISERROR( @MsgText, 16, 1 );
    RETURN -1;
  END;
  SELECT @DoseId,@MsgText;
END
GO

ALTER PROCEDURE dbo.UpdateDrugTreatmentDosetteDetails( @TreatId INT,
 @Dose08 decimal(8,2), @Dose13 decimal(8,2),
 @Dose18 decimal(8,2), @Dose21 decimal(8,2),
 @ChangedAt DateTime = NULL )
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Dose24hCount DECIMAL(12,4);
  DECLARE @CalcDose DECIMAL(12,4);
  DECLARE @DoseId INT;
  DECLARE @MsgText varchar(255);
  DECLARE @TreatType CHAR(1);
  SELECT @TreatType=TreatType FROM dbo.DrugTreatment WHERE TreatId=@TreatId;
  IF @ChangedAt IS NULL SET @ChangedAt=GetDate();
  SET @DoseId = NULL;
  UPDATE dbo.DrugTreatment SET PackType='D' WHERE TreatId=@TreatId;
  /* Make sure the dose is equivalent to what we are adding here */
  SELECT @Dose24hCount = Dose24hCount FROM dbo.DrugTreatment
    WHERE ( TreatId=@TreatId ) AND (( StopAt IS NULL ) OR (StopAt>GetDate())) AND ( TreatType=@TreatType);
  IF @Dose24hCount IS NULL
    SET @MsgText = 'Treatment does not exists, is not active, or of the wrong type.'
  ELSE BEGIN
    /* Calculate the dose based on given information */
    IF @Dose24hCount=0 
      SET @CalcDose = 0
    ELSE
      SET @CalcDose=@Dose08+@Dose13+@Dose18+@Dose21;
    IF ( @CalcDose<>@Dose24hCount )
      SET @MsgText = 'Daily dose invalid.  Could not set dosette details'
    ELSE BEGIN
      /* Stop all earlies dosing schemes */
      EXEC DisableDrugDosingSchemes @TreatId,@ChangedAt;
      /* Add a new dosing scheme to DrugDosing */
      INSERT INTO dbo.DrugDosing (TreatId,PackType,ValidFrom,Dose08,Dose13,Dose18,Dose21,
        DoseMon,DoseTue,DoseWed,DoseThu,DoseFri,DoseSat,DoseSun,TreatType)
        VALUES (@TreatId,'D',@ChangedAt,@Dose08,@Dose13,@Dose18,@Dose21,
         @CalcDose,@CalcDose,@CalcDose,@CalcDose,@CalcDose,@CalcDose,@CalcDose,@TreatType);
      SET @DoseId=SCOPE_IDENTITY();
      UPDATE dbo.DrugTreatment SET DoseId=@DoseId WHERE TreatId=@TreatId;
      SET @MsgText = 'OK'
    END
  END
  IF @DoseId IS NULL 
  BEGIN
    RAISERROR( @MsgText, 16, 1 );
    RETURN -1;
  END;
  SELECT @DoseId,@MsgText;
END
GO

IF NOT OBJECT_ID('ConvertDoseHourText') IS NULL DROP FUNCTION dbo.ConvertDoseHourText
GO

CREATE FUNCTION dbo.ConvertDoseHourText( @NumFloat FLOAT, @ThisHour TINYINT, @DoseHour TinyInt ) RETURNS VarChar(24)
AS
BEGIN
  DECLARE @RetVal VARCHAR(24);
  IF ISNULL(@NumFloat,0) = 0 
  BEGIN
    IF @ThisHour=@DoseHour
      SET @RetVal = 'U'
    ELSE 
      SET @RetVal = '';
  END
  ELSE IF @NumFloat = -1
    SET @RetVal = 'X'
  ELSE
    SET @RetVal = CONVERT(VARCHAR,@NumFloat)
  RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.ConvertDoseHourText TO [public] AS [dbo]
GO

ALTER PROCEDURE dbo.GetDrugForMultidose( @PersonId INT, @ShowDate DateTime = NULL ) AS
BEGIN
  IF @ShowDate IS NULL SET @ShowDate = getdate();
  SELECT
    dt.TreatId,dt.StartAt,dt.DrugName,dbo.GetRxText( dt.TreatId ) as RxText,
    dt.StopAt,p2.Signature as StopSign,p1.Signature as StartSign,dt.PackType,mp.PackDesc,
    mp.SortOrder, mtpg.GroupName,
    dt.TreatType,mt.TreatDesc,
      dbo.ConvertDoseHourText(dd.Dose07,7,dd.DoseHour) as Dose07,
      dbo.ConvertDoseHourText(dd.Dose08,8,dd.DoseHour) as Dose08,
      dbo.ConvertDoseHourText(dd.Dose13,13,dd.DoseHour) as Dose13,
      dbo.ConvertDoseHourText(dd.Dose18,18,dd.DoseHour) as Dose18,
      dbo.ConvertDoseHourText(dd.Dose21,21,dd.DoseHour) as Dose21,
      dbo.ConvertDoseHourText(dd.Dose23,23,dd.DoseHour) as Dose23,
    dt.DrugForm,
    dbo.GetDose24hText( dt.TreatId) as Dose24hText,
    dt.Strength,dt.StrengthUnit,dt.Dose24hDD,
    CONVERT(FLOAT,ISNULL(StopAt,@ShowDate+1) - @ShowDate) as DaysLeft, dt.PauseStatus
  FROM DrugTreatment dt
    JOIN MetaPackType mp on mp.PackType = dt.PackType
    JOIN MetaTreatType mt on mt.TreatType = dt.TreatType
    LEFT OUTER JOIN dbo.DrugDosing dd on dd.DoseId=dt.DoseId
    LEFT OUTER JOIN dbo.UserList u1 on u1.UserId=dt.CreatedBy
    LEFT OUTER JOIN dbo.Person p1 on p1.PersonId=u1.PersonId
    LEFT OUTER JOIN dbo.UserList u2 on u2.UserId=dt.StopBy
    LEFT OUTER JOIN dbo.Person p2 on p2.PersonId=u2.PersonId
    LEFT OUTER JOIN dbo.MetaTreatPackGroup mtpg on dt.TreatType=mtpg.TreatType and dt.PackType=mtpg.PackType
  WHERE dt.PersonId=@PersonId
    AND (( dt.StopAt IS NULL ) OR ( @ShowDate < dt.StopAt ))
    AND ( dt.CreatedAt <= @ShowDate )
  ORDER BY mtpg.SortOrder,dt.StartAt
END;
GO

GRANT SELECT,UPDATE ON ClinObservation TO [public] AS [dbo]
GO

IF dbo.DbColumnExists( 'ClinObservation','ItemId') = 0
  ALTER TABLE ClinObservation ADD ItemId INT
GO

UPDATE ClinObservation 
  SET ItemId = ( SELECT ItemId FROM MetaItem where VarName=ClinObservation.VarName ) 
  WHERE ItemId IS NULL
GO

REVOKE UPDATE ON ClinObservation TO [public]
GO

EXEC AddSchema 'Report'
GO

IF NOT OBJECT_ID('Report.OrphanedVariables') IS NULL DROP VIEW Report.OrphanedVariables
GO

CREATE VIEW Report.OrphanedVariables AS
  SELECT ct.FormId,co.VarName,count(*) AS [UseCount],min(co.ObsDate) AS [MinDate],max(co.ObsDate) AS [MaxDate] 
  FROM ClinObservation co 
  LEFT OUTER JOIN ClinTouch ct ON ct.TouchId=co.TouchId
  WHERE co.ItemId IS NULL
  GROUP BY ct.FormId,co.VarName
GO

GRANT SELECT ON Report.OrphanedVariables TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('Report.GetStudyVariables') IS NULL DROP PROCEDURE Report.GetStudyVariables
GO

CREATE PROCEDURE Report.GetStudyVariables( @StudyId INT )
AS
BEGIN
  SELECT DISTINCT mi.ItemId,mi.VarName,mfi.ItemText,mi.ItemType 
  FROM MetaItem mi 
  JOIN MetaFormItem mfi ON mfi.ItemId=mi.ItemId 
  JOIN MetaStudyForm sf ON sf.FormId=mfi.FormId 
  WHERE sf.StudyId=@Studyid AND NOT mi.ItemType in (6,8) 
  order by mi.ItemId
END
GO

GRANT EXECUTE ON Report.GetStudyVariables TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('Report.GetClassifiedLabdata') IS NULL DROP PROCEDURE Report.GetClassifiedLabdata
GO

CREATE PROCEDURE Report.GetClassifiedLabdata AS
BEGIN
  SELECT lc.LabCodeId,lc.LabName,lc.VarName,count(*) as LabCount 
  FROM dbo.LabCode lc 
  JOIN dbo.LabData ld ON lc.LabCodeId=ld.LabCodeId
  WHERE ( NOT lc.VarName IS NULL ) AND ( not lc.VarName LIKE '% IKA' )
  GROUP BY lc.LabCodeId,lc.LabName,lc.VarName
  HAVING COUNT(*) > 1 
  ORDER BY COUNT(*) DESC
END
GO

GRANT EXECUTE ON Report.GetClassifiedLabdata TO [public] AS [dbo]
GO

EXECUTE DbFinalizeUpgrade 518;
GO

COMMIT TRANSACTION UpgradeTo518;
GO

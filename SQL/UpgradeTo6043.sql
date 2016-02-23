SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6043
PRINT 'Starting upgrade to 6043'

DELETE FROM DbUpgradeLog WHERE DbVer > 6042;

EXEC DbCheckVersion 6042;
EXECUTE DbStartUpgrade 6043;
GO

IF NOT OBJECT_ID('CanModifyDrugTreatment') IS NULL
  DROP PROCEDURE dbo.CanModifyDrugTreatment
GO

CREATE PROCEDURE dbo.CanModifyDrugTreatment ( @UserId INTEGER = NULL, @CanModify BIT OUTPUT, @ErrMsg VARCHAR(512) OUTPUT) 
AS
BEGIN
  SET @UserId = ISNULL(@UserId,USER_ID());
  SET @ErrMsg = '';
  SET @CanModify = 0;

  SELECT @CanModify = 1
    FROM dbo.UserList ul JOIN dbo.MetaProfession mp ON mp.ProfId=ul.ProfId
   WHERE ul.UserId=@UserId
   AND mp.ProfType IN ( 'LE', 'SP', 'VP');
   
  IF @CanModify = 0  
    SET @ErrMsg = 'Du har ikke rettigheter til å endre medisinlisten'
END
GO

GRANT EXECUTE ON dbo.CanModifyDrugTreatment TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('GetDrugPermission') IS NULL
  DROP PROCEDURE dbo.GetDrugPermission
GO

CREATE PROCEDURE dbo.GetDrugPermission
AS
BEGIN
  DECLARE @CanModifyDrugTreatment BIT;
  DECLARE @ErrMsg VARCHAR(512); 
  EXEC dbo.CanModifyDrugTreatment  null, @CanModifyDrugTreatment OUTPUT, @ErrMsg OUTPUT 
  SELECT @CanModifyDrugTreatment as 'CanModify', @ErrMsg as 'ErrorMessage'
END
GO

GRANT EXECUTE ON dbo.GetDrugPermission TO [public] AS [dbo]
GO

ALTER PROCEDURE dbo.UpdateDrugStop( 
  @TreatId            INTEGER, 
  @StopAt             DateTime, 
  @StopFuzzy          integer = 0, 
  @StopReason         VARCHAR(64) = NULL, 
  @SaveThisReason     integer = 1 )
AS
BEGIN
  DECLARE @ATC VARCHAR(7);
  DECLARE @StartAt DateTime;
  DECLARE @AlreadyStopped DateTime;
  DECLARE @PersonId INTEGER;
  DECLARE @ErrMsg VARCHAR(512);
  DECLARE @CanModifyDrugTreatment BIT;

  SET @CanModifyDrugTreatment = 1;

  EXEC dbo.CanModifyDrugTreatment  null, @CanModifyDrugTreatment OUTPUT, @ErrMsg OUTPUT;
  IF  @CanModifyDrugTreatment = 0
  BEGIN
    RAISERROR( @ErrMsg, 16, 1 );
    RETURN -200;
  END;

  SELECT @StartAt=StartAt,@AlreadyStopped=StopAt FROM dbo.DrugTreatment WHERE TreatId=@TreatId;
  IF (@StopAt<@StartAt) AND convert(int,getdate())=convert(int,@StartAt) SET @StopAt=@StartAt;
  UPDATE dbo.DrugTreatment
    SET StopAt=@StopAt,StopFuzzy=@StopFuzzy,StopReason=@StopReason,StopBy=user_id()
    WHERE TreatId=@TreatId AND ((StopAt IS NULL) or ( StopAt > @StopAt ));
  IF ( @@ROWCOUNT<>1 ) AND ( @AlreadyStopped IS NULL )
  BEGIN
    SET @ErrMsg = dbo.GetTextItem( 'UpdateDrugStop','Failed' );
    RAISERROR( @ErrMsg, 16, 1 );
    RETURN -1;
  END
  ELSE
  BEGIN
    SELECT @PersonId = PersonId FROM dbo.DrugTreatment WHERE TreatId=@TreatId;
    UPDATE dbo.StudCase SET LastWrite = getdate() WHERE PersonId=@PersonId;
    IF ( ISNULL(@StopReason,'')<>'' and @SaveThisReason=1 ) 
    BEGIN
      SELECT @ATC = ATC FROM dbo.DrugTreatment WHERE TreatId=@TreatId;
      IF DATALENGTH(@ATC) > 4 EXEC dbo.AddDrugReason @ATC,2,@StopReason
    END
  END;
END;
GO

ALTER PROCEDURE dbo.AddDrugFromTemplate( @PersonId INTEGER, @TemplateId INTEGER, @StartAt DateTime = NULL )
AS
BEGIN
  DECLARE @ATC VARCHAR(7);
  DECLARE @DrugName VARCHAR(64);  
  DECLARE @DrugForm VARCHAR(64);
  DECLARE @Strength DECIMAL(12,4);
  DECLARE @TreatId INTEGER;      
  DECLARE @TreatType CHAR(1);
  DECLARE @PackType CHAR(1);
  DECLARE @CanModifyDrugTreatment BIT;
  DECLARE @ErrMsg VARCHAR(512);

  SET @CanModifyDrugTreatment = 1;

  EXEC dbo.CanModifyDrugTreatment  null, @CanModifyDrugTreatment OUTPUT, @ErrMsg OUTPUT;
  IF  @CanModifyDrugTreatment = 0
  BEGIN
    RAISERROR( @ErrMsg, 16, 1 );
    RETURN -200;
  END;

  IF @StartAt IS NULL SET @StartAt=getdate();
  
  SELECT @ATC = ATC, @Strength=Strength,@DrugForm = DrugForm FROM dbo.DrugTemplate WHERE TemplateId=@TemplateId;
  
  SELECT @DrugName=DrugName FROM dbo.DrugTreatment WHERE PersonId=@PersonId AND StopAt IS NULL AND ATC=@ATC; 
  
  IF @DrugName IS NULL
  BEGIN  
    INSERT INTO dbo.DrugTreatment 
      (PersonId,ATC,DrugName,DrugForm,Strength,StrengthUnit,StartAt,StartReason,DoseCode )
  
    SELECT @PersonId,ATC,DrugName,DrugForm,Strength,StrengthUnit,@StartAt,StartReason,DoseCode
      FROM dbo.DrugTemplate 
     WHERE TemplateId=@TemplateId;
    
    SET @TreatId=SCOPE_IDENTITY();
    
    /* Get TreatPack info */
    SELECT TOP 1 TreatType,PackType,count(*) AS HitCount INTO #MostPopularDosing 
      FROM dbo.DrugTreatment 
     WHERE ATC=@ATC AND DrugForm=@DrugForm AND Strength=@Strength 
  GROUP BY TreatType,PackType ORDER BY count(*) DESC;          
    
    SELECT @TreatType=TreatType,@PackType=PackType FROM #MostPopularDosing;
    
    /* Update with most popular TreatPack */
    UPDATE dbo.DrugTreatment SET TreatType=@TreatType,PackType=@PackType WHERE TreatId=@TreatId;
    SELECT @TreatId AS TreatId;
  END
  ELSE
  BEGIN         
    SET @ErrMsg = dbo.GetTextItem( 'AddDrugFromTemplate','DrugExists'); 
    RAISERROR( @ErrMsg, 16,1, @DrugName, @ATC );
  END         
END
GO

ALTER PROCEDURE dbo.AddDrugByNewStrength( @TreatId INTEGER, @NewStrength DECIMAL(12,4),@StopReason VARCHAR(64) )
AS
BEGIN
  DECLARE @NewId INTEGER;
  DECLARE @CanModifyDrugTreatment BIT;
  DECLARE @ErrMsg VARCHAR(512);
  DECLARE @ChangeAt DateTime;

  SET @CanModifyDrugTreatment = 1;

  EXEC dbo.CanModifyDrugTreatment  null, @CanModifyDrugTreatment OUTPUT, @ErrMsg OUTPUT;
  IF  @CanModifyDrugTreatment = 0
  BEGIN
    RAISERROR( @ErrMsg, 16, 1 );
    RETURN -200;
  END;

  SET @ChangeAt = getdate();
  INSERT INTO dbo.DrugTreatment
   (PersonId,ATC,DrugName,DrugForm,Strength,Dose24hCount,
    StrengthUnit,StartAt,StartReason,RxText,TreatType,PackType,DoseCode,DoseId)
  SELECT
    PersonId,ATC,DrugName,DrugForm,@NewStrength,Dose24hCount,
    StrengthUnit,@ChangeAt,StartReason,RxText,TreatType,PackType,DoseCode,DoseId
  FROM dbo.DrugTreatment WHERE TreatId=@TreatId;
  SET @NewId=SCOPE_IDENTITY();
  IF @@ERROR <> 0 RETURN -ABS(@@ERROR);
  EXEC dbo.UpdateDrugStop @TreatId,@ChangeAt,0,@StopReason,0;
  RETURN @NewId;
END
GO

ALTER PROCEDURE dbo.AddDrug( @PersonId INTEGER, @ATC VARCHAR(7),
       @DrugName VARCHAR(64), @DrugForm VARCHAR(64), @Strength DECIMAL(12,4),
       @StrengthUnit VARCHAR(24), @Dose24hCount DECIMAL(12,4),
       @StartAt DateTime, @StartFuzzy INTEGER,
       @StartReason VARCHAR(64), @DoseCode VARCHAR(24),
       @RxText text, @TreatType char(1), @BatchId INTEGER = NULL )
AS
BEGIN
  DECLARE @TreatId INTEGER;
  DECLARE @MaxSeverity INTEGER;
  DECLARE @CanModifyDrugTreatment BIT;
  DECLARE @ErrMsg VARCHAR(512);

  SET @CanModifyDrugTreatment = 1;

  UPDATE dbo.StudCase SET LastWrite = getdate() WHERE PersonId=@PersonId;

  /* Check if user is allowed to modify drugs */
  EXEC dbo.CanModifyDrugTreatment  null, @CanModifyDrugTreatment OUTPUT, @ErrMsg OUTPUT; 
  IF  @CanModifyDrugTreatment = 0
  BEGIN
    SELECT 0 AS TreatId;
    RAISERROR( @ErrMsg, 16, 1 );
    RETURN -200;
  END;

  IF dbo.AllowDrug( @PersonId, @ATC ) = 0
  BEGIN
    RAISERROR( 'Medisinen kan ikke ordineres pga. tidligere bivirkninger.', 16, 1 );
    RETURN -1;
  END;

  /* Match on every field except StartAt/StopAt.
  Match on StartAt if batch, otherwise nStopAt IS NULL */
  SELECT @TreatId = TreatId FROM dbo.DrugTreatment
   WHERE PersonId=@PersonId AND ATC=@ATC AND DrugName=@DrugName AND DrugForm=@DrugForm
     AND Strength=@Strength AND StrengthUnit=@StrengthUnit AND Dose24hCount=@Dose24hCount AND DoseCode=@DoseCode
     AND TreatType=@TreatType AND ( StopAt IS NULL);

  /* Add this drug if not found */
  IF NOT @TreatId IS NULL
    UPDATE dbo.DrugTreatment SET RxText=@RxText,StartReason=@StartReason WHERE TreatId=@TreatId
  ELSE 
  BEGIN
    INSERT INTO dbo.DrugTreatment (PersonId,ATC,DrugName,DrugForm,Strength,StrengthUnit,
      Dose24hCount, StartAt, StartFuzzy, StartReason, DoseCode, TreatType, RxText, BatchId )
    VALUES(@PersonId,@ATC,@DrugName,@DrugForm,@Strength,@StrengthUnit,
      @Dose24hCount,@StartAt,@StartFuzzy,@StartReason,@DoseCode,@TreatType, @RxText,@BatchId );
    SET @TreatId=SCOPE_IDENTITY();
    IF @@ERROR <> 0 RETURN -ABS(@@ERROR);
    IF DATALENGTH(@StartReason)>1 EXEC dbo.AddDrugReason @ATC,1,@StartReason;
  END;
  SELECT @TreatId AS TreatId;
  RETURN @TreatId;
END
GO

ALTER PROCEDURE dbo.UpdateDrugPause @TreatId INTEGER,@PauseStatus INTEGER,
 @PauseTime DateTime = NULL, @PauseReason VARCHAR(64) = NULL
AS
BEGIN
  DECLARE @NewId INTEGER;
  DECLARE @CanModifyDrugTreatment BIT;
  DECLARE @ErrMsg VARCHAR(512);

  SET @CanModifyDrugTreatment = 1;

  EXEC dbo.CanModifyDrugTreatment  null, @CanModifyDrugTreatment OUTPUT, @ErrMsg OUTPUT;
  IF  @CanModifyDrugTreatment = 0
  BEGIN
    RAISERROR( @ErrMsg, 16, 1 );
    RETURN -200;
  END;
  
  IF @PauseTime IS NULL SET @PauseTime=getdate();
  UPDATE dbo.DrugTreatment SET PauseStatus=@PauseStatus
  WHERE TreatId=@TreatId
    AND (StopAt IS NULL OR StopAt > @PauseTime )
    AND (( PauseStatus<>@PauseStatus ) OR ( PauseStatus IS NULL));
  IF @@ROWCOUNT<>1 RETURN -2; /* No match found */
  /* Add new entry to DrugPause table */
  IF @PauseStatus=1 
  BEGIN
    INSERT INTO DrugPause (TreatId,PausedAt) VALUES (@TreatId,@PauseTime);
  END
  ELSE IF @PauseStatus=0 
  BEGIN
    UPDATE dbo.DrugPause SET RestartAt=getdate(),RestartBy=user_id()
      WHERE TreatId=@TreatId AND RestartAt IS NULL;
    IF @@ROWCOUNT<>1 RETURN -3; /* No Matching record in DrugPause */
  END
  ELSE
    RETURN -6; /* Invalid PauseStatus */
END;
GO

ALTER PROCEDURE dbo.UpdateDrugStop( @TreatId INTEGER, @StopAt DateTime, @StopFuzzy integer = 0, @StopReason VARCHAR(64) = NULL, @SaveThisReason INTEGER = 1 )
AS
BEGIN
  DECLARE @ATC VARCHAR(7);
  DECLARE @StartAt DateTime;
  DECLARE @AlreadyStopped DateTime;
  DECLARE @PersonId INTEGER;
  DECLARE @CanModifyDrugTreatment BIT;
  DECLARE @ErrMsg VARCHAR(512);

  SET @CanModifyDrugTreatment = 1;

  EXEC dbo.CanModifyDrugTreatment  null, @CanModifyDrugTreatment OUTPUT, @ErrMsg OUTPUT; 
  IF  @CanModifyDrugTreatment = 0
  BEGIN
    RAISERROR( @ErrMsg, 16, 1 );
    RETURN -200;
  END;

  SELECT @StartAt=StartAt,@AlreadyStopped=StopAt FROM dbo.DrugTreatment WHERE TreatId=@TreatId;
  IF (@StopAt<@StartAt) AND convert(int,getdate())=convert(int,@StartAt) SET @StopAt=@StartAt;
  UPDATE dbo.DrugTreatment
    SET StopAt=@StopAt,StopFuzzy=@StopFuzzy,StopReason=@StopReason,StopBy=user_id()
    WHERE TreatId=@TreatId AND ((StopAt IS NULL) or ( StopAt > @StopAt ));
  IF ( @@ROWCOUNT<>1 ) AND ( @AlreadyStopped IS NULL )
  BEGIN
    SET @ErrMsg = dbo.GetTextItem( 'UpdateDrugStop','Failed' );
    RAISERROR( @ErrMsg, 16, 1 );
    RETURN -1;
  END
  ELSE
  BEGIN
    SELECT @PersonId = PersonId FROM dbo.DrugTreatment WHERE TreatId=@TreatId;
    UPDATE dbo.StudCase SET LastWrite = getdate() WHERE PersonId=@PersonId;
    IF ( ISNULL(@StopReason,'')<>'' and @SaveThisReason=1 ) 
    BEGIN
      SELECT @ATC = ATC FROM dbo.DrugTreatment WHERE TreatId=@TreatId;
      IF DATALENGTH(@ATC) > 4 EXEC dbo.AddDrugReason @ATC,2,@StopReason
    END
  END;
END;
GO

ALTER PROCEDURE dbo.UpdateDrugStrength( @TreatId INTEGER, @NewStrength DECIMAL(12,4),@StopReason VARCHAR(64), @ChangeAt DateTime = NULL )
AS
BEGIN
  DECLARE @NewId INTEGER;
  DECLARE @CanModifyDrugTreatment BIT;
  DECLARE @ErrMsg VARCHAR(512);

  SET @CanModifyDrugTreatment = 1;

  EXEC dbo.CanModifyDrugTreatment  null, @CanModifyDrugTreatment OUTPUT, @ErrMsg OUTPUT;
  IF  @CanModifyDrugTreatment = 0
  BEGIN
    RAISERROR( @ErrMsg, 16, 1 );
    RETURN -200;
  END;

  IF @ChangeAt IS NULL SET @ChangeAt = getdate();
  EXEC dbo.UpdateDrugStop @TreatId,@ChangeAt,0,@StopReason,0;
  INSERT INTO dbo.DrugTreatment
   (PersonId,ATC,DrugName,DrugForm,Strength,Dose24hCount,
    StrengthUnit,StartAt,StartReason,RxText,TreatType,PackType,DoseCode,DoseId)
  SELECT
    PersonId,ATC,DrugName,DrugForm,@NewStrength,Dose24hCount,
    StrengthUnit,@ChangeAt,StartReason,RxText,TreatType,PackType,DoseCode,DoseId
  FROM dbo.DrugTreatment WHERE TreatId=@TreatId;
  SET @NewId=SCOPE_IDENTITY();              
  SELECT @NewId AS TreatId;
END
GO

ALTER PROCEDURE dbo.UpdateDrugTreatmentDosetteDetails( @TreatId INTEGER,
 @Dose08 DECIMAL(8,2), @Dose13 DECIMAL(8,2),
 @Dose18 DECIMAL(8,2), @Dose21 DECIMAL(8,2),
 @ChangedAt DateTime = NULL )
AS
BEGIN
  DECLARE @CanModifyDrugTreatment BIT;
  DECLARE @ErrMsg VARCHAR(512);
  DECLARE @Dose24hCount DECIMAL(12,4);
  DECLARE @CalcDose DECIMAL(12,4);
  DECLARE @DoseId INTEGER;
  DECLARE @MsgText VARCHAR(255);
  DECLARE @TreatType CHAR(1);

  SET @CanModifyDrugTreatment = 1;

  EXEC dbo.CanModifyDrugTreatment  null, @CanModifyDrugTreatment OUTPUT, @ErrMsg OUTPUT;
  IF  @CanModifyDrugTreatment = 0
  BEGIN
    RAISERROR( @ErrMsg, 16, 1 );
    RETURN -200;
  END;

  SELECT @TreatType=TreatType FROM dbo.DrugTreatment WHERE TreatId=@TreatId;
  IF @ChangedAt IS NULL SET @ChangedAt=GetDate();
  SET @DoseId = NULL;
  UPDATE dbo.DrugTreatment SET PackType='D' WHERE TreatId=@TreatId;
  /* Make sure the dose is equivalent to what we are adding here */
  SELECT @Dose24hCount = Dose24hCount FROM dbo.DrugTreatment
    WHERE ( TreatId=@TreatId ) AND (( StopAt IS NULL ) OR (StopAt>GetDate())) AND ( TreatType=@TreatType);
  IF @Dose24hCount IS NULL
    SET @MsgText = 'Treatment does not exists, is not active, or of the wrong type.'
  ELSE 
  BEGIN
    /* Calculate the dose based on given information */
    IF @Dose24hCount=0 
      SET @CalcDose = 0
    ELSE
      SET @CalcDose=@Dose08+@Dose13+@Dose18+@Dose21;
    IF ( @CalcDose<>@Dose24hCount )
      SET @MsgText = 'Daily dose invalid.  Could not set dosette details'
    ELSE 
    BEGIN
      /* Stop all earlies dosing schemes */
      EXEC dbo.DisableDrugDosingSchemes @TreatId,@ChangedAt;
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
  SELECT @DoseId AS DoseId,@MsgText AS MsgText;
END
GO

ALTER PROCEDURE dbo.UpdateDrugTreatmentMultidoseDetails( @TreatId INTEGER,
 @Dose07 DECIMAL(8,2), @Dose08 DECIMAL(8,2), @Dose13 DECIMAL(8,2),
 @Dose18 DECIMAL(8,2), @Dose21 DECIMAL(8,2), @Dose23 DECIMAL(8,2),
 @ChangedAt DateTime = NULL )
AS
BEGIN
  DECLARE @CanModifyDrugTreatment BIT;
  DECLARE @ErrMsg VARCHAR(512);
  DECLARE @Dose24hCount DECIMAL(12,4);
  DECLARE @CalcDose DECIMAL(12,4);
  DECLARE @DoseId INTEGER;
  DECLARE @MsgText VARCHAR(255);
  DECLARE @TreatType CHAR(1);
  DECLARE @PackType CHAR(1);

  SET @CanModifyDrugTreatment = 1;

  EXEC dbo.CanModifyDrugTreatment  null, @CanModifyDrugTreatment OUTPUT, @ErrMsg OUTPUT;
  IF  @CanModifyDrugTreatment = 0
  BEGIN
    RAISERROR( @ErrMsg, 16, 1 );
    RETURN -200;
  END;

  SELECT @TreatType=TreatType,@PackType=PackType FROM dbo.DrugTreatment WHERE TreatId=@TreatId;
  IF @ChangedAt IS NULL SET @ChangedAt=GetDate();
  SET @DoseId = NULL;
  SELECT @Dose24hCount = Dose24hCount FROM dbo.DrugTreatment
    WHERE ( TreatId=@TreatId ) AND (StopAt IS NULL ) AND ( TreatType = @TreatType );
  IF @Dose24hCount IS NULL
    SET @MsgText = 'Treatment does not exists, is not active, or of the wrong type.'
  ELSE 
  BEGIN
    /* Calculate the dose based on given information */
    IF @Dose24hCount=0 
      SET @CalcDose = 0
    ELSE
      SET @CalcDose=@Dose07+@Dose08+@Dose13+@Dose18+@Dose21+@Dose23;
    /* Make sure the existing dose is equivalent to what we are adding here */
    IF ( @CalcDose<>@Dose24hCount )
      SET @MsgText = 'Daily dose mismatch.  Could not set dose details.'
    ELSE 
    BEGIN
      /* Stop all earlier dosing schemes, regardless of type */
      EXEC dbo.DisableDrugDosingSchemes @TreatId,@ChangedAt;
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
  SELECT @DoseId AS DoseId, @MsgText AS MsgText;
END
GO

ALTER PROCEDURE dbo.UpdateDrugTreatmentWeekDetails( @TreatId INTEGER,
 @DoseHour INTEGER,
 @DoseMon DECIMAL(8,2), @DoseTue DECIMAL(8,2), @DoseWed DECIMAL(8,2),
  @DoseThu DECIMAL(8,2), @DoseFri DECIMAL(8,2), @DoseSat DECIMAL(8,2),
  @DoseSun DECIMAL(8,2), @ChangedAt DateTime = NULL )
AS
BEGIN
  DECLARE @CanModifyDrugTreatment BIT;
  DECLARE @ErrMsg VARCHAR(512);
  DECLARE @Dose24hCount DECIMAL(12,4);
  DECLARE @CalcDose DECIMAL(12,4);
  DECLARE @DoseId INTEGER;
  DECLARE @MsgText VARCHAR(255);
  DECLARE @PackType CHAR(1);

  SET @CanModifyDrugTreatment = 1;

  EXEC dbo.CanModifyDrugTreatment  null, @CanModifyDrugTreatment OUTPUT, @ErrMsg OUTPUT;
  IF  @CanModifyDrugTreatment = 0
  BEGIN
    RAISERROR( @ErrMsg, 16, 1 );
    RETURN -200;
  END;

  SELECT @PackType = PackType FROM dbo.DrugTreatment WHERE TreatId=@TreatId;
  UPDATE dbo.DrugTreatment SET TreatType='U' WHERE TreatId=@TreatId;
  IF @ChangedAt IS NULL SET @ChangedAt=GetDate();
  /* Make sure the existing dose is equivalent to what we are adding here */
  SET @CalcDose=(@DoseMon+@DoseTue+@DoseWed+@DoseThu+@DoseFri+@DoseSat+@DoseSun)/7;
  /* Stop all earlier dosing schemes, regardless of type */
  EXEC dbo.DisableDrugDosingSchemes @TreatId,@ChangedAt;
  /* Add a new dosing scheme to DrugDosing */
  INSERT INTO dbo.DrugDosing (TreatId,PackType,ValidFrom,DoseHour,
    DoseMon,DoseTue,DoseWed,DoseThu,DoseFri,DoseSat,DoseSun,TreatType)
    VALUES (@TreatId,'M',@ChangedAt,@DoseHour,
      @DoseMon,@DoseTue,@DoseWed,@DoseThu,@DoseFri,@DoseSat,@DoseSun,'U');
  SET @DoseId=SCOPE_IDENTITY();
  UPDATE dbo.DrugTreatment SET DoseId=@DoseId WHERE TreatId=@TreatId;
  SET @MsgText='OK';
  SELECT ISNULL(@DoseId,-1),@MsgText;
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6043;
GO

COMMIT TRANSACTION UpgradeTo6043;
GO



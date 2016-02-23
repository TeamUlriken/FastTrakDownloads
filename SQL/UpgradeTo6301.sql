-- Upgrade type: Hotfix.
-- Purpose of this upgrade:
--- Altered procedure CRF.UpdateClinForm to sign the items on the form (Bugfix)
--- Altered procedure CRF.UpdateClinForm moving search for PersonId/StudyId into first query (Tweak)
--- Altered procedure dbo.GetStudyAndUser to return updated error messages and phone numbers etc.
--- Altered function dbo.GetLastCompleteForm to exclude deleted forms.
--- Altered function dbo.AddDrug to allow starting a drug earlier than first planned.

SET NOEXEC OFF;
IF dbo.DbVersion() <> 6300
BEGIN
  PRINT 'Wrong database version: ' + CONVERT(VARCHAR, dbo.DbVersion()) + '!'
  SET NOEXEC ON;
END
ELSE
  PRINT 'Starting upgrade to 6301'
GO

BEGIN TRANSACTION UpgradeTo6301

EXECUTE DbStartUpgrade 6301;
GO

ALTER PROCEDURE CRF.UpdateClinForm (@ClinFormId INT, @FormComment VARCHAR(MAX), @FormStatus CHAR(1), @FormComplete TINYINT) AS
BEGIN
  DECLARE @StudyId INT;
  DECLARE @PersonId INT;
  DECLARE @EventId INT;
  DECLARE @OldFormStatus CHAR(1);
  DECLARE @OldFormComplete TINYINT;
  DECLARE @FormTitle VARCHAR(128);

  SET NOCOUNT ON;

  -- Get current status details about person/study
  SELECT @StudyId = ce.StudyId, @PersonId = ce.PersonId, @EventId = ce.EventId, @OldFormStatus = cf.FormStatus, @OldFormComplete = cf.FormComplete, @FormTitle = mf.FormTitle
  FROM dbo.ClinForm cf
  JOIN dbo.ClinEvent ce ON ce.EventId = cf.EventId
  JOIN dbo.MetaForm mf ON mf.FormId = cf.FormId
  WHERE ClinFormId = @ClinFormId;

  -- Check for signed forms
  IF (@OldFormStatus = 'L')
  BEGIN
    RAISERROR ('%s er signert og kan ikke endres.', 16, 1, @FormTitle);
    RETURN -2;
  END
  ELSE
  BEGIN
    IF (@FormStatus = 'L')
    BEGIN
      -- Check form signing privileges for profession 
      IF dbo.HasSignClinFormPrivilege(@ClinFormId, NULL) <> 1
      BEGIN
        RAISERROR ('Du har ikke rettigheter til å signere %s!', 16, 1, @FormTitle);
        RETURN -1;
      END;
      EXEC CRF.UpdateClinFormSignItems @ClinFormId;
    END;

    -- Update form properties
    UPDATE dbo.ClinForm
    SET FormComplete = @FormComplete,
        FormStatus = @FormStatus,
        Comment = @FormComment
    WHERE ClinFormId = @ClinFormId;

    -- Sign form if status is locked
    IF @FormStatus = 'L'
      UPDATE dbo.ClinForm
      SET SignedAt = GETDATE(),
          SignedBy = USER_ID()
      WHERE ClinFormId = @ClinFormId;

    -- Update StudCase with LastWrite
    UPDATE dbo.StudCase
    SET LastWrite = GETDATE()
    WHERE StudyId = @StudyId
    AND PersonId = @PersonId;

  END;
END
GO

ALTER PROCEDURE dbo.GetStudyAndUser (@StudyName VARCHAR(40)) AS
BEGIN
  DECLARE @StudyId INT;
  DECLARE @UserId INT;
  DECLARE @UserName NVARCHAR(128);
  DECLARE @RealName NVARCHAR(128);

  SET NOCOUNT ON;

  -- User validation
  IF ISNULL(USER_ID(), 0) = 0
  BEGIN
    RAISERROR (N'Du mangler dessverre en brukerkonto i systemet. Be en superbruker\nom å legge deg til som bruker i applikasjonen!', 16, 1);
    RETURN -4;
  END;
  SET @RealName = USER_NAME();
  SELECT @UserId = UserId, @UserName = ISNULL(UserName, '(mangler)')
  FROM dbo.UserList
  WHERE UserId = USER_ID();
  IF @UserId IS NULL
  BEGIN
    SET @UserId = USER_ID();
    SET @UserName = @RealName;
    INSERT INTO dbo.UserList (UserId, UserName)
      VALUES (@UserId, @UserName)
  END
  ELSE
  IF (@UserName <> @RealName)
    OR (@UserName IS NULL)
  BEGIN
    RAISERROR (N'Forventet [%s] og virkelig brukernavn [%s] er forskjellig.\nDu kan ikke bruke applikasjonen før dette er rettet.\nDu bør kontakte DIPS ASA på telefon 45064040 snarest!', 16, 1, @UserName, @RealName)
    RETURN -1;
  END;

  -- StudyName validation
  IF ISNULL(@StudyName, '') = ''
  BEGIN
    RAISERROR (N'Fagjournal er ikke spesifisert!', 16, 1);
    RETURN -2;
  END;
  SELECT @StudyId = StudyId
  FROM dbo.Study
  WHERE StudyName = @StudyName;
  IF @StudyId IS NULL
  BEGIN
    RAISERROR (N'Fagjournalen "%s" mangler i denne databasen!\nDenne må lisensieres separat fra DIPS ASA.', 16, 1, @StudyName);
    RETURN -3;
  END;

  -- Return details about user and study
  SELECT s.StudyId, p.*, mp.*, c.*, sg.*, su.ShowMyGroup, su.CaseList, USER_ID() AS UserId, USER_NAME() AS UserName
  FROM dbo.Study s
  LEFT JOIN dbo.UserList ul ON ul.UserId = USER_ID()
  LEFT JOIN dbo.Person p ON p.PersonId = ul.PersonId
  LEFT JOIN dbo.StudyCenter c ON c.CenterId = ul.CenterId
  LEFT JOIN dbo.StudyUser su ON su.UserId = ul.UserId AND su.StudyId = s.StudyId
  LEFT JOIN dbo.StudyGroup sg ON sg.GroupId = su.GroupId AND sg.StudyId = s.StudyId
  LEFT JOIN dbo.MetaProfession mp ON mp.ProfId = ul.ProfId
  WHERE s.StudyId = @StudyId;
END
GO

ALTER FUNCTION dbo.GetLastCompleteForm (@StudyId INT, @PersonId INT, @FormName VARCHAR(24))
RETURNS DATETIME AS
BEGIN
  DECLARE @LastFormDate DATETIME;
  SELECT @LastFormDate = MAX(ce.EventTime)
  FROM dbo.ClinEvent ce
  JOIN dbo.ClinForm cf ON (cf.EventId = ce.EventId) AND (ce.StudyId = @StudyId) AND (ce.PersonId = @PersonId) AND (cf.DeletedAt IS NULL) AND (cf.FormComplete = 100)
  JOIN dbo.MetaForm mf ON mf.FormId = cf.FormId AND mf.FormName = @FormName;
  RETURN @LastFormDate;
END
GO

ALTER PROCEDURE dbo.AddDrug (@PersonId INTEGER, @ATC VARCHAR(7), @DrugName VARCHAR(64), @DrugForm VARCHAR(64), @Strength DECIMAL(12, 4), @StrengthUnit VARCHAR(24), @Dose24hCount DECIMAL(12, 4), @StartAt DATETIME, @StartFuzzy INTEGER, @StartReason VARCHAR(64), @DoseCode
VARCHAR(24), @RxText VARCHAR(MAX), @TreatType CHAR(1), @BatchId INTEGER = NULL) AS
BEGIN
  DECLARE @TreatId INTEGER;
  DECLARE @OldStartAt DATETIME;
  DECLARE @MaxSeverity INTEGER;
  DECLARE @CanModifyDrugTreatment BIT;
  DECLARE @ErrMsg VARCHAR(512);

  SET NOCOUNT ON;

  SET @CanModifyDrugTreatment = 1;

  UPDATE dbo.StudCase
  SET LastWrite = GETDATE()
  WHERE PersonId = @PersonId;

  /* Check if user is allowed to modify drugs */
  EXEC dbo.CanModifyDrugTreatment NULL,
                                  @CanModifyDrugTreatment OUTPUT,
                                  @ErrMsg OUTPUT;
  IF @CanModifyDrugTreatment = 0
  BEGIN
    SELECT 0 AS TreatId;
    RAISERROR (@ErrMsg, 16, 1);
    RETURN -200;
  END;

  IF dbo.AllowDrug(@PersonId, @ATC) = 0
  BEGIN
    RAISERROR ('Du kan ikke ordinere %s %s pga. tidligere bivirkninger av tilsvarende preparat!', 16, 1, @ATC, @DrugName);
    RETURN -1;
  END;

  /* Match on every field except StartAt/StopAt. Match on StartAt if batch, otherwise on StopAt IS NULL */

  SELECT @TreatId = TreatId, @OldStartAt = StartAt
  FROM dbo.DrugTreatment
  WHERE PersonId = @PersonId AND ATC = @ATC AND DrugName = @DrugName AND DrugForm = @DrugForm
  AND Strength = @Strength AND StrengthUnit = @StrengthUnit AND Dose24hCount = @Dose24hCount AND DoseCode = @DoseCode AND TreatType = @TreatType
  AND (StopAt IS NULL);

  IF @OldStartAt < GETDATE()
    SET @StartAt = @OldStartAt;

  IF DATALENGTH(@StartReason) > 2
    EXEC dbo.AddDrugReason @ATC,
                           1,
                           @StartReason;

  IF NOT @TreatId IS NULL
    UPDATE dbo.DrugTreatment
    SET StartAt = @StartAt,
        RxText = @RxText,
        StartReason = @StartReason
    WHERE (TreatId = @TreatId)
    AND ((StartAt <> @StartAt)
    OR (ISNULL(RxText, '') <> ISNULL(@RxText, ''))
    OR (ISNULL(StartReason, '') <> ISNULL(@StartReason, '')))
  ELSE
  BEGIN
    /* Add this drug if not found */
    INSERT INTO dbo.DrugTreatment (PersonId, ATC, DrugName, DrugForm, Strength, StrengthUnit, Dose24hCount, StartAt, StartFuzzy, StartReason, DoseCode, TreatType, RxText, BatchId)
      VALUES (@PersonId, @ATC, @DrugName, @DrugForm, @Strength, @StrengthUnit, @Dose24hCount, @StartAt, @StartFuzzy, @StartReason, @DoseCode, @TreatType, @RxText, @BatchId);
    SET @TreatId = SCOPE_IDENTITY();
    IF @@ERROR <> 0
      RETURN -ABS(@@ERROR);
  END;
  SELECT @TreatId AS TreatId;
  RETURN @TreatId;
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6301;
GO

COMMIT TRANSACTION UpgradeTo6301;
GO
BEGIN TRY
  ALTER TABLE dbo.ClinDataPointDeleted DROP CONSTRAINT FK_ClinDataPointDeleted_ClinFormId;
  ALTER TABLE dbo.ClinDataPointDeleted DROP CONSTRAINT FK_ClinDataPointDeleted_TouchId;
  ALTER TABLE dbo.ClinDataPointDeleted DROP CONSTRAINT FK_ClinDataPointDeleted_EventId
END TRY
BEGIN CATCH
    PRINT 'Constraints er allerede fjernet.'
END CATCH;
GO

ALTER PROCEDURE dbo.DeleteAllClinicalData ( @PersonId INT, @DOB DATETIME, @ReasonText VARCHAR(MAX) ) AS
BEGIN
  SET XACT_ABORT ON;
  IF NOT EXISTS (SELECT 1
      FROM dbo.Person
      WHERE PersonId = @PersonId
      AND DOB = @DOB)
  BEGIN
    RAISERROR ('Ikke samsvar mellom PersonId og fødselsdato. Sletting kan ikke utføres!', 16, 1);
    RETURN -1;
  END;
  BEGIN TRANSACTION DeletePatientClinicalData;
  BEGIN TRY
    DELETE FROM dbo.ClinRelation
    WHERE PersonId = @PersonId;
    DELETE FROM dbo.LabData
    WHERE PersonId = @PersonId
    DELETE FROM dbo.DrugPause
    WHERE TreatId IN (SELECT TreatId
        FROM dbo.DrugTreatment
        WHERE PersonId = @PersonId)
    DELETE FROM dbo.DrugDosing
    WHERE TreatId IN (SELECT TreatId
        FROM dbo.DrugTreatment
        WHERE PersonId = @PersonId)
    DELETE FROM dbo.DrugPrescription
    WHERE TreatId IN (SELECT TreatId
        FROM dbo.DrugTreatment
        WHERE PersonId = @PersonId)
    DELETE FROM dbo.DrugTreatment
    WHERE PersonId = @PersonId;
    DELETE FROM dbo.ClinProblem
    WHERE PersonId = @PersonId;
    DELETE FROM dbo.ClinFormLog
    WHERE ClinFormId IN (SELECT ClinFormId
        FROM dbo.ClinForm cf
        JOIN dbo.ClinEvent ce
          ON ce.EventId = cf.EventId
        WHERE ce.PersonId = @PersonId)
    DELETE FROM dbo.ClinForm
    WHERE EventId IN (SELECT EventId
        FROM dbo.ClinEvent
        WHERE PersonId = @PersonId)
    DELETE FROM dbo.ClinLog
    WHERE RowId IN (SELECT RowId
        FROM dbo.ClinDatapoint cdp
        JOIN dbo.ClinEvent ce
          ON ce.EventId = cdp.EventId
        WHERE ce.PersonId = @PersonId);

    -- Disable trigger to stop deleted datapoints from being stored in ClinDataPointDeleted.
    DISABLE TRIGGER T_ClinDataPoint_Update
    ON dbo.ClinDataPoint;
    DELETE FROM dbo.ClinDatapoint
    WHERE EventId IN (SELECT EventId
        FROM dbo.ClinEvent
        WHERE PersonId = @PersonId);
    ENABLE TRIGGER T_ClinDataPoint_Update
    ON dbo.ClinDataPoint;

    DELETE FROM dbo.ClinTouch
    WHERE EventId IN (SELECT EventId
        FROM dbo.ClinEvent
        WHERE PersonId = @PersonId);
    DELETE FROM dbo.ClinEvent
    WHERE PersonId = @PersonId;
    DELETE FROM dbo.CaseLog
    WHERE PersonId = @PersonId;
    DELETE FROM dbo.StudCase
    WHERE PersonId = @PersonId;
    DELETE FROM dbo.DSSRuleExecute
    WHERE PersonId = @PersonId;
    IF NOT EXISTS (SELECT PersonId
        FROM dbo.UserList
        WHERE PersonId = @PersonId)
      DELETE FROM dbo.Person
      WHERE PersonId = @PersonId;
    INSERT INTO dbo.ClinicalDataDeletion (PersonId, ReasonText)
      VALUES (@PersonId, @ReasonText);
    COMMIT TRANSACTION DeletePatientClinicalData;
  END TRY
  BEGIN CATCH
    PRINT 'Sletting ble ikke utført.'
    ROLLBACK TRANSACTION;
  END CATCH;
END
GO
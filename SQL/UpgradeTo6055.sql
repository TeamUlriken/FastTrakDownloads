SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6055
PRINT 'Starting upgrade to 6055'

DELETE FROM DbUpgradeLog
WHERE  DbVer > 6054;

EXEC DbCheckVersion 6054;
EXECUTE DbStartUpgrade 6055;
GO

IF OBJECT_ID('ClinicalDataDeletion') IS NULL
BEGIN

  CREATE TABLE dbo.ClinicalDataDeletion( 
  LogId INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
  PersonId INT NOT NULL, 
  ReasonText VARCHAR(MAX) NOT NULL, 
  DeletedAt DateTime NOT NULL CONSTRAINT DF_ClinicalDataDeletion_DeletedAt DEFAULT GETDATE(),
  DeletedBy INT NOT NULL CONSTRAINT DF_ClinicalDataDeletion_DeletedBy DEFAULT USER_ID() )

  ALTER TABLE dbo.ClinicalDataDeletion ADD CONSTRAINT FK_ClinicalDataDeletion_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.UserList (UserId)

END
GO

IF NOT OBJECT_ID('DeleteAllClinicalData') IS NULL
  DROP PROCEDURE dbo.DeleteAllClinicalData
GO

CREATE PROCEDURE dbo.DeleteAllClinicalData( @PersonId INT, @DOB DateTime, @ReasonText VARCHAR(MAX) ) AS
BEGIN
  SET XACT_ABORT ON;
  IF NOT EXISTS( SELECT 1 FROM Person WHERE PersonId=@PersonId AND DOB=@DOB )
  BEGIN
    RAISERROR( 'Ikke samsvar mellom DOB og PersonId. Sletting kan ikke utføres!', 16, 1 );
    RETURN -1;
  END;
  BEGIN TRANSACTION DeletePatientClinicalData;
  DELETE FROM dbo.ClinRelation WHERE PersonId=@PersonId;
  DELETE FROM dbo.LabData WHERE PersonId=@PersonId
  DELETE FROM dbo.DrugPause WHERE TreatId IN (SELECT TreatId FROM dbo.DrugTreatment WHERE PersonId=@PersonId)
  DELETE FROM dbo.DrugDosing WHERE TreatId IN (SELECT TreatId FROM dbo.DrugTreatment WHERE PersonId=@PersonId)
  DELETE FROM dbo.DrugPrescription WHERE TreatId IN (SELECT TreatId FROM dbo.DrugTreatment WHERE PersonId=@PersonId)
  DELETE FROM dbo.DrugTreatment WHERE PersonId=@PersonId;
  DELETE FROM dbo.ClinProblem WHERE PersonId=@PersonId;
  DELETE FROM dbo.ClinFormLog WHERE ClinFormId IN ( SELECT ClinFormId FROM dbo.ClinForm cf JOIN dbo.ClinEvent ce ON ce.EventId=cf.EventId WHERE ce.PersonId=@PersonId)
  DELETE FROM dbo.ClinForm WHERE EventId IN ( SELECT EventId FROM dbo.ClinEvent WHERE PersonId=@PersonId)
  DELETE FROM dbo.ClinLog WHERE RowId IN (SELECT RowId FROM dbo.ClinDatapoint cdp JOIN dbo.ClinEvent ce ON ce.EventId=cdp.EventId WHERE ce.PersonId=@PersonId);
  DELETE FROM dbo.ClinDatapoint WHERE EventId IN (SELECT EventId FROM dbo.ClinEvent where PersonId=@PersonId);
  DELETE FROM dbo.ClinTouch WHERE EventId IN (SELECT EventId FROM dbo.ClinEvent where PersonId=@PersonId);
  DELETE FROM dbo.ClinEvent WHERE PersonId=@PersonId;
  DELETE FROM dbo.CaseLog WHERE PersonId=@PersonId;
  DELETE FROM dbo.StudCase where PersonId=@PersonId;
  DELETE FROM dbo.DSSRuleExecute WHERE PersonId=@PersonId;
  IF NOT EXISTS( SELECT PersonId FROM UserList WHERE PersonId=@PersonId )
    DELETE FROM dbo.Person WHERE PersonId=@PersonId;
  INSERT INTO dbo.ClinicalDataDeletion( PersonId, ReasonText ) VALUES ( @PersonId, @ReasonText );
  COMMIT TRANSACTION DeletePatientClinicalData;
END
GO

GRANT EXECUTE ON dbo.DeleteAllClinicalData to [superuser] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6055;
GO

COMMIT TRANSACTION UpgradeTo6055;
GO

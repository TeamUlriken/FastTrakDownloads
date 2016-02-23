BEGIN TRANSACTION UpgradeTo6024
PRINT 'Starting upgrade to 6024'

DELETE FROM DbUpgradeLog WHERE DbVer > 6023;

EXEC DbCheckVersion 6023;
EXECUTE DbStartUpgrade 6024;
GO

EXEC dbo.UtilDropObject 'UpdateDemographics'
GO

CREATE PROCEDURE dbo.UpdateDemographics (@NationalId VARCHAR (16), @DeceasedDate DateTime, @DeceasedInd BIT,
  @StreetAddress VARCHAR (64), @PostalCode VARCHAR (12), @City VARCHAR (32), 
  @KommuneNr VARCHAR (8), @KommuneNavn VARCHAR (32), @FylkeNr VARCHAR (8), @FylkeNavn VARCHAR (32) )
AS
BEGIN
  -- Update Deceased status
  UPDATE dbo.Person SET DeceasedInd = @DeceasedInd, DeceasedDate = @DeceasedDate
  WHERE NationalId = @NationalId;
  -- Update address for non-deceased only
  IF @DeceasedInd = 0 
    UPDATE dbo.Person
    SET StreetAddress = NULLIF(@StreetAddress,''),
        PostalCode = NULLIF(@PostalCode,''),
        City = NULLIF(@City,''),
        KommuneNr = NULLIF(@KommuneNr,''),
        KommuneNavn = NULLIF(@KommuneNavn,''),
        FylkeNr = NULLIF(@FylkeNr,''),
        FylkeNavn = NULLIF(@FylkeNavn,'')
    WHERE NationalId = @NationalId;

  UPDATE dbo.LivingStatusCheck
     SET LastChecked = GetDate()
  WHERE NationalId = @NationalId;

  -- If nothing affected, insert row for check
  IF @@ROWCOUNT = 0
     INSERT INTO dbo.LivingStatusCheck (NationalId, LastChecked)
     VALUES (@NationalId, GetDate())
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6024;
GO

COMMIT TRANSACTION UpgradeTo6024;
GO


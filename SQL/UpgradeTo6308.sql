SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6308
GO

PRINT 'Overall purpose: Add procedure to update address info'

--  CREATE procedure dbo.UpdatePersonContactInfo to support extended DIPS integration. 

EXECUTE dbo.DbStartUpgrade 6307, 6308;
GO

PRINT '--  CREATE procedure dbo.UpdatePersonContactInfo to support extended DIPS integration. '

IF NOT OBJECT_ID('UpdatePersonContactInfo') IS NULL
  DROP PROCEDURE dbo.UpdatePersonContactInfo
GO

CREATE PROCEDURE dbo.UpdatePersonContactInfo ( @NationalId VARCHAR(16), @GSM VARCHAR(16), @StreetAddress VARCHAR(64), @PostalCode VARCHAR(12), @City VARCHAR(32), @KommuneNr VARCHAR(8), @KommuneNavn VARCHAR(32) ) AS
BEGIN
  UPDATE dbo.Person
  SET StreetAddress = @StreetAddress, PostalCode = @PostalCode, City = @City, KommuneNr = @KommuneNr, KommuneNavn = @KommuneNavn
  WHERE NationalId = @NationalId;
  IF @GSM <> ''
    UPDATE dbo.Person
    SET GSM = @GSM
    WHERE GSM <> @GSM
    AND NationalId = @NationalId
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6308;
GO

COMMIT TRANSACTION UpgradeTo6308;
GO
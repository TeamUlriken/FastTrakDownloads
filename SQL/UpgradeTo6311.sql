SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6311
GO

PRINT 'Overall purpose: Add GetLastQuantityTable for reporting/populations. Bugfixes.'

--  CREATE table function dbo.GetLastQuantityTable for easy cross-sectional reporting on quantity variables.
--  UPDATE UserRoleInfo, change misleading caption and text related to role ReadOnly.
--  CREATE PROCEDURE UpdateCaseTransfer to allow single-operation transfer of patients between institutions.

EXECUTE dbo.DbStartUpgrade 6310, 6311;
GO

PRINT '--  CREATE table function dbo.GetLastQuantityTable for easy cross-sectional reporting on quantity variables.'
GO

IF NOT OBJECT_ID('dbo.GetLastQuantityTable') IS NULL
  DROP FUNCTION dbo.GetLastQuantityTable
GO

CREATE FUNCTION dbo.GetLastQuantityTable ( @ItemId INT, @EndTime DATETIME = NULL )
RETURNS @LastQuantities TABLE (
  PersonId INT NOT NULL,
  EventTime DATETIME NOT NULL,
  Quantity DECIMAL(18, 4) NOT NULL
) AS
BEGIN
  SELECT @EndTime = ISNULL(@EndTime, GETDATE() + 1);
  INSERT @LastQuantities
    SELECT a.PersonId, a.EventTime, a.Quantity
    FROM (SELECT ce.PersonId, ce.EventTime, cdp.Quantity, RANK()
        OVER (
        PARTITION BY ce.PersonId
        ORDER BY ce.EventTime DESC) AS OrderNo
      FROM dbo.ClinEvent ce
      JOIN dbo.ClinDataPoint cdp
        ON cdp.EventId = ce.EventId AND ce.EventTime < @EndTime
      WHERE cdp.ItemId = @ItemId
      AND NOT cdp.Quantity IS NULL) a
    WHERE a.OrderNo = 1;
  RETURN;
END
GO

PRINT '--  UPDATE UserRoleInfo, change misleading caption and text related to role ReadOnly.'
GO

GRANT UPDATE ON dbo.UserRoleInfo TO [public] AS [dbo]
GO

SET NOCOUNT ON
UPDATE dbo.UserRoleInfo
SET RoleCaption = 'Skrivesperre', RoleInfo = 'Hindrer brukeren i å registrere data i journalen.'
WHERE RoleName = 'ReadOnly'
GO

REVOKE UPDATE ON dbo.UserRoleInfo TO [public]
GO

PRINT '--  CREATE PROCEDURE UpdateCaseTransfer to allow single-operation transfer of patients between institutions.'
GO

IF NOT OBJECT_ID('UpdateCaseTransfer','P') IS NULL
  DROP PROCEDURE dbo.UpdateCaseTransfer
GO

CREATE PROCEDURE dbo.UpdateCaseTransfer( @StudyId INT, @PersonId INT, @GroupId INT, @StatusId INT ) AS
BEGIN
  SET NOCOUNT ON;
  UPDATE dbo.StudCase SET GroupId=@GroupId, FinState = @StatusId 
  WHERE StudyId=@StudyId AND PersonId=@PersonId;
END
GO

GRANT EXECUTE ON dbo.UpdateCaseTransfer TO [public] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6311;
GO

COMMIT TRANSACTION UpgradeTo6311;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6311
GO

PRINT 'Overall purpose: Add GetLastQuantityTable for reporting/populations.'

--  CREATE table function dbo.GetLastQuantityTable for easy cross-sectional reporting on quantity variables.

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

EXECUTE dbo.DbFinalizeUpgrade 6311;
GO

COMMIT TRANSACTION UpgradeTo6311;
GO
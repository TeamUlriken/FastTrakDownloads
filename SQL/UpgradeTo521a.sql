IF NOT OBJECT_ID('dbo.GetLastQuantityInThePast') IS NULL DROP FUNCTION dbo.GetLastQuantityInThePast
GO

CREATE FUNCTION dbo.GetLastQuantityInThePast( @PersonId INT, @VarName VARCHAR(24), @StatusDate DateTime ) RETURNS DECIMAL(18,4)
AS
BEGIN
 DECLARE @RetVal DECIMAL(18,4);
 DECLARE @EventNum INTEGER;
 SET @EventNum = dbo.FnEventTimeToNum( @StatusDate );
 SET @RetVal = ( SELECT TOP 1 co.Quantity FROM ClinObservation co
   JOIN dbo.ClinEvent ce ON ce.EventId=co.EventId
   JOIN dbo.ClinTouch ct ON ct.TouchId=co.TouchId
   JOIN dbo.ClinForm cf ON cf.EventId=ct.EventId AND cf.FormId=ct.FormId AND cf.DeletedAt IS NULL
   WHERE ( ce.PersonId=@PersonId ) AND (ce.EventNum <=@EventNum) AND ( co.VarName=@VarName ) AND ISNULL(co.Quantity,-1)>=0
   ORDER BY ce.EventNum DESC );
 RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.GetLastQuantityInThePast to [public] AS [dbo]
GO

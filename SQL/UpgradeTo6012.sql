SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6012
PRINT 'Starting upgrade to 6012'

DELETE FROM DbUpgradeLog WHERE DbVer > 6011;

EXEC DbCheckVersion 6011;
EXECUTE DbStartUpgrade 6012;
GO

IF NOT OBJECT_ID('CRF.AddClinDataEnum' ) IS NULL DROP PROCEDURE CRF.AddClinDataEnum
IF NOT OBJECT_ID('dbo.AddClinDataEnum' ) IS NULL DROP PROCEDURE dbo.AddClinDataEnum
GO

CREATE PROCEDURE [CRF].[AddClinDataEnum] ( @TouchId INT, @ItemId INT, @EnumVal int )
AS
BEGIN
  DECLARE @Locked INT;
  DECLARE @RowId INT;
  DECLARE @OldEnumVal INT;
  DECLARE @OldTouchId INT; 
  DECLARE @EventId INT;
  SELECT @EventId = EventId FROM ClinTouch WHERE TouchId=@TouchId;
  -- Get existing data
  SELECT @RowId = RowId, @Locked=Locked, @OldEnumVal=EnumVal, @OldTouchId = TouchId
    FROM dbo.ClinDatapoint WHERE EventId=@EventId AND ItemId = @ItemId;
  -- Add if not found
  IF ( @RowId IS NULL )
    INSERT INTO dbo.ClinDataPoint ( TouchId,EventId,ItemId,EnumVal,Quantity ) VALUES ( @TouchId, @EventId, @ItemId, @EnumVal, @EnumVal )
  ELSE IF @OldEnumVal <> @EnumVal 
  BEGIN
    -- Need to change
    IF @Locked <> 0
    BEGIN
     RAISERROR( 'Could not save data.  This row is signed.', 16, 1 );
     RETURN -2;
    END;
    BEGIN
	  -- Write to log
	  IF @TouchId <> @OldTouchId 
	  BEGIN
        INSERT INTO dbo.ClinLog( RowId,TouchId,ObsDate,Quantity,DTVal,EnumVal,TextVal )
        SELECT co.RowId,co.TouchId,co.ObsDate,co.Quantity,co.DTVal,co.EnumVal,co.TextVal 
        FROM dbo.ClinDatapoint co WHERE co.RowId=@RowId;
	  END;
	  -- Set new value
	  UPDATE dbo.ClinDataPoint SET TouchId=@TouchId,EnumVal=@EnumVal,Quantity=@EnumVal,ChangeCount=ChangeCount + 1, ObsDate=getdate() 
	  WHERE RowId=@RowId;
    END
  END
END
GO
                
GRANT EXECUTE ON CRF.AddClinDataEnum TO [public] AS [dbo]
GO
        

IF NOT OBJECT_ID('CRF.AddClinDataQuantity' ) IS NULL DROP PROCEDURE CRF.AddClinDataQuantity
IF NOT OBJECT_ID('dbo.AddClinDataQuantity' ) IS NULL DROP PROCEDURE dbo.AddClinDataQuantity
GO

CREATE PROCEDURE [CRF].[AddClinDataQuantity] ( @TouchId INT, @ItemId INT, @Quantity FLOAT )
AS
BEGIN
  DECLARE @Locked INT;
  DECLARE @RowId INT;
  DECLARE @OldQuantity FLOAT;
  DECLARE @OldTouchId INT; 
  DECLARE @EventId INT;
  SELECT @EventId = EventId FROM ClinTouch WHERE TouchId=@TouchId;
  -- Get existing data
  SELECT @RowId = RowId, @Locked=Locked, @OldQuantity=Quantity, @OldTouchId = TouchId
    FROM dbo.ClinDatapoint WHERE EventId=@EventId AND ItemId = @ItemId;
  -- Add if not found
  IF ( @RowId IS NULL )
    INSERT INTO dbo.ClinDataPoint ( TouchId,EventId,ItemId,Quantity ) VALUES ( @TouchId, @EventId, @ItemId, @Quantity )
  ELSE IF @OldQuantity <> @Quantity 
  BEGIN
    -- Need to change
    IF @Locked <> 0
    BEGIN
     RAISERROR( 'Could not save data.  This row is signed.', 16, 1 );
     RETURN -2;
    END;
    BEGIN
	  -- Write to log
	  IF @TouchId <> @OldTouchId 
	  BEGIN
        INSERT INTO dbo.ClinLog( RowId,TouchId,ObsDate,Quantity,DTVal,EnumVal,TextVal )
        SELECT co.RowId,co.TouchId,co.ObsDate,co.Quantity,co.DTVal,co.EnumVal,co.TextVal 
        FROM dbo.ClinDatapoint co WHERE co.RowId=@RowId;
	  END;
	  -- Set new value
	  UPDATE dbo.ClinDataPoint SET TouchId=@TouchId,Quantity=@Quantity,ChangeCount=ChangeCount + 1, ObsDate=getdate() 
	  WHERE RowId=@RowId;
    END
  END
END
GO
                
GRANT EXECUTE ON CRF.AddClinDataQuantity TO [public] AS [dbo]
GO
        
IF NOT OBJECT_ID('CRF.GetImportSpec' ) IS NULL DROP PROCEDURE CRF.GetImportSpec
GO

CREATE PROCEDURE CRF.GetImportSpec( @FormId INT ) AS
BEGIN
  SELECT fi.OrderNumber,i.ItemId,fi.ItemText,i.ItemType,i.VarName,
  fi.MinExpression,fi.MaxExpression, MIN(ia.OrderNumber) as MinOrder, MAX(ia.OrderNumber) AS MaxOrder
  FROM dbo.MetaItem i 
  LEFT OUTER JOIN dbo.MetaItemAnswer ia ON ia.ItemId=i.ItemId 
  JOIN dbo.MetaFormItem fi ON fi.ItemId=i.ItemId 
  WHERE fi.FormId=@FormId
  GROUP BY 
    fi.OrderNumber,i.ItemId,fi.ItemText,i.ItemType,i.VarName,
    fi.MinExpression,fi.MaxExpression
  ORDER BY fi.OrderNumber
END
GO


GRANT EXECUTE ON CRF.GetImportSpec TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('CRF.GetOldData' ) IS NULL DROP PROCEDURE CRF.GetOldData
GO

CREATE PROCEDURE CRF.GetOldData( @StudyId INT, @PersonId INT, @EventNum INT, @FormId INT )
AS
BEGIN
  SELECT mi.ItemId,co.VarName,co.Quantity,co.EnumVal,co.DTVal,co.TextVal 
  FROM dbo.ClinObservation co
  JOIN dbo.ClinEvent ce ON ce.EventId=co.EventId
  JOIN dbo.ClinForm cf ON cf.EventId=ce.EventId
  JOIN dbo.MetaFormItem mfi ON mfi.FormId=cf.FormId
  JOIN dbo.MetaItem mi ON mi.ItemId=mfi.ItemId AND mi.VarName=co.VarName
  WHERE ce.StudyId=@StudyId AND ce.PersonId=@PersonId AND ce.EventNum=@EventNum AND cf.FormId=@FormId
END
GO

GRANT EXECUTE ON CRF.GetOldData TO [public] AS [dbo]
GO

EXECUTE DbFinalizeUpgrade 6012;
GO

COMMIT TRANSACTION UpgradeTo6012;
GO

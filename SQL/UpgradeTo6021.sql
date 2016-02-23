BEGIN TRANSACTION UpgradeTo6021
PRINT 'Starting upgrade to 6021'

DELETE FROM DbUpgradeLog WHERE DbVer > 6020;

EXEC DbCheckVersion 6020;
EXECUTE DbStartUpgrade 6021;
GO

EXEC dbo.UtilDropObject 'UpdateClinDataQuantity'
EXEC dbo.UtilDropObject 'UpdateClinDataEnum'
EXEC dbo.UtilDropObject 'UpdateClinDataText'
EXEC dbo.UtilDropObject 'UpdateClinDataDate'
GO

CREATE PROCEDURE dbo.UpdateClinDataQuantity( @TouchId INT, @VarName VARCHAR(24), @Quantity FLOAT )
AS
BEGIN
  DECLARE @EventId INT;
  SELECT @EventId = EventId FROM dbo.ClinTouch WHERE TouchId=@TouchId;
  UPDATE dbo.ClinObservation SET Quantity=@Quantity,EnumVal=NULL,ObsDate=getdate(),ChangeCount=ChangeCount+1 
  WHERE ( EventId=@EventId ) AND ( VarName=@VarName ) AND ( ISNULL(Quantity,1) <> ISNULL(@Quantity,-1) );
END 
GO

CREATE PROCEDURE dbo.UpdateClinDataEnum( @TouchId INT, @VarName VARCHAR(24), @EnumVal INT )
AS
BEGIN
  SET ANSI_NULLS OFF;
  DECLARE @EventId INT;
  SELECT @EventId = EventId FROM dbo.ClinTouch WHERE TouchId=@TouchId;
  UPDATE dbo.ClinObservation SET Quantity=@EnumVal,EnumVal=@EnumVal,ObsDate=getdate(),ChangeCount=ChangeCount+1 
  WHERE ( EventId=@EventId ) AND ( VarName=@VarName ) AND ( EnumVal <> @EnumVal );
END 
GO

CREATE PROCEDURE dbo.UpdateClinDataText( @TouchId INT, @VarName VARCHAR(24), @TextVal VARCHAR(MAX) )
AS
BEGIN
  SET ANSI_NULLS OFF;
  DECLARE @EventId INT;
  SELECT @EventId = EventId FROM dbo.ClinTouch WHERE TouchId=@TouchId;
  UPDATE dbo.ClinObservation SET Quantity=NULL,EnumVal=NULL,TextVal=@TextVal,ObsDate=getdate(),ChangeCount=ChangeCount+1 
  WHERE ( EventId=@EventId ) AND ( VarName=@VarName ) AND ( TextVal <> @TextVal );
END 
GO

CREATE PROCEDURE dbo.UpdateClinDataDate( @TouchId INT, @VarName VARCHAR(24), @DTVal DateTime )
AS
BEGIN
  SET ANSI_NULLS OFF;
  DECLARE @EventId INT;         
  SELECT @EventId = EventId FROM dbo.ClinTouch WHERE TouchId=@TouchId;
  UPDATE dbo.ClinObservation SET Quantity=NULL,EnumVal=NULL,TextVal=NULL,DTVal=@DTVal,ObsDate=getdate(),ChangeCount=ChangeCount+1 
  WHERE ( EventId=@EventId ) AND ( VarName=@VarName ) AND ( DTVal <> @DTVal);
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6021;
GO

COMMIT TRANSACTION UpgradeTo6021;
GO


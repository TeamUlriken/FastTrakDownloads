BEGIN TRANSACTION UpgradeTo6031
PRINT 'Starting upgrade to 6031'

DELETE FROM DbUpgradeLog WHERE DbVer > 6030;

EXEC DbCheckVersion 6030;
EXECUTE DbStartUpgrade 6031;
GO

IF NOT OBJECT_ID('GetReplaceConflictCount') IS NULL 
  DROP FUNCTION dbo.GetReplaceConflictCount
GO

CREATE FUNCTION dbo.GetReplaceConflictCount( @FormId INT, @OldItemId INT, @NewItemId INT ) RETURNS INT
AS
BEGIN
  DECLARE @RetVal INT;
  SELECT @RetVal =  count(a.ProbCount) 
  FROM
    ( 
    SELECT EventId,count(*) AS ProbCount from ClinDataPoint 
    WHERE ItemId in (@OldItemId,@NewItemId)
	AND EventId IN ( SELECT EventId FROM dbo.ClinForm WHERE FormId=@FormId )
    GROUP BY EventId
    HAVING count(*) > 1 
    )  a;
  RETURN @RetVal;
END
GO

IF NOT OBJECT_ID('UtilRetrofitEnumData') IS NULL 
  DROP PROCEDURE dbo.UtilRetrofitEnumData
GO

CREATE PROCEDURE dbo.UtilRetrofitEnumData( @MasterItemId INT, @MasterEnumVal INT, @DetailItemId INT, @DetailEnumVal INT ) AS
BEGIN
  INSERT INTO dbo.ClinDatapoint( EventId, ObsDate,ItemId,Quantity,EnumVal,Locked,LockedAt,LockedBy,TouchId )
    SELECT EventId, ObsDate,@MasterItemId,@MasterEnumVal,@MasterEnumVal,Locked,LockedAt,LockedBy,TouchId 
    FROM dbo.ClinDatapoint WHERE ItemId=@DetailItemId AND EnumVal=@DetailEnumVal
    AND NOT EventId IN ( SELECT EventId FROM dbo.ClinDatapoint WHERE ItemId=@MasterItemId )
END
GO

GRANT EXECUTE ON dbo.UtilRetrofitEnumData TO [superuser] AS [dbo]
GO

IF NOT OBJECT_ID('UtilRetrofitQuantityData') IS NULL 
  DROP PROCEDURE dbo.UtilRetrofitQuantityData
GO

CREATE PROCEDURE dbo.UtilRetrofitQuantityData( @MasterItemId INT, @MasterEnumVal INT, @DetailItemId INT, @DetailMinQuantity DECIMAL(18,4) ) AS
BEGIN
  INSERT INTO dbo.ClinDatapoint( EventId, ObsDate,ItemId,Quantity,EnumVal,Locked,LockedAt,LockedBy,TouchId )
    SELECT EventId, ObsDate,@MasterItemId,@MasterEnumVal,@MasterEnumVal,Locked,LockedAt,LockedBy,TouchId 
    FROM dbo.ClinDatapoint WHERE ItemId=@DetailItemId AND Quantity>=@DetailMinQuantity
    AND NOT EventId IN ( SELECT EventId FROM dbo.ClinDatapoint WHERE ItemId=@MasterItemId )
END
GO

GRANT EXECUTE ON dbo.UtilRetrofitQuantityData TO [superuser] AS [dbo]
GO

IF NOT OBJECT_ID('UtilReplaceItem') IS NULL 
  DROP PROCEDURE dbo.UtilReplaceItem
GO

CREATE PROCEDURE dbo.UtilReplaceItem( @OldItemId INT, @NewItemId INT ) AS
BEGIN
  UPDATE dbo.ClinDatapoint SET ItemId=@NewItemId WHERE ( ItemId=@OldItemId ) 
  AND ( NOT EventId IN ( SELECT EventId FROM dbo.ClinDatapoint WHERE ItemId=@NewItemId) );
END
GO

GRANT EXECUTE ON dbo.UtilReplaceItem TO [superuser] AS [dbo]
GO

IF NOT OBJECT_ID('UtilReplaceFormItem') IS NULL 
  DROP PROCEDURE dbo.UtilReplaceFormItem
GO

CREATE PROCEDURE dbo.UtilReplaceFormItem( @FormId INT, @OldItemId INT, @NewItemId INT ) AS
BEGIN
  UPDATE dbo.MetaFormItem SET ItemId = @NewItemId WHERE FormId=@FormId AND ItemId=@OldItemId ;
  UPDATE dbo.ClinDatapoint SET ItemId=@NewItemId WHERE ( ItemId=@OldItemId ) 
  AND ( ( @FormId = 0 ) OR ( EventId IN ( SELECT EventId FROM ClinForm WHERE FormId=@FormId ) ) ) 
  AND ( NOT EventId IN ( SELECT EventId FROM dbo.ClinDatapoint WHERE ItemId=@NewItemId) );
END
GO

GRANT EXECUTE ON dbo.UtilReplaceFormItem TO [superuser] AS [dbo]
GO

IF NOT OBJECT_ID('UtilRecodeFormEnumItem') IS NULL 
  DROP PROCEDURE dbo.UtilRecodeFormEnumItem
GO

CREATE PROCEDURE dbo.UtilRecodeFormEnumItem( @FormId INT, @OldItemId INT, @OldEnumVal INT, @NewItemId INT, @NewEnumVal INT) AS
BEGIN
  UPDATE dbo.MetaFormItem SET ItemId = @NewItemId WHERE FormId=@FormId AND ItemId=@OldItemId ;
  UPDATE dbo.ClinDatapoint SET ItemId=@NewItemId,EnumVal=@NewEnumVal,Quantity=@NewEnumVal 
  WHERE ( ItemId=@OldItemId ) AND ( EnumVal=@OldEnumVal ) AND ( ( @FormId = 0 ) OR ( EventId IN ( SELECT EventId FROM ClinForm WHERE FormId=@FormId ) ) ) 
  AND ( NOT EventId IN ( SELECT EventId FROM dbo.ClinDatapoint WHERE ItemId=@NewItemId) );
END
GO

GRANT EXECUTE ON dbo.UtilRecodeFormEnumItem TO [superuser] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6031;
GO
COMMIT TRANSACTION UpgradeTo6031;
GO

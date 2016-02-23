BEGIN TRANSACTION UpgradeTo6037
PRINT 'Starting upgrade to 6037'

DELETE FROM DbUpgradeLog WHERE DbVer > 6036;

EXEC DbCheckVersion 6036;
EXECUTE DbStartUpgrade 6037;
GO

IF NOT OBJECT_ID('dbo.GetMetaFormItems') IS NULL
  DROP PROCEDURE dbo.GetMetaFormItems
GO

CREATE PROCEDURE dbo.GetMetaFormItems( @StudyId INT )
AS
BEGIN
  SELECT mfi.FormId,mfi.ItemId,mfi.OrderNumber,mfi.ItemHeader,mfi.ItemText,mi.VarName,mi.UnitStr,mi.ItemType,
    mfi.MinExpression,mfi.MaxExpression, mfi.Decimals, mfi.FormItemId  
  FROM dbo.MetaFormItem mfi 
  JOIN dbo.MetaItem mi ON mi.ItemId=mfi.ItemId
  JOIN dbo.MetaStudyForm msf ON msf.FormId=mfi.FormId
  WHERE msf.StudyId=@StudyId
END
GO

GRANT EXECUTE ON dbo.GetMetaFormItems TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('dbo.AddFormItem') IS NULL
  DROP PROCEDURE dbo.AddFormItem
GO

CREATE PROCEDURE dbo.AddFormItem( @FormId INT, @ItemId INT, @VarName VARCHAR(25), @ItemType INT, @OrderNumber INT, @ItemHeader VARCHAR(MAX), @ItemText VARCHAR(MAX) )
AS
BEGIN
  IF NOT EXISTS ( SELECT 1 FROM dbo.MetaItem WHERE ItemId=@ItemId )
    INSERT INTO dbo.MetaItem( ItemId, VarName, ItemType ) VALUES (@ItemId,@VarName,@ItemType);
END
GO

GRANT EXECUTE ON dbo.AddFormItem TO [public] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6037;
GO

COMMIT TRANSACTION UpgradeTo6037;
GO




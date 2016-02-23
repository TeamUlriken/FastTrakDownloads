BEGIN TRANSACTION UpgradeTo6051
PRINT 'Starting upgrade to 6051'

DELETE FROM DbUpgradeLog WHERE DbVer > 6050;

EXEC DbCheckVersion 6050;
EXECUTE DbStartUpgrade 6051;
GO

IF dbo.DbColumnExists( 'MetaFormItem', 'FormatStr' ) = 0
  ALTER TABLE dbo.MetaFormItem ADD FormatStr VARCHAR(24)
GO

GRANT UPDATE ON dbo.MetaFormItem TO [superuser] AS [dbo]
GO

UPDATE dbo.MetaFormItem SET LastUpdate = '2000-01-01'
GO

ALTER PROCEDURE CRF.GetFormItems( @FormId INT ) AS
BEGIN
  SELECT mfi.OrderNumber,mi.ItemId,mi.VarName,mi.LabName,mi.ItemType,mi.UnitStr,
    mi.MinNormal,mi.MaxNormal,mi.ThreadTypeId, mi.Multiline,
    mfi.ExcludeFromText,mfi.ExcludeCaption, mfi.ItemHeader,mfi.ItemText,
    mfi.ItemHelp,mfi.Optional,mfi.ReadOnly,mfi.CarryForward,
    mfi.MinExpression,mfi.MaxExpression,mfi.Decimals,mfi.Expression, mfi.FormatStr,
    DefaultValue,ISNULL(Visibility,1) as Visibility,mfi.PageNumber,mfi.LastUpdate 
    FROM dbo.MetaFormItem mfi 
    JOIN dbo.MetaItem mi ON mi.ItemId=mfi.ItemId 
    LEFT OUTER JOIN dbo.MetaFormPage mfp ON mfp.PageId=mfi.PageId 
    WHERE mfi.FormId=@FormId 
    ORDER BY mfi.PageNumber,mfi.OrderNumber
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6051;
GO

COMMIT TRANSACTION UpgradeTo6051;
GO

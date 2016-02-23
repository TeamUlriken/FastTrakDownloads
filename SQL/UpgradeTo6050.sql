BEGIN TRANSACTION UpgradeTo6050
PRINT 'Starting upgrade to 6050'

DELETE FROM DbUpgradeLog WHERE DbVer > 6049;

EXEC DbCheckVersion 6049;
EXECUTE DbStartUpgrade 6050;
GO

IF NOT OBJECT_ID('GetProblemGroups') IS NULL DROP PROCEDURE GetProblemGroups
GO

CREATE PROCEDURE dbo.GetProblemGroups( @ListId INTEGER ) AS
BEGIN
  IF @ListId = 4 
  BEGIN
    SELECT mi.ItemCode,mi.ItemName FROM dbo.MetaNomItem mi
    JOIN dbo.MetaNomListItem li ON li.ItemId=mi.ItemId and ListId IN (16,17)
  END      
  ELSE
    SELECT '*' as ItemCode, ListName as ItemName FROM dbo.MetaNomList WHERE ListId=@ListId;
END
GO

GRANT EXECUTE ON dbo.GetProblemGroups TO [public] AS [dbo]
GO

ALTER PROCEDURE dbo.GetNomMatch( @MatchString VARCHAR(32), @ListId INT ) AS
BEGIN
  DECLARE @SearchFor VARCHAR(36);
  DECLARE @SubStr VARCHAR(2);
  SET @SubStr=SUBSTRING(@MatchString,2,1);
  IF ISNUMERIC(@SubStr)=1 
  BEGIN
    SET @SearchFor = @MatchString + '%';
    SELECT mi.ItemCode,mi.ItemName
      FROM dbo.MetaNomItem mi
      JOIN dbo.MetaNomListItem ml ON ml.ItemId=mi.ItemId AND ml.ListId=@ListId
    WHERE mi.ItemCode LIKE @SearchFor;
  END
  ELSE 
  BEGIN
    SET @SearchFor = '%' + @MatchString + '%';
    SELECT mi.ItemCode,mi.ItemName,CharIndex(@MatchString,mi.ItemName) as FindPos
      FROM dbo.MetaNomItem mi
      JOIN dbo.MetaNomListItem ml ON ml.ItemId=mi.ItemId AND ml.ListId=@ListId
      WHERE mi.ItemName LIKE @SearchFor
    ORDER by FindPos,mi.ItemCode
  END
END
GO


IF NOT OBJECT_ID('GetNomCodeMatch') IS NULL DROP PROCEDURE GetNomCodeMatch
GO

CREATE PROCEDURE dbo.GetNomCodeMatch( @MatchString VARCHAR(32), @ListId INT ) AS
BEGIN
  SELECT mi.ItemCode,mi.ItemName
  FROM dbo.MetaNomItem mi   
  JOIN dbo.MetaNomListItem ml ON ml.ItemId=mi.ItemId AND ml.ListId=@ListId
  WHERE mi.ItemCode LIKE @MatchString
  ORDER by mi.ItemCode
END
GO

GRANT EXECUTE ON dbo.GetNomCodeMatch TO [public] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6050
GO

COMMIT TRANSACTION UpgradeTo6050;
GO


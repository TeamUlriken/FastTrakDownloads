BEGIN TRANSACTION UpgradeTo6036
PRINT 'Starting upgrade to 6036'

DELETE FROM DbUpgradeLog WHERE DbVer > 6035;

EXEC DbCheckVersion 6035;
EXECUTE DbStartUpgrade 6036;
GO

IF NOT OBJECT_ID('DbCheckConstraintExists') IS NULL DROP FUNCTION dbo.DbCheckConstraintExists
GO

CREATE FUNCTION dbo.DbCheckConstraintExists( @ConstraintName NVARCHAR(128) ) RETURNS TINYINT
AS
BEGIN
  DECLARE @RetVal TINYINT;
  SELECT @RetVal = COUNT(*) FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS 
    WHERE CONSTRAINT_NAME = @ConstraintName;
  RETURN @RetVal;
END
GO

GRANT EXECUTE ON dbo.DbCheckConstraintExists TO [public] AS [dbo]
GO

IF dbo.DbCheckConstraintExists( 'C_LabGroupName' ) = 0
BEGIN
  UPDATE dbo.LabGroup SET LabGroupName = 'Uten navn' WHERE DATALENGTH( LabGroupName ) < 3
  ALTER TABLE dbo.LabGroup WITH CHECK ADD CONSTRAINT C_LabGroupName CHECK (datalength([LabGroupName])>(2))
END
GO

IF dbo.DbCheckConstraintExists( 'C_LabName' ) = 0
BEGIN
  UPDATE dbo.LabCode SET LabName = 'Uten navn' WHERE DATALENGTH( LabName ) < 2
  ALTER TABLE dbo.LabCode WITH CHECK ADD CONSTRAINT C_LabName CHECK (datalength([LabName])>(1))
END
GO

EXECUTE dbo.DbFinalizeUpgrade 6036;
GO

COMMIT TRANSACTION UpgradeTo6036;
GO




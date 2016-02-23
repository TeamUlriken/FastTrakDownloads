IF NOT OBJECT_ID('UpdateLabTestGroup') IS NULL
  DROP PROCEDURE dbo.UpdateLabTestGroup
GO

CREATE PROCEDURE dbo.UpdateLabTestGroup( @LabCodeId INT, @AddToGroupId INT, @RemoveFromGroupId INT ) AS
BEGIN
  -- Delete from existing group
  DELETE FROM dbo.LabCodeGroup WHERE LabGroupId=@RemoveFromGroupId AND LabCodeId=@LabCodeId;
  -- Add to new group
  IF ( ISNULL( @AddToGroupId, 0 ) > 0 ) AND NOT 
  EXISTS( SELECT LabCodeId FROM dbo.LabCodeGroup WHERE LabCodeId=@LabCodeId AND LabGroupId=@AddToGroupId )
    INSERT INTO dbo.LabCodeGroup (LabGroupId,LabCodeId) VALUES( @AddToGroupId, @LabCodeId );
END
GO

GRANT EXECUTE ON dbo.UpdateLabTestGroup TO [superuser] AS [dbo]
GO

ALTER PROCEDURE dbo.UpdateLabCodeGroup( @LabName VARCHAR(40), @AddToGroupId INT, @RemoveFromGroupId INT ) AS
BEGIN
  DECLARE @LabCodeId INT;
  SELECT @LabCodeId=LabCodeId FROM dbo.LabCode WHERE LabName = @LabName;
  IF @LabCodeId IS NULL 
  BEGIN
    INSERT INTO dbo.LabCode (LabName) VALUES( @LabName );
    SET @LabCodeId=SCOPE_IDENTITY();
  END
  ELSE
    DELETE FROM dbo.LabCodeGroup WHERE LabGroupId=@RemoveFromGroupId AND LabCodeId=@LabCodeId;
  IF ISNULL( @AddToGroupId, 0 ) > 0
    INSERT INTO dbo.LabCodeGroup (LabGroupId,LabCodeId) VALUES( @AddToGroupId, @LabCodeId );
END
GO
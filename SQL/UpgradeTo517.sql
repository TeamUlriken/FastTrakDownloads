SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo517;
PRINT 'Starting upgrade to 517'
DELETE FROM DbUpgradeLog WHERE DbVer > 516;

EXEC DbCheckVersion 516;       
EXECUTE DbStartUpgrade 517;
GO

GRANT SELECT,UPDATE ON Alert TO [public]
GO

ALTER TABLE Alert ALTER COLUMN AlertHeader VARCHAR(MAX)
ALTER TABLE Alert ALTER COLUMN AlertMessage VARCHAR(MAX)
GO

REVOKE SELECT,UPDATE ON Alert TO [public] AS [dbo]
GO


ALTER PROCEDURE dbo.RuleReminder( @StudyId INT, @PersonId INT )
AS
BEGIN
  -- Reset all alerts of this class to level 0, because some forms may have been deleted
  UPDATE Alert SET AlertLevel=0 WHERE StudyId=@StudyId AND PersonId=@PersonId AND AlertClass LIKE 'CF#%';
  
  -- Find events first to get a small temp table for next join
  SELECT ce.EventId,cf.ClinFormId,ce.EventTime 
  INTO #tempEvents 
  FROM ClinEvent ce
  JOIN ClinForm cf ON cf.EventId=ce.EventId AND cf.DeletedAt IS NULL
  JOIN MetaForm mf ON mf.FormId=cf.FormId AND mf.FormName = 'ALERT'
  WHERE ce.StudyId=@StudyId AND ce.PersonId=@PersonId; 
  
  -- Get current alerts 
  SELECT @PersonId as PersonId,@StudyId AS StudyId,
    'CF#' + CONVERT(VARCHAR,te.ClinFormId) AS AlertClass,
    'Include' as AlertFacet,                                                          
    c.EnumVal as AlertLevel,
    h.TextVal as AlertHeader, 
    q.TextVal + ' ( <a href="ShowClinFormId='+CONVERT(VARCHAR,te.ClinFormId) + '">Påminnelse</a> fra ' + CONVERT(VARCHAR,te.EventTime,104 ) + ' )' as AlertMessage,
    ISNULL(NULLIF(b.TextVal,''),'TWMF') as AlertButtons, 
    d.DTVal AS HideUntil           
  INTO #tempAlerts
  FROM #tempEvents te 
    JOIN ClinObservation h on h.EventId = te.EventId AND h.VarName='AlertHeader' 
    JOIN ClinObservation c on c.EventId = te.EventId AND c.VarName='AlertLevel' 
    JOIN ClinObservation q on q.EventId = te.EventId AND q.VarName='AlertMessage'
    JOIN ClinObservation d ON d.EventId = te.EventId AND d.VarName='HideUntil'
    LEFT OUTER JOIN ClinObservation b ON b.EventId = te.EventId AND b.VarName='AlertButtons'
  WHERE c.EnumVal > 0;
    
  UPDATE Alert SET 
    AlertLevel=t.AlertLevel,AlertHeader=t.AlertHeader,
    AlertMessage=t.AlertMessage, AlertButtons=t.AlertButtons
  FROM #tempAlerts t 
  WHERE ( t.PersonId=Alert.PersonId AND t.StudyId=Alert.StudyId AND t.AlertClass=Alert.AlertClass )
  AND  (Alert.AlertLevel <> t.AlertLevel OR Alert.AlertMessage<>t.AlertMessage OR Alert.AlertHeader<>t.AlertHeader OR Alert.AlertButtons <> t.AlertButtons);
  
  -- Bump forward HideUntil if needed (data on form has changed)  
  UPDATE Alert SET 
    HideUntil=t.HideUntil
  FROM #tempAlerts t
  WHERE (t.PersonId=Alert.PersonId AND t.StudyId=Alert.StudyId AND t.AlertClass=Alert.AlertClass )
  AND t.HideUntil > Alert.HideUntil;
  
  -- Remove all existing alerts from temp, based on ClinFormId
  DELETE FROM #tempAlerts WHERE AlertClass IN ( SELECT AlertClass FROM Alert WHERE StudyId=@StudyId AND PersonId=@PersonId );
  
  -- Add the rest, which will be from new ClinForms
  INSERT INTO Alert ( PersonId,StudyId,AlertClass,AlertFacet,AlertLevel,AlertHeader,AlertMessage,AlertButtons,HideUntil)
  SELECT t.PersonId,t.StudyId,t.AlertClass,t.AlertFacet,t.AlertLevel,t.AlertHeader,t.AlertMessage,t.AlertButtons,t.HideUntil FROM #tempAlerts t;
  
END
GO

ALTER PROCEDURE dbo.GetMyActivity( @StudyId INT = 1 ) AS
BEGIN
  DECLARE @Caption VARCHAR(64);
  SELECT TOP 30 p.PersonId,p.DOB,p.FullName,sg.GroupName,max(cl.CreatedAt) as LastActivity  
    FROM CaseLog cl
    JOIN Person p ON p.PersonId=cl.PersonId
    JOIN StudCase sc ON sc.PersonId=cl.PersonId AND sc.StudyId=@StudyId
    LEFT OUTER JOIN dbo.StudyGroup sg ON sg.GroupId=sc.GroupId AND sg.StudyId=sc.StudyId
  WHERE cl.CreatedBy=USER_ID() AND cl.CreatedAt > getdate()-30 
  GROUP BY p.PersonId,p.DOB,p.FullName,sg.GroupName 
  ORDER BY LastActivity DESC
END
GO

ALTER PROCEDURE dbo.UtilNegateUser( @UserId INT )
AS
BEGIN
  DECLARE @TableSchema NVARCHAR(128);
  DECLARE @TableName NVARCHAR(128);
  DECLARE @ColumnName NVARCHAR(128);
  DECLARE @UserName NVARCHAR(128);
  DECLARE @NegUser int;
  DECLARE @SqlCmd varchar(512);
  SELECT @UserName=UserName FROM UserList WHERE UserId=@UserId;
  IF @UserName=USER_NAME(@UserId)
  BEGIN
    RAISERROR( 'You can not negate a valid user!', 16, 1 )
    RETURN -1;
  END;
  SELECT @NegUser = MIN( UserId ) FROM UserList;
  IF @NegUser > 0 SET @NegUser = 0;
  SET @NegUser = @NegUser - 1;    
  -- Create the negated user
  INSERT INTO UserList (UserId,PersonId,CreatedAt,CreatedBy,CenterId,ProfId,UserName,OldUserId)
    SELECT @NegUser,PersonId,CreatedAt,CreatedBy,CenterId,ProfId,UserName,UserId FROM UserList
    WHERE UserId=@UserId;
  -- Find columns to update
  DECLARE cur_columns CURSOR FOR
    SELECT t.TABLE_SCHEMA,c.TABLE_NAME,c.COLUMN_NAME
    FROM INFORMATION_SCHEMA.columns c
    JOIN INFORMATION_SCHEMA.tables t ON t.TABLE_NAME = c.TABLE_NAME AND t.TABLE_SCHEMA=c.TABLE_SCHEMA
    WHERE c.COLUMN_NAME IN(
      'CreatedBy','SignedBy','PausedBy','PulledBy','StopBy','FormOwner','UpgradedBy','UpdatedBy','StartedBy','RestartBy','ChangedBy','LockedBy','UserId','ClosedBy','HandledBy' )
    AND t.TABLE_NAME <>'UserList' AND t.TABLE_TYPE='BASE TABLE';
  OPEN cur_columns;
  -- Update all columns from list
  FETCH NEXT FROM cur_columns INTO @TableSchema,@TableName,@ColumnName;
  WHILE @@FETCH_STATUS = 0
  BEGIN
      SET @SqlCmd = 'UPDATE ' + @TableSchema + '.' + @TableName + ' SET ' + @ColumnName + '=' + CONVERT(VARCHAR,@NegUser) + ' WHERE ' + @ColumnName + '=' + CONVERT(Varchar,@UserId);
      EXECUTE( @SqlCmd );
    FETCH NEXT FROM cur_columns INTO @TableSchema,@TableName,@ColumnName;
  END
  CLOSE cur_columns;
  DEALLOCATE cur_columns;
  DELETE FROM UserList WHERE UserId=@UserId;
END
GO

EXECUTE DbFinalizeUpgrade 517;
GO

COMMIT TRANSACTION UpgradeTo517;
GO

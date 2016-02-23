BEGIN TRANSACTION UpgradeTo6052
PRINT 'Starting upgrade to 6052'

DELETE FROM DbUpgradeLog WHERE DbVer > 6051;

EXEC DbCheckVersion 6051;
EXECUTE DbStartUpgrade 6052;
GO

IF NOT OBJECT_ID('StudyCaseGroupStatusHistory') IS NULL 
  DROP VIEW dbo.StudyCaseGroupStatusHistory
GO

IF NOT OBJECT_ID('FK_StudCase_StudyGroup') IS NULL
  ALTER TABLE dbo.StudCase DROP CONSTRAINT FK_StudCase_StudyGroup
GO

IF NOT OBJECT_ID('FK_StudCase_StudyStatus') IS NULL
  ALTER TABLE dbo.StudCase DROP CONSTRAINT FK_StudCase_StudyStatus
GO

GRANT UPDATE ON dbo.StudyStatus TO [superuser] AS [dbo]
GO

ALTER TABLE dbo.StudyStatus DROP CONSTRAINT PK_StudyStatus
GO

ALTER TABLE dbo.StudyStatus ALTER COLUMN StatusId INT NOT NULL
GO

ALTER TABLE dbo.StudyStatus ADD CONSTRAINT PK_StudyStatus PRIMARY KEY (StudyId,StatusId)
GO

ALTER TABLE dbo.StudCase ADD CONSTRAINT FK_StudCase_StudyGroup FOREIGN KEY (StudyId,GroupId) REFERENCES dbo.StudyGroup (StudyId,GroupId )
GO

ALTER TABLE dbo.StudCase ADD CONSTRAINT FK_StudCase_StudyStatus FOREIGN KEY (StudyId,FinState) REFERENCES dbo.StudyStatus(StudyId,StatusId)
GO

CREATE VIEW dbo.StudyCaseGroupStatusHistory
AS 
  SELECT sc.StudyId,s.StudyName,sc.PersonId,sg.CenterId,c.CenterName,scl.NewGroupId as GroupId,sg.GroupName,sg.GroupActive,scl.NewStatusId as StatusId,ss.StatusText,ss.StatusActive,scl.ChangedAt 
  FROM dbo.StudCaseLog scl 
  JOIN dbo.StudCase sc ON sc.StudCaseId = scl.StudCaseId
  JOIN dbo.Study s ON s.StudyId=sc.StudyId  
  LEFT OUTER JOIN dbo.StudyGroup sg ON sg.StudyId=sc.StudyId AND sg.GroupId=scl.NewGroupId
  LEFT OUTER JOIN dbo.StudyCenter c ON c.CenterId=sg.CenterId
  LEFT OUTER JOIN dbo.StudyStatus ss ON ss.StudyId=sc.StudyId AND ss.StatusId=scl.NewStatusId
GO

EXECUTE dbo.DbFinalizeUpgrade 6052;
GO

COMMIT TRANSACTION UpgradeTo6052;
GO

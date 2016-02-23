BEGIN TRANSACTION UpgradeTo6028
PRINT 'Starting upgrade to 6028'

DELETE FROM DbUpgradeLog WHERE DbVer > 6027;

EXEC DbCheckVersion 6027;
EXECUTE DbStartUpgrade 6028;
GO

EXEC AddSchema 'SNAPSHOT'
GO

IF NOT OBJECT_ID('GetStudyNames') IS NULL 
  DROP PROCEDURE [dbo].[GetStudyNames]
GO
 
CREATE PROCEDURE [dbo].[GetStudyNames] AS
BEGIN
  SELECT StudyId,StudyName FROM Study WHERE StudyId>0
END
GO

GRANT EXECUTE ON [dbo].[GetStudyNames] TO [public]
GO

IF NOT OBJECT_ID('SNAPSHOT.SnapshotLog') IS NULL DROP TABLE Snapshot.SnapshotLog
GO

CREATE TABLE [SNAPSHOT].[SnapshotLog](
    [SnapshotId] [int] IDENTITY(1,1) NOT NULL,
    [SnapshotName] [nvarchar](128) NOT NULL,
    [CreatedBy] [int] NOT NULL,
    [CreatedAt] [datetime] NOT NULL,
    [Active] [bit] NOT NULL )
GO

ALTER TABLE [SNAPSHOT].[SnapshotLog] ADD CONSTRAINT PK_SnapshotLog PRIMARY KEY( SnapshotId )
GO

CREATE UNIQUE INDEX IDX_SnapshotLog_SnapshotName ON [SNAPSHOT].[SnapshotLog]( SnapshotName )
GO

ALTER TABLE [SNAPSHOT].[SnapshotLog] ADD  DEFAULT (user_id()) FOR [CreatedBy]
GO

ALTER TABLE [SNAPSHOT].[SnapshotLog] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO

EXECUTE dbo.DbFinalizeUpgrade 6028;
GO

COMMIT TRANSACTION UpgradeTo6028;
GO

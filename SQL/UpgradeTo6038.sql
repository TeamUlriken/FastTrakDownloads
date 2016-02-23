BEGIN TRANSACTION UpgradeTo6038
PRINT 'Starting upgrade to 6038'

DELETE FROM DbUpgradeLog WHERE DbVer > 6037;

EXEC DbCheckVersion 6037;
EXECUTE DbStartUpgrade 6038;
GO

IF NOT OBJECT_ID('[Comm].[NewMessageWarning]') IS NULL
  DROP TABLE Comm.NewMessageWarning
GO

CREATE TABLE Comm.NewMessageWarning( WarnId INT IDENTITY(1,1) NOT NULL, PersonId INT NOT NULL, NewMsgCount INT, LastUpdated DateTime )
GO
ALTER TABLE Comm.NewMessageWarning ADD CONSTRAINT PK_NewMessageWarning PRIMARY KEY( WarnId )
GO
ALTER TABLE Comm.NewMessageWarning ADD CONSTRAINT FK_NewMessageWarning_PersonId FOREIGN KEY (PersonId) REFERENCES dbo.Person(PersonId)
GO

CREATE UNIQUE INDEX I_NewMessageWarning_PersonId ON Comm.NewMessageWarning(PersonId)
GO

IF NOT OBJECT_ID('[Comm].[UpdateNewMessageWarning]') IS NULL
  DROP PROCEDURE Comm.UpdateNewMessageWarning
GO
 
CREATE PROCEDURE Comm.UpdateNewMessageWarning( @NationalId VARCHAR(16), @NewMsgCount INT )
AS
BEGIN
  UPDATE Comm.NewMessageWarning SET NewMsgCount = @NewMsgCount, LastUpdated = getdate() 
  WHERE PersonId IN ( SELECT PersonId FROM dbo.Person WHERE NationalId = @NationalId );
  IF @@ROWCOUNT = 0
    INSERT INTO Comm.NewMessageWarning ( PersonId, NewMsgCount, LastUpdated )
    SELECT PersonId,@NewMsgCount,getdate() FROM dbo.Person WHERE NationalId = @NationalId;
END
GO

GRANT EXECUTE ON Comm.UpdateNewMessageWarning TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('[GBD].[GetCaseListUnhandledMessages]') IS NULL
  DROP PROCEDURE GBD.GetCaseListUnhandledMessages
GO

CREATE PROCEDURE GBD.GetCaseListUnhandledMessages( @StudyId INT ) AS
BEGIN
  SELECT v.PersonId,v.DOB,v.FullName,v.StudyId,v.GroupName,v.GenderId, 'Meldinger ' + CONVERT(VARCHAR,w.NewMsgCount) AS InfoText
  FROM dbo.ViewActiveCaseListStub v
  JOIN Comm.NewMessageWarning w ON w.PersonId=v.PersonId
  WHERE w.NewMsgCount > 0
  ORDER BY NewMsgCount DESC
END
GO

GRANT EXECUTE ON GBD.GetCaseListUnhandledMessages TO [public] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6038;
GO

COMMIT TRANSACTION UpgradeTo6038;
GO


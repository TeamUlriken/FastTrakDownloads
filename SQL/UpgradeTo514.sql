SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo514;
PRINT 'Starting upgrade to 514'
GO

GRANT SELECT,UPDATE,DELETE ON DbUpgradeLog TO public
GO

DELETE FROM DbUpgradeLog WHERE DbVer > 513;
EXEC DbCheckVersion 513;       
EXECUTE DbStartUpgrade 514;
GO

IF NOT OBJECT_ID('Comm.OutboxForm') IS NULL DROP VIEW Comm.OutboxForm
GO

IF dbo.DbColumnExists( 'Comm.Outbox', 'AppRecMessage' )  = 0
 ALTER TABLE Comm.Outbox ADD AppRecMessage NVARCHAR(MAX)
GO

IF NOT dbo.DbColumnExists( 'dbo.MetaStudyForm', 'MustFollow' ) = 0
 ALTER TABLE dbo.MetaStudyForm ADD MustFollow INT
GO

IF NOT OBJECT_ID('Comm.UpdateMessageAppRec' ) IS NULL DROP PROCEDURE Comm.UpdateMessageAppRec
GO

CREATE PROCEDURE Comm.UpdateMessageAppRec( @OriginalMsgId uniqueidentifier, @StatusCode INTEGER, @AppRecMessage NVARCHAR(MAX) )
AS
BEGIN
  DECLARE @OutId INT;
  SELECT @OutId = OutId FROM Comm.OutBox WHERE MsgGuid = @OriginalMsgId;
  IF @OutId IS NULL
  BEGIN
    RAISERROR( 'The OriginalMsgId is unknown', 16, 1 )
    RETURN -1
  END;
  UPDATE Comm.Outbox SET StatusCode = @StatusCode, AppRecMessage = @AppRecMessage
  WHERE OutId=@OutId;
END
GO 

IF NOT OBJECT_ID('Comm.FK_OutBox_StatusCode') IS NULL
  ALTER TABLE Comm.Outbox DROP CONSTRAINT FK_OutBox_StatusCode
GO

IF NOT OBJECT_ID('Comm.MetaStatusCode') IS NULL DROP TABLE Comm.MetaStatusCode
GO
 
CREATE TABLE Comm.MetaStatusCode( StatusCode INT NOT NULL, StatusText VARCHAR(32) NOT NULL )
GO

ALTER TABLE Comm.MetaStatusCode ADD CONSTRAINT PK_StatusCode PRIMARY KEY (StatusCode)
GO

INSERT INTO Comm.MetaStatusCode (StatusCode,StatusText ) VALUES( -2,'Ubehandlet' )
INSERT INTO Comm.MetaStatusCode (StatusCode,StatusText ) VALUES( -1,'Feil ved henting' )
INSERT INTO Comm.MetaStatusCode (StatusCode,StatusText ) VALUES( 0,'Hentet av meldingsutveksler' )
INSERT INTO Comm.MetaStatusCode (StatusCode,StatusText ) VALUES( 1,'Positiv kvittering mottatt' )
INSERT INTO Comm.MetaStatusCode (StatusCode,StatusText ) VALUES( 2,'Negativ kvittering mottatt' )
GO

ALTER TABLE Comm.OutBox ADD CONSTRAINT FK_OutBox_StatusCode FOREIGN KEY (StatusCode) REFERENCES Comm.MetaStatusCode ( StatusCode )
GO

GRANT EXECUTE ON Comm.UpdateMessageAppRec TO [public]
GO

CREATE VIEW Comm.OutboxForm AS
SELECT 
  o.OutId,p.PersonId,p.DOB,p.Initials,p.ReverseName as PatientName,ce.EventTime,mf.FormTitle,cf.CreatedAt,cf.SignedAt,sp.Signature,
  o.CreatedAt as ExportedAt,
  o.PulledAt,CONVERT(FLOAT,o.PulledAt-o.CreatedAt)*24 as PullDelayHrs, 
  ISNULL(o.StatusCode,-2) AS StatusCode, ISNULL(m.StatusText,'Ubehandlet') as StatusText,
  o.StatusMessage

FROM COMM.Outbox o
JOIN dbo.ClinForm cf ON cf.ClinFormId=o.ClinFormId
JOIN dbo.ClinEvent ce ON ce.EventId=cf.EventId
JOIN dbo.Person p on p.PersonId=o.PersonId
LEFT OUTER JOIN dbo.UserList usp ON usp.UserId=cf.SignedBy 
LEFT OUTER JOIN dbo.Person sp ON sp.PersonId=usp.PersonId
JOIN dbo.MetaForm mf ON mf.FormId = cf.FormId
LEFT OUTER JOIN Comm.MetaStatusCode m ON m.StatusCode=o.StatusCode
GO

GRANT SELECT ON Comm.OutboxForm TO public
GO

ALTER PROCEDURE COMM.GetOutbox AS
BEGIN
  SELECT OutId, MessageText, MsgGuid FROM COMM.OutBox WHERE PulledAt IS NULL OR ISNULL(StatusCode,-2) < 0;
END
GO

EXECUTE DbFinalizeUpgrade 514;

COMMIT TRANSACTION UpgradeTo514;
GO

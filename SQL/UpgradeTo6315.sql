SET XACT_ABORT OFF;

BEGIN TRANSACTION UpgradeTo6315
GO

PRINT 'Overall purpose: Add CRF.GetStudyCase and add synonym LoadStudyCase.'


EXECUTE dbo.DbStartUpgrade 6314, 6315;
GO

PRINT '--  CREATE procedure CRF.GetStudyCase to return name for Journalansvarlig.'
GO

IF NOT OBJECT_ID('LoadStudyCase', 'P') IS NULL
  DROP PROCEDURE dbo.LoadStudyCase
GO

IF NOT OBJECT_ID('LoadStudyCase', 'SN') IS NULL
  DROP SYNONYM dbo.LoadStudyCase
GO

IF NOT OBJECT_ID('CRF.GetStudyCase', 'P') IS NULL
  DROP PROCEDURE CRF.GetStudyCase
GO

CREATE PROCEDURE CRF.GetStudyCase( @StudyId INT, @PersonId INT )
AS
BEGIN
  SELECT 
     p.*,
	 mr.RelId,mr.RelName,
	 sg.GroupId,sg.GroupName,ss.StatusId,ss.StatusText,
     c.CenterId,c.CenterName, 
     ppc.Signature AS PrimaryContactSign,ppc.FullName AS PrimaryContactName,
	 uja.UserId AS Journalansvarlig,
	 pja.FullName AS JournalansvarligNavn
    FROM dbo.Person p
    LEFT JOIN dbo.StudCase sc ON sc.PersonId=p.PersonId AND sc.StudyId=@StudyId
    LEFT JOIN dbo.StudyStatus ss ON ss.StudyId=@StudyId AND ss.StatusId=sc.FinState
    LEFT JOIN dbo.StudyGroup sg ON sg.StudyId=@StudyId AND sg.GroupId=sc.GroupId
    LEFT JOIN dbo.StudyCenter c ON c.CenterId=sg.CenterId
    LEFT JOIN dbo.ClinRelation cr ON cr.PersonId=sc.PersonId AND cr.UserId=USER_ID() AND ExpiresAt>getdate()
    LEFT JOIN dbo.MetaRelation mr ON mr.RelId = cr.RelId
    LEFT JOIN dbo.UserList upc ON upc.UserId=sc.HandledBy
    LEFT JOIN dbo.UserList uja ON uja.UserId=sc.Journalansvarlig
    LEFT JOIN dbo.Person ppc ON ppc.PersonId=upc.PersonId
    LEFT JOIN dbo.Person pja ON pja.PersonId=uja.PersonId
  WHERE p.PersonId=@PersonId
END
GO

GRANT EXECUTE ON CRF.GetStudyCase TO [public] AS [dbo]
GO

CREATE SYNONYM dbo.LoadStudyCase FOR CRF.GetStudyCase
GO

GRANT EXECUTE ON dbo.LoadStudyCase TO [public] AS [dbo]
GO

EXECUTE dbo.DbFinalizeUpgrade 6315;
GO

COMMIT TRANSACTION UpgradeTo6315;
GO

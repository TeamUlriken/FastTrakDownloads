SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6005
PRINT 'Starting upgrade to 6005'

DELETE FROM DbUpgradeLog WHERE DbVer > 6004;

EXEC DbCheckVersion 6004;
EXECUTE DbStartUpgrade 6005;
GO

IF NOT OBJECT_ID('CRF.GetStudyForm') IS NULL
  DROP PROCEDURE CRF.GetStudyForm
GO

CREATE PROCEDURE CRF.GetStudyForm( @StudyId INT, @FormId INT ) AS
BEGIN 
  SELECT msf.StudyId,mf.FormId,mf.FormName,mf.FormTitle,mf.Subtitle,
    mf.CalculateInvalid, mf.RatingScale, mf.Copyright,
    mf.ThreadTypeId, mf.Instructions, 
    ISNULL(msf.Repeatable,mf.Repeatable) as Repeatable,
    ISNULL(msf.SurveyStatus,mf.SurveyStatus) AS SurveyStatus, 
    ISNULL(msf.FormActive,mf.FormActive ) AS FormActive,
    msf.HideComment,
    msf.ParentId, msf.CreatedAt,msf.CreatedBy           
    FROM dbo.MetaForm mf 
    JOIN dbo.MetaStudyForm msf ON msf.FormId=mf.FormId
    WHERE mf.FormId=@FormId AND msf.StudyId=@StudyId
END
GO

GRANT EXECUTE ON CRF.GetStudyForm TO [public] AS [dbo]
GO

EXECUTE DbFinalizeUpgrade 6005;
GO

COMMIT TRANSACTION UpgradeTo6005;
GO

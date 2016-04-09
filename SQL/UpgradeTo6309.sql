SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6309
GO

PRINT 'Overall purpose: Adapting audit trail procedure to use ClinDataPoint instead of ClinObservation.'

--  DROP procedure dbo.ReportClinFormAuditTrail
--  CREATE procedure Report.GetClinFormAuditTrail.
--  CREATE synonym dbo.ReportClinFormAuditTrail for backwards compatibility.
--  Deactivate all BERGER alerts and disable the CDSS rule.

EXECUTE dbo.DbStartUpgrade 6308, 6309;
GO

PRINT '--  DROP procedure dbo.ReportClinFormAuditTrail'

IF NOT OBJECT_ID('dbo.ReportClinFormAuditTrail', 'P') IS NULL
  DROP PROCEDURE dbo.ReportClinFormAuditTrail
GO

IF NOT OBJECT_ID('dbo.ReportClinFormAuditTrail', 'SN') IS NULL
  DROP SYNONYM dbo.ReportClinFormAuditTrail
GO

PRINT '--  CREATE procedure Report.GetClinFormAuditTrail.'

IF NOT OBJECT_ID('Report.GetClinFormAuditTrail') IS NULL
  DROP PROCEDURE Report.GetClinFormAuditTrail
GO

CREATE PROCEDURE Report.GetClinFormAuditTrail ( @ClinFormId INT ) AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @FormId INT;
  DECLARE @EventNum INT;
  DECLARE @StudyId INT;
  DECLARE @PersonId INT;

  -- Establish context variables for this form

  SELECT @FormId = FormId
  FROM dbo.ClinForm
  WHERE ClinFormId = @ClinFormId;
  SELECT @StudyId = ce.StudyId, @PersonId = ce.PersonId, @EventNum = ce.EventNum
  FROM dbo.ClinEvent ce
  JOIN dbo.ClinForm cf ON cf.EventId = ce.EventId AND ClinFormId = @ClinFormId;

  -- Get current data for items that appear on this form

  SELECT mi.ItemId,
    ISNULL(NULLIF(mfi.ItemHeader, ''), mfi.ItemText) AS Caption, mi.VarName,
    cdp.TextVal AS TextValNow, cdp.Quantity AS QuantityNow, cdp.DTVal AS DTValNow, cdp.EnumVal AS EnumValNow, cdp.ObsDate AS TimeNow,
    ulognow.SessId AS SessIdNow, ctnow.TouchId AS TouchIdNow, pnow.FullName AS FullNameNow,

    ISNULL(cl.LogId, 0) AS LogId, cl.TextVal AS TextValThen, cl.Quantity AS QuantityThen, cl.DTVal AS DTValThen, cl.EnumVal AS EnumValThen, cl.ObsDate AS TimeThen,
    ulog.SessId AS SessIdThen, ct.TouchId AS TouchIdThen, p.FullName AS FullNameThen,

    cdp.LockedAt, psign.FullName AS FullNameLockedBy

  FROM dbo.ClinDataPoint cdp
  JOIN dbo.MetaItem mi ON mi.ItemId = cdp.ItemId
  JOIN dbo.MetaFormItem mfi ON mfi.ItemId = mi.ItemId AND mfi.FormId = @FormId
  JOIN dbo.ClinTouch ctnow ON ctnow.TouchId = cdp.TouchId
  JOIN dbo.UserLog ulognow ON ulognow.SessId = ctnow.SessId
  JOIN dbo.UserList ulnow ON ulnow.UserId = ulognow.UserId
  JOIN dbo.Person pnow ON pnow.PersonId = ulnow.PersonId
  JOIN dbo.ClinEvent ce ON ce.EventId = cdp.EventId AND ce.StudyId = @StudyId AND ce.PersonId = @PersonId AND ce.EventNum = @EventNum

  -- Get historic data for the same items

  LEFT JOIN dbo.ClinLog cl ON cl.RowId = cdp.RowId
  LEFT JOIN dbo.ClinTouch ct ON ct.TouchId = cl.TouchId
  LEFT JOIN dbo.UserLog ulog ON ulog.SessId = ct.SessId
  LEFT JOIN dbo.UserList ul ON ul.UserId = ulog.UserId
  LEFT JOIN dbo.Person p ON p.PersonId = ul.PersonId
  LEFT JOIN dbo.UserList usign ON usign.UserId = cdp.LockedBy
  LEFT JOIN dbo.Person psign ON psign.PersonId = usign.PersonId

  ORDER BY mfi.OrderNumber, cl.ObsDate DESC

END
GO


GRANT EXECUTE ON Report.GetClinFormAuditTrail TO [public] AS [dbo]
GO

PRINT '--  CREATE synonym dbo.ReportClinFormAuditTrail for backwards compatibility.'
GO

CREATE SYNONYM dbo.ReportClinFormAuditTrail FOR Report.GetClinFormAuditTrail
GO

GRANT EXECUTE ON dbo.ReportClinFormAuditTrail TO [public] AS [dbo]
GO


PRINT '--  Deactivate all BERGER alerts and disable the CDSS rule.'

GRANT UPDATE ON dbo.DSSStudyRule TO [public] AS [dbo]
GRANT UPDATE ON dbo.Alert TO [public] AS [dbo]
GO

UPDATE dbo.DSSStudyRule SET RuleActive = 0 WHERE RuleId = 1 AND RuleActive = 1
UPDATE dbo.Alert SET AlertLevel = 0 WHERE AlertClass = 'BERGER' AND AlertLevel <> 0
GO

REVOKE UPDATE ON dbo.DSSStudyRule TO [public]
REVOKE UPDATE ON dbo.Alert TO [public]
GO

EXECUTE dbo.DbFinalizeUpgrade 6309;
GO

COMMIT TRANSACTION UpgradeTo6309;
GO
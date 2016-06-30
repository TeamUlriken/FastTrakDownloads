SET XACT_ABORT ON;
BEGIN TRANSACTION UpgradeTo6307
GO

PRINT 'Overall purpose: Correct permissions'

EXECUTE dbo.DbStartUpgrade 6306, 6307;
GO

-- -----------------------------------------------------------------------------
-- END Start sequence. Copy statements above this to subsequent upgrade scripts.
-- -----------------------------------------------------------------------------

REVOKE SELECT ON dbo.MetaFormProfessionPrivilege TO [superuser]
REVOKE SELECT ON dbo.UserRoleInfo TO [superuser]
REVOKE INSERT ON dbo.MetaNomItem TO [superuser]
REVOKE INSERT ON dbo.MetaNomList TO [superuser]
REVOKE INSERT ON dbo.MetaNomListItem TO [superuser]
REVOKE INSERT ON dbo.UserRoleInfo TO [superuser]
REVOKE DELETE ON dbo.MetaNomList TO [superuser]
REVOKE DELETE ON dbo.MetaNomListItem TO [superuser]
GO

REVOKE UPDATE ON dbo.ClinDataPoint TO [superuser]
REVOKE UPDATE ON dbo.MetaNomItem TO [superuser]
REVOKE UPDATE ON dbo.MetaNomList TO [superuser]
REVOKE UPDATE ON dbo.MetaNomListItem TO [superuser]
REVOKE UPDATE ON dbo.StudyStatus TO [superuser]
REVOKE UPDATE ON dbo.UserRoleInfo TO [superuser]
GO

IF NOT OBJECT_ID('GetAndRemoveStudyCasesWithoutForms') IS NULL
  REVOKE EXECUTE ON dbo.GetAndRemoveStudyCasesWithoutForms TO [public]
GO

REVOKE EXECUTE ON FEST.FinnRefusjonskoder TO [PrintPrescription]

IF NOT OBJECT_ID('GBD.GetCaseListAvvik') IS NULL
  REVOKE EXECUTE ON GBD.GetCaseListAvvik TO [superuser]
GO

IF NOT USER_ID('FTKithImp') IS NULL
BEGIN
  REVOKE SELECT ON dbo.Study TO [FTKithImp]
  REVOKE SELECT ON dbo.MetaForm TO [FTKithImp]
  REVOKE EXECUTE ON RunHourly TO [HOS1\gbdjobber]
  REVOKE EXECUTE ON dbo.AddLabData TO [FTKithImp]
  REVOKE EXECUTE ON dbo.UpdateUserCenter TO [HOS1\cd745]
  REVOKE EXECUTE ON dbo.UpdateUserCenter TO [HOS1\hs562]
END
GO

-- -----------------------------------------------------------------------------
-- Finalization sequence (copy to subsequent upgrade scripts)
-- -----------------------------------------------------------------------------

EXECUTE dbo.DbFinalizeUpgrade 6307;
GO

COMMIT TRANSACTION UpgradeTo6307;
GO
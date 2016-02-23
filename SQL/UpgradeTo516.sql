SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo516;
PRINT 'Starting upgrade to 516'
DELETE FROM DbUpgradeLog WHERE DbVer > 515;

EXEC DbCheckVersion 515;       
EXECUTE DbStartUpgrade 516;
GO

IF USER_ID('Journalansvarlig') IS NULL CREATE ROLE Journalansvarlig
GO

GRANT EXECUTE ON dbo.AddAlertForDSSRule TO [public]
GO

GRANT EXECUTE ON dbo.UpdateDrugStop TO [public]
GO

GRANT EXECUTE ON dbo.AddFormItem TO [superuser]
GO

GRANT UPDATE ON dbo.StudyGroup TO [public]
GO

UPDATE StudyGroup SET GroupActive = 0 WHERE GroupName IN ('Test','Testpasienter')
GO

REVOKE UPDATE,INSERT,DELETE ON dbo.StudyGroup TO [public]
GO

IF NOT OBJECT_ID('TEST.CheckAlertText') IS NULL DROP PROCEDURE Test.CheckAlertText
GO

IF NOT OBJECT_ID('TEST.MessageView') IS NULL DROP TABLE Test.MessageView
GO

IF EXISTS( SELECT * FROM sys.schemas WHERE name=N'TEST' )
  DROP SCHEMA TEST
GO

ALTER VIEW [NDV].[EnkeltRegneark] AS
SELECT v.PersonId, v.DOB, v.FullName, DATEDIFF(year, v.DOB, GETDATE()) AS Alder, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_TYPE')) AS NDV_TYPE, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_CONSENT')) AS NDV_CONSENT, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'SYSBP')) AS SYSBT, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'DIABP')) AS DIABT, 
    dbo.GetLastLab(v.PersonId, 'HBA1C') AS [Lab.HbA1c], 
    dbo.GetLastLab(v.PersonId, 'LDL') AS [Lab.LDL], 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_DIAGNOSE_YYYY')) AS NDV_DIAGNOSE_YYY,
    ( SELECT COUNT(*) FROM OngoingTreatment WHERE PersonId=v.PersonId AND ( ATC LIKE 'C0[2789]%' 
    OR StartReason IN ( 'Høyt blodtrykk','Hypertensjon','Blodtrykk' ))) AS [DrugList.BpDrugs],
    
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_SMOKING')) AS V3227, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'ALKOHOL_PER_UKE')) AS V3986, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_HYPOGLYCEMIA')) AS V3351, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'DM_HYPOGLYC_MONTH')) AS V3220, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'GLUC_SELFMON')) AS V5715, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_INSULIN_DEVICE')) AS V4056, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_KETOACIDOSIS')) AS V3352, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_BPDRUGS')) AS V4079,
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_FOOT_SENS')) AS V4636, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_FOOT_PULSE')) AS V4637, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_EYESIGHT')) AS V3404, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_FOOT_ULCER')) AS V3218, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_AMPUTATION')) AS V3414, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_NEPHROPATHY')) AS V3415, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_RETINOPATHY')) AS V4087, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_CHD')) AS V3397, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_STROKE')) AS V3398, 
    CONVERT(INT,dbo.GetLastQuantity(v.PersonId, 'NDV_ARTERIAL_SURGERY')) AS V3417
FROM
 dbo.ViewActiveCaseListStub AS v JOIN dbo.Study AS s ON s.StudyId = v.StudyId AND s.StudyName = 'NDV'
GO

IF NOT OBJECT_ID('dbo.MergeVariables') IS NULL DROP PROCEDURE dbo.MergeVariables
GO

CREATE PROCEDURE dbo.MergeVariables( @OldVarName VARCHAR(24), @NewVarName VARCHAR(24 ) )
AS
BEGIN
  DELETE FROM dbo.ClinObservation WHERE RowId IN
  ( SELECT RowId FROM dbo.ClinObservation o1 WHERE VarName=@OldVarName
    AND EXISTS 
      ( 
       SELECT * FROM dbo.ClinObservation o2 WHERE o2.VarName=@NewVarName AND o1.EventId=o2.EventId
       AND o1.Quantity=o2.Quantity 
      )
  )
  UPDATE dbo.ClinObservation SET VarName = @NewVarName WHERE VarName=@OldVarName;
END
GO
GRANT SELECT,DELETE ON dbo.ClinObservation TO [public]
GO
DELETE FROM dbo.ClinObservation WHERE EventId=213288 AND VarName='VAR5876' 
GO 
REVOKE SELECT,DELETE ON dbo.ClinObservation TO [public]
GO

EXECUTE dbo.MergeVariables 'VAR5876','DBP_UNSPEC'
GO

ALTER PROCEDURE dbo.UpdateClinDataEventId( @FormId INT, @OldEventId INT, @NewEventId INT )
AS
BEGIN
  -- Find variable names on this form
  SELECT mi.ItemId,mi.VarName INTO #FormItems 
  FROM dbo.MetaItem mi JOIN dbo.MetaFormItem mfi ON mfi.ItemId=mi.ItemId
  WHERE mfi.FormId=@FormId;                                                                       
  -- Make non-greedy by deleting all items found in other forms
  DELETE FROM #FormItems WHERE ItemId IN (SELECT mfi.ItemId FROM dbo.MetaFormItem mfi
  WHERE mfi.FormId IN ( SELECT FormId FROM dbo.ClinForm WHERE EventId=@OldEventId AND FormId <> @FormId));
  -- Move all standard variables
  UPDATE dbo.ClinObservation SET EventId = @NewEventId WHERE EventId = @OldEventId
  AND VarName IN ( SELECT VarName FROM #FormItems ); 
  -- Move all threaded variables
  UPDATE dbo.ClinThreadData SET EventId = @NewEventId WHERE EventId = @OldEventId
  AND ItemId IN ( SELECT ItemId FROM #FormItems ); 
END
GO

IF NOT  OBJECT_ID('dbo.RoleMembership') IS NULL DROP VIEW dbo.RoleMembership
GO

CREATE VIEW dbo.RoleMembership AS
  select ul.CenterId,ul.UserId,ul.UserName,p.FullName,USER_NAME(role_principal_id) as RoleName 
  from sys.database_Role_members rm 
  join UserList ul on ul.UserId=rm.member_principal_id
  LEFT OUTER JOIN dbo.Person p ON p.PersonId=ul.PersonId
GO

GRANT SELECT ON dbo.RoleMembership to [public]
GO


ALTER PROCEDURE dbo.DeleteClinForm( @ClinFormId INT ) AS
BEGIN
  DECLARE @RoleName VARCHAR(64);
  DECLARE @MsgText VARCHAR(512);
  DECLARE @CenterName VARCHAR(64);
  DECLARE @RoleMemberName VARCHAR(64);
  UPDATE ClinForm SET DeletedAt=getdate(),DeletedBy=user_id()
    WHERE ( ClinFormId=@ClinFormId ) AND ( ( CreatedBy=user_id() AND SignedAt IS NULL) OR (FormComplete=0 AND Comment IS NULL ) );
  IF @@ROWCOUNT=0
  BEGIN            
    /* Determine role membership that may allow deleting anyway */
    IF IS_MEMBER( 'Journalansvarlig' ) = 1 
      SET @RoleName = 'Journalansvarlig'
    ELSE 
      SET @RoleName = NULL;
    IF NOT @RoleName IS NULL
    BEGIN
      SET @MsgText = dbo.GetTextItem( 'DeleteClinForm','RoleBasedDelete' );
      UPDATE ClinForm SET DeletedAt=getdate(),DeletedBy=user_id()
        WHERE ( ClinFormId=@ClinFormId );
      RAISERROR( @MsgText , 16, 1, @RoleName )
    END   
    ELSE 
    BEGIN         
      SET @MsgText = dbo.GetTextItem( 'DeleteClinForm','UndeletableByYou' );
      /* Suggest person that can delete */
      SELECT TOP 1 @RoleMemberName = rm.FullName,@CenterName=c.CenterName FROM RoleMembership rm 
        JOIN StudyCenter c ON c.CenterId=rm.CenterId 
        JOIN UserList my ON my.CenterId = rm.CenterId AND my.UserId=USER_ID()
        WHERE RoleName = 'Journalansvarlig';
      /* Replace NULLs with general information */
      IF @RoleMemberName IS NULL SET @RoleMemberName = 'ikke spesifisert';
      IF @CenterName IS NULL SET @CenterName = 'din institusjon';
      RAISERROR( @MsgText, 16, 1, @RoleMemberName, @CenterName );
    END      
  END;
END
GO

ALTER PROCEDURE dbo.GetRoles AS
BEGIN
  SELECT principal_id as RoleId,name as RoleName,uri.RoleCaption,uri.RoleInfo
  FROM sys.database_principals 
  LEFT OUTER JOIN UserRoleInfo uri ON name=uri.RoleName  
  WHERE type='R' AND uri.IsActive=1 
  ORDER BY RoleName
END
GO

IF NOT OBJECT_ID('UpdateUserPerson') IS NULL DROP PROCEDURE dbo.UpdateUserPerson
GO

CREATE PROCEDURE dbo.UpdateUserPerson( @UserId INT, @PersonId INT ) AS
BEGIN
  UPDATE UserList SET PersonId=@PersonId WHERE UserId=@UserId;
END
GO

GRANT EXECUTE ON dbo.UpdateUserPerson TO [superuser]
GO

EXEC AddSchema 'BAR'
GO

IF NOT OBJECT_ID('BAR.CheckMetadata') IS NULL DROP PROCEDURE BAR.CheckMetadata
GO

CREATE PROCEDURE BAR.CheckMetadata AS
BEGIN
  DECLARE @StudyId AS INT;
  DECLARE @CenterId AS INT;
  DECLARE @GroupId AS INT;
  SELECT @StudyId=MAX(StudyId) FROM Study WHERE StudName='BAR';
  IF @StudyId IS NULL 
    PRINT 'Studien er ikke definert' 
  ELSE 
  BEGIN
    SELECT @CenterId=CenterId FROM UserList WHERE UserId=user_id();
    PRINT 'BAR Studien er definert'
    IF ( SELECT COUNT(*) FROM StudyStatus WHERE StudyId=@StudyId ) = 0 
    BEGIN
      INSERT INTO StudyStatus (StudyId,StatusId,StatusText,StatusActive)
        VALUES (@StudyId,1,'Aktiv',1)
      INSERT INTO StudyStatus (StudyId,StatusId,StatusText,StatusActive)
        VALUES (@StudyId,2,'Mors',0)
      INSERT INTO StudyStatus (StudyId,StatusId,StatusText,StatusActive)
        VALUES (@StudyId,3,'Flyttet',0)
      INSERT INTO StudyStatus (StudyId,StatusId,StatusText,StatusActive)
        VALUES (@StudyId,4,'Avsluttet',0)
    END;
    IF ( SELECT COUNT(*) FROM StudyGroup WHERE StudyId=@StudyId AND GroupName LIKE 'Test%') = 0 
    BEGIN
      SELECT @GroupId = ISNULL(MAX(GroupId),0) FROM StudyGroup WHERE StudyId=@StudyId;
      SET @GroupId=@GroupId + 1;
      INSERT INTO StudyGroup(StudyId,GroupId,GroupName,CenterId)
        VALUES (@StudyId,@GroupId,'Testpasienter',@CenterId)
    END
    UPDATE StudyGroup SET GroupActive=1 WHERE StudyId=@StudyId AND GroupName LIKE 'Test%';
  END
END
GO

GRANT EXECUTE ON BAR.CheckMetadata TO [public]
GO

IF dbo.DbColumnExists( 'MetaRelation', 'DisabledBy') = 0
BEGIN
  ALTER TABLE MetaRelation ADD DisabledBy INT
  ALTER TABLE MetaRelation Add DisabledAt DateTime
  ALTER TABLE MetaRelation ADD CONSTRAINT FK_MetaRelation_DisabledBy FOREIGN KEY(DisabledBy) REFERENCES UserList(UserId)
END
GO

ALTER PROCEDURE dbo.GetUserRelations ( @UserId INT = NULL ) 
AS
BEGIN
  IF @UserId IS NULL SET @UserId = USER_ID();
  SELECT mr.RelId,mr.RelName FROM MetaRelation mr  
    JOIN MetaProfession mp on mp.ProfType=mr.ProfType
    JOIN UserList ul ON ul.ProfId=mp.ProfId 
  WHERE ul.UserId=@UserId AND mr.DisabledBy IS NULL
END
GO

IF NOT OBJECT_ID('dbo.DisableRelation') IS NULL DROP PROCEDURE dbo.DisableRelation
GO

CREATE PROCEDURE dbo.DisableRelation( @RelId INT ) AS
BEGIN
  UPDATE MetaRelation SET DisabledAt = getdate(), DisabledBy = USER_ID() WHERE RelId=@RelId;
  UPDATE ClinRelation SET ExpiresAt = getdate() WHERE RelId=@RelId AND ExpiresAt > getdate();
END
GO

GRANT EXECUTE ON dbo.DisableRelation TO [superuser]
GO

IF NOT OBJECT_ID('dbo.EnableRelation') IS NULL DROP PROCEDURE dbo.EnableRelation
GO

CREATE PROCEDURE dbo.EnableRelation( @RelId INT ) AS
BEGIN
  UPDATE MetaRelation SET DisabledAt = NULL, DisabledBy = NULL WHERE RelId=@RelId
END
GO

GRANT EXECUTE ON dbo.EnableRelation TO [superuser]
GO

IF NOT OBJECT_ID('dbo.GetEnabledRelations') IS NULL DROP PROCEDURE dbo.GetEnabledRelations
GO

CREATE PROCEDURE dbo.GetEnabledRelations AS
BEGIN
  SELECT mr.RelId,mp.ProfName,mr.RelName,mr.RelDuration 
  FROM MetaRelation mr JOIN MetaProfession mp ON mp.ProfType=mr.ProfType 
  WHERE mr.DisabledBy IS NULL
  ORDER BY mp.ProfName,mr.RelName
END
GO

GRANT EXECUTE ON dbo.GetEnabledRelations TO [public]
GO

IF NOT OBJECT_ID('dbo.GetDisabledRelations') IS NULL DROP PROCEDURE dbo.GetDisabledRelations
GO

CREATE PROCEDURE dbo.GetDisabledRelations AS
BEGIN
  SELECT mr.RelId,mp.ProfName,mr.RelName,mr.RelDuration 
  FROM MetaRelation mr JOIN MetaProfession mp ON mp.ProfType=mr.ProfType 
  WHERE mr.DisabledBy<>0 
  ORDER BY mp.ProfName,mr.RelName
END
GO

GRANT EXECUTE ON dbo.GetDisabledRelations TO [public]
GO

ALTER PROCEDURE dbo.DeleteUser( @UserName NVARCHAR(128) ) AS
BEGIN
  DECLARE @UserId INT;
  SELECT @UserId=UserId from UserList WHERE (UserName=@UserName) AND ( UserId > 0 );
  IF @UserId IS NULL
  BEGIN
    SET @UserId = USER_ID(@UserName);
    IF @UserId > 0
      INSERT INTO UserList (UserId,UserName,IsActive) VALUES ( @UserId,@UserName,0 );
    ELSE
      RAISERROR( 'Databasebrukeren finnes "%s" ikke', 16, 1, @UserName )
  END
  ELSE
    UPDATE UserList SET IsActive=0 WHERE UserId=@UserId;
END
GO

EXEC sp_addrolemember db_ddladmin,'superuser'
GO
EXEC sp_addrolemember db_accessadmin,'superuser'
GO

EXEC BAR.CheckMetadata
GO
EXEC NDV.CheckMetadata
GO

ALTER PROCEDURE dbo.ResetUserRoleInfo
AS
BEGIN
  DELETE FROM UserRoleInfo WHERE 1=1
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('PrintPrescription'  ,'Forskrivningsrett',  'Gir tillatelse til utskrift av egne resepter.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('DrugPrescriber'     ,'Resepter',           'Gir tillatelse til å klargjøre resepter.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('Journalansvarlig'   ,'Journalansvarlig',   'Gir visse lovbestemte rettigheter og plikter rundt endring av journal.  Gjelder bare for de pasienter man er journalansvarlig for.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('superuser'          ,'Superbruker',        'Gir enkelte rettigheter rundt oppdatering av faginnhold i systemet.  Superbruker tildeles normalt også rollene Tilgangsstyring og Oppgradering (db_accessadmin, db_ddladmin).' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('db_ddladmin'        ,'Oppgradering',       'Gir tillatelse til å oppgradere databasen.  Kan bare tildeles av systemeier (db_owner).' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('db_accessadmin'     ,'Tilgangsstyring',    'Gir tillatelse til å legge til/fjerne brukere, samt tildele andre roller til brukerne.  Kan bare tildeles av systemeier (db_owner).' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('db_owner'           ,'Systemeier',         'Gir alle rettigheter lokalt i databasen, inkludert alle oppgraderinger. Kan bare tildeles av andre med samme rolle.  Overstyrer alle andre roller.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('ChangeWorksite'     ,'Ambulering',         'Gir tillatelse til å bytte arbeidssted selv.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('ChangeProfession'   ,'Bytte yrke',         'Gir tillatelse til å bytte mellom flere yrker selv.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('DataImport'         ,'Importere data',     'Brukes for automatiske prosesser for dataimport.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('EnterLabdata'       ,'Redigere labarket',  'Gir tillatelse til å redigere laboratoriebildet.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('EPRResponsible'     ,'Journalansvarlig',   'Foreldet rolle, bruk Journalansvarlig i stedet.' )
  INSERT INTO UserRoleInfo( RoleName, RoleCaption, RoleInfo ) VALUES('ProtocolOwner'      ,'Protokollansvarlig', 'Foreldet rolle, bruk Superuser i stedet.' )
  UPDATE UserRoleInfo SET IsActive=0 WHERE RoleName IN ('EnterLabData','ProtocolOwner','DataImport','EPRResponsible')
END
GO

EXECUTE ResetUserRoleInfo
GO

ALTER PROCEDURE NDV.GetCenterList AS
BEGIN
  SELECT DISTINCT c.CenterId,c.CenterName 
    FROM StudyCenter c 
    JOIN StudyGroup sg ON sg.CenterId = c.CenterId AND sg.GroupActive=1 AND c.CenterActive=1
    JOIN Study s ON s.StudyId=sg.StudyId 
  WHERE s.StudyName IN ('NDV','NDV.PAS','ENDO')
END
GO

ALTER PROCEDURE NDV.GetPersonData
AS BEGIN
  DECLARE @XmlData XML;
  SET @XmlData = (SELECT Person.PersonId,Person.FullName,Person.DOB,Person.GenderId,Person.NationalId 
  FROM dbo.Person JOIN StudCase sc ON sc.PersonId=Person.PersonId AND sc.MarkedForExport=1 
  JOIN dbo.Study s on s.StudyId=sc.StudyId AND s.StudName='NDV' 
  FOR XML AUTO, TYPE);
  SELECT CONVERT( varchar(max), @XmlData ) as XmlData;
END
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

CREATE PROCEDURE NDV.GetCaseHistory AS
BEGIN
  DECLARE @XmlData XML;
  SET @XmlData = ( 
    SELECT Person.NationalId,History.* FROM StudyCaseGroupStatusHistory History 
    JOIN dbo.Person Person ON Person.PersonId=History.PersonId 
    JOIN dbo.StudCase sc ON sc.PersonId=Person.PersonId AND sc.MarkedForExport=1
    ORDER BY Person.PersonId FOR XML AUTO);
  SELECT CONVERT(VARCHAR(max),@XmlData) AS XmlData;
END
GO

ALTER PROCEDURE NDV.MarkForExport
AS
BEGIN
  DECLARE @StudyId INT                             
  DECLARE @UserCenterId INT;                           
  DECLARE @FirstDOB DateTime;
  SET @FirstDOB = DATEADD( yy, -18, getdate()); 
  SELECT @UserCenterId=CenterId FROM UserList WHERE UserId=USER_ID();
  SELECT @StudyId = StudyId FROM Study WHERE StudName='NDV';
  UPDATE dbo.StudCase SET MarkedForExport=0 WHERE StudyId=@StudyId;
  UPDATE dbo.StudCase SET MarkedForExport=1 WHERE StudyId=@StudyId 
    AND dbo.GetLastQuantity( PersonId,'NDV_CONSENT') = 1
    AND GroupId IN ( SELECT GroupId FROM StudyGroup WHERE CenterId=@UserCenterId AND GroupActive=1 )
    AND PersonId IN ( SELECT PersonId FROM Person WHERE DOB <= @FirstDOB );
END
GO

ALTER VIEW NDV.LabData  
AS
  SELECT 1 AS Tag, NULL AS Parent,
    p.NationalId AS [labtest!1!pasientid],
    NULL AS [variabel!2!loinc],
    NULL AS [variabel!2!navn],
    NULL AS [variabel!2!komparator],
    NULL AS [variabel!2!original],
    NULL AS [variabel!2!verdi!element],
    NULL AS [variabel!2!enhet!element],
    NULL AS [variabel!2!tekst!element],
    NULL AS [variabel!2!analysedato!element] 
  FROM dbo.Person p JOIN dbo.StudCase sc ON sc.PersonId=p.PersonId AND sc.MarkedForExport=1 
    JOIN dbo.Study s ON s.StudyId=sc.StudyId 
  UNION ALL
  SELECT 2 AS Tag, 1 AS Parent,p.NationalId,lc.LoincCode,lc.VarName,ld.ArithmeticComp,lc.LabName,ld.NumResult,NULLIF(ld.UnitStr,''), NULLIF(ld.TxtResult,''),ld.LabDate 
    FROM dbo.LabData ld 
    JOIN dbo.Person p ON p.personId=ld.PersonId JOIN dbo.LabCode lc ON lc.LabCodeId=ld.LabCodeId 
	JOIN dbo.StudCase sc ON sc.PersonId=p.PersonId AND sc.MarkedForExport=1 JOIN Study s ON s.StudyId=sc.StudyId 
  WHERE  lc.LoincCode IN ( '4548-4','14682-9','14585-4','14647-2','22748-8','14646-4','14927-8','11218-5','1754-1','1755-8' )
GO

ALTER PROCEDURE NDV.GetLabData AS
BEGIN
  DECLARE @XmlData XML;
  UPDATE dbo.LabData SET ArithmeticComp=NULL WHERE ArithmeticComp IN ( '',' ','  ');
  SET @XmlData = ( SELECT * FROM NDV.LabData ORDER BY [labtest!1!pasientid],[variabel!2!analysedato!element] FOR XML EXPLICIT )
  SELECT CONVERT( VARCHAR(max), @XmlData) AS XmlData;
END;
GO

CREATE VIEW NDV.FormData 
AS
SELECT ce.EventTime as dato,p.NationalId as pasientid,co.VarName as navn,ISNULL(CONVERT(VARCHAR,co.DTVal,126),ISNULL(CONVERT(VARCHAR,co.EnumVal),CONVERT(VARCHAR,co.Quantity) ) ) as verdi
  FROM dbo.ClinObservation co 
  JOIN dbo.ClinEvent ce ON ce.EventId=co.EventId
  JOIN dbo.Person p ON p.PersonId=ce.PersonId
  JOIN dbo.StudCase sc ON sc.PersonId=p.PersonId AND sc.MarkedForExport=1
  WHERE (( co.VarName LIKE 'NDV_%' ) OR ( co.VarName IN ('SYSBP','DIABP','WEIGHT','HEIGHT','WAIST','BMI','HBA1C','DIABETESKOMPLIKASJONER')) OR ( co.VarName LIKE 'ATC_%' ));
GO

CREATE PROCEDURE NDV.GetFormData AS
BEGIN
  DECLARE @XmlData XML;
  SET @XmlData = ( select * FROM NDV.FormData as variabel ORDER BY pasientid,dato,navn FOR XML AUTO );
  SELECT CONVERT(VARCHAR(max),@XmlData) AS XmlData;
END
GO

EXECUTE DbFinalizeUpgrade 516;
GO

COMMIT TRANSACTION UpgradeTo516;
GO
  



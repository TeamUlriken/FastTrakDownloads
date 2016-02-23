SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

BEGIN TRANSACTION UpgradeTo6011
PRINT 'Starting upgrade to 6011'

DELETE FROM DbUpgradeLog WHERE DbVer > 6010;

EXEC DbCheckVersion 6010;
EXECUTE DbStartUpgrade 6011;
GO

EXEC AddSchema 'QA'
GO
ALTER AUTHORIZATION ON SCHEMA::QA TO [dbo]
GO

IF NOT OBJECT_ID('UtilRepairLabData') IS NULL DROP PROCEDURE dbo.UtilRepairLabData
IF NOT OBJECT_ID('QA.UtilRepairLabData') IS NULL DROP PROCEDURE QA.UtilRepairLabData
IF NOT OBJECT_ID('QA.RepairLabData') IS NULL DROP PROCEDURE QA.RepairLabData
GO

CREATE PROCEDURE QA.RepairLabData AS
BEGIN
  DELETE FROM dbo.LabData where NumResult=-999 AND TxtResult IS NULL;
  UPDATE dbo.LabData SET TxtResult = 'Påvist' WHERE TxtResult <> 'Påvist' AND TxtResult LIKE 'P%vist';
  UPDATE dbo.LabData SET TxtResult = 'Utgår' WHERE TxtResult <> 'Utgår' AND TxtResult LIKE 'Utg%r';
  UPDATE dbo.LabData SET TxtResult = 'Utført' WHERE TxtResult <> 'Utført' AND TxtResult LIKE 'Utf%rt';
  UPDATE dbo.LabData SET TxtResult = 'Ikke påvist' WHERE TxtResult <> 'Ikke påvist' AND TxtResult LIKE 'Ikke p%vist';
  UPDATE dbo.LabData SET TxtResult = 'Ikke påvist' WHERE TxtResult LIKE 'Ikke p%v';
  UPDATE dbo.LabData SET TxtResult = 'Avbestilt' WHERE TxtResult = 'Avbestil';
  UPDATE dbo.LabData SET TxtResult = 'Ikke utført' WHERE TxtResult = 'Ikke utf';
  UPDATE dbo.LabData SET TxtResult = 'Ikke beregnet' WHERE TxtResult IN ('Ikke ber','Ikke beregn.','Ikke beregn,');
  UPDATE dbo.LabData SET TxtResult = 'Se kommentar' WHERE TxtResult IN ('Se komme');

  UPDATE dbo.LabData SET TxtResult = LTRIM(RTRIM(TxtResult)) WHERE TxtResult <> LTRIM(RTRIM(TxtResult));
  UPDATE dbo.LabData SET TxtResult = REPLACE(TxtResult,',','.') WHERE ISNUMERIC(TxtResult)=1;
  UPDATE dbo.LabData SET TxtResult=NULL WHERE TxtResult='';
  UPDATE dbo.LabData SET TxtResult=NULL WHERE TxtResult IN ('0','0.0','0.00') AND NumResult=0;

  UPDATE dbo.LabData SET TxtResult = '+4' WHERE TxtResult IN ('+ 4','++++');
  UPDATE dbo.LabData SET TxtResult = '+3' WHERE TxtResult IN ('+ 3','+++');
  UPDATE dbo.LabData SET TxtResult = '+2' WHERE TxtResult IN ('+ 2','++');
  UPDATE dbo.LabData SET TxtResult = '+1' WHERE TxtResult IN ('+ 1');

  UPDATE dbo.LabData SET NumResult=CONVERT(FLOAT,TxtResult),TxtResult=NULL 
    WHERE ISNUMERIC(TxtResult)=1 AND (( NumResult=-1 ) OR ( NumResult IS NULL ))
    AND NOT TxtResult IN ( '+','-','.',',','$' );

  UPDATE dbo.LabData SET TxtResult=NULL
    WHERE ISNUMERIC(TxtResult)=1
    AND NOT TxtResult IN ( '+','-','.',',','$' ) 
    AND NumResult > 0
    AND NumResult = CONVERT(FLOAT,TxtResult);

  UPDATE dbo.LabData SET NumResult=NumResult*100       
    WHERE LabCodeId IN ( SELECT LabCodeId FROM LabCode WHERE VarName='HBA1C')
    AND NumResult < 0.3 AND NumResult > 0.03;

  UPDATE dbo.LabData SET ArithmeticComp='LT',NumResult=100,TxtResult=NULL 
    WHERE NumResult IS NULL AND TxtResult IN ('<100','< 100' );

  UPDATE dbo.LabData SET ArithmeticComp='LT',NumResult=60,TxtResult=NULL 
    WHERE NumResult IS NULL AND TxtResult IN ('<60','< 60' );

  UPDATE dbo.LabData SET ArithmeticComp='LT',NumResult=10,TxtResult=NULL 
    WHERE NumResult IS NULL AND TxtResult IN ('<10','< 10' );
    
  UPDATE dbo.LabData SET ArithmeticComp='LT',NumResult=5,TxtResult=NULL 
    WHERE NumResult IS NULL AND TxtResult IN ('<5','< 5' );    
    
  UPDATE dbo.LabData SET ArithmeticComp='LT',NumResult=1,TxtResult=NULL 
    WHERE NumResult IS NULL AND TxtResult IN ('<1','< 1' );    

  UPDATE dbo.LabData SET ArithmeticComp='LT',NumResult=1,TxtResult=NULL 
    WHERE NumResult=1 AND TxtResult IN ('<1','< 1' );    

  UPDATE dbo.LabData SET ArithmeticComp='LT',NumResult=0.1,TxtResult=NULL 
    WHERE NumResult IS NULL AND TxtResult IN ('<0.1','< 0.1','<0,1','< 0,1' );  

  UPDATE dbo.LabData SET ArithmeticComp='LT',NumResult=0.03,TxtResult=NULL 
    WHERE NumResult IS NULL AND TxtResult IN ('<0.03','< 0.03','<0,03','< 0,03' );  
      
  UPDATE dbo.LabData SET ArithmeticComp='LT',NumResult=0.01,TxtResult=NULL 
    WHERE NumResult IS NULL AND TxtResult IN ('<0.01','< 0.01','<0,01','< 0,01' ); 

  UPDATE dbo.LabData SET ArithmeticComp='LT',NumResult=0.002,TxtResult=NULL 
    WHERE NumResult IS NULL AND TxtResult IN ('<0.002','< 0.002','<0,002','< 0,002' ); 
END
GO

GRANT EXECUTE ON QA.RepairLabData TO [public] AS [dbo]
GO

IF NOT OBJECT_ID('QA.LabDataNumericInTxtResult') IS NULL 
  DROP VIEW QA.LabDataNumericInTxtResult 
GO

CREATE VIEW QA.LabDataNumericInTxtResult WITH SCHEMABINDING AS
  SELECT ld.ResultId,ld.LabDate,lc.LabName,ld.NumResult,ld.TxtResult 
  FROM dbo.LabData ld JOIN dbo.LabCode lc ON lc.LabCodeId=ld.LabCodeId
  WHERE ( (NumResult IS NULL) OR (NumResult=-1) ) AND ISNUMERIC(TxtResult)=1
  AND NOT TxtResult IN ( '-', '.', '+' )
GO

EXECUTE DbFinalizeUpgrade 6011;
GO

COMMIT TRANSACTION UpgradeTo6011;
GO

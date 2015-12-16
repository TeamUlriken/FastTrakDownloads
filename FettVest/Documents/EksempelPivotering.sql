SELECT p.* FROM 
 (
    SELECT cv.PersonId, 'V' + CONVERT(VARCHAR,cdp.ItemId) AS VarName, cdp.Quantity
    FROM dbo.ClinDataPoint cdp
    JOIN dbo.ClinForm cf ON cf.EventId=cdp.EventId AND cf.DeletedAt IS NULL
    JOIN dbo.ClinVisit cv ON cv.EventId=cf.EventId
    WHERE FormId=606 AND ItemId IN (3224,3225,3230)
  ) AS s
PIVOT ( MAX(Quantity) FOR VarName IN ([V3225],[V3224],[V3230]) ) AS p
SELECT ib.BatchId,ib.CreatedAt,ib.ErrorMessages,ul.CompName,ul.DbUser 
FROM dbo.ImportBatch ib
JOIN dbo.UserLog ul 
ON ul.UserId = ib.CreatedBy AND ( ib.CreatedAt > ul.ServTime AND ib.ClosedAt < ul.ClosedAt  )
WHERE ErrorCount > 0
ORDER BY BatchId 

SELECT ib.BatchId,ib.CreatedAt,ib.ErrorMessages,ul.CompName,ul.DbUser 
FROM dbo.ImportBatch ib
JOIN dbo.UserLog ul 
ON ul.UserId = ib.CreatedBy AND ( ib.CreatedAt > ul.ServTime AND ib.ClosedAt < ul.ClosedAt  )
ORDER BY BatchId 

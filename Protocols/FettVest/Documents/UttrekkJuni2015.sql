ALTER VIEW FettVest.CaseList1Year AS
SELECT p.PersonId,YEAR(p.DOB) AS YOB,
  CASE p.GenderId WHEN 1 THEN 'Mann, Anonym' WHEN 2 THEN 'Kvinne, Anonym' END AS FullName,
  sg.GroupName,c.CenterName as InfoText,p.GenderId
FROM
  (
   SELECT DISTINCT ce.PersonId FROM ClinForm cf 
   JOIN ClinEvent ce ON ce.EventId=cf.EventId
   WHERE cf.FormId IN (592,650,681,709)
  ) a
JOIN Person p ON p.PersonId=a.PersonId
JOIN dbo.StudCase sc on sc.PersonId=p.PersonId
JOIN dbo.Study s ON s.StudyId=sc.StudyId AND s.StudName = 'FettVest'
JOIN dbo.StudyGroup sg ON sg.StudyId=s.StudyId AND sg.GroupId=sc.GroupId
JOIN dbo.StudyCenter c ON c.CenterId=sg.CenterId
WHERE sg.GroupName = 'Studie'
GO

ALTER VIEW FettVest.Form590 AS
  SELECT 
    ce.PersonId AS F590PersonId, 
    ce.EventId AS F590EventId, ce.EventTime AS F590EventTime, 
    cf.ClinFormId AS F590ClinFormId, cf.FormStatus AS F590FormStatus, cf.FormComplete AS F590FormComplete,
    v6736.EnumVal AS E6736_Incl,
    v6737.EnumVal AS E6737_Incl,
    v6738.EnumVal AS E6738_Incl,
    v6739.EnumVal AS E6739_Incl,
    v6740.EnumVal AS E6740_Incl,
    v6741.EnumVal AS E6741_Incl,
    v6742.EnumVal AS E6742_Incl,
    v6743.EnumVal AS E6743_Incl,
    v6744.EnumVal AS E6744_Incl,
    v6745.EnumVal AS E6745_Incl,
    v6746.EnumVal AS E6746_Incl,
    v6747.EnumVal AS E6747_Incl,
    v6748.EnumVal AS E6748_Incl,
    v6749.EnumVal AS E6749_Incl,
    v6750.EnumVal AS E6750_Incl,
    v6751.EnumVal AS E6751_Incl,
    v6752.EnumVal AS E6752_Incl,
    v6753.EnumVal AS E6753_Incl,
    v6754.EnumVal AS E6754_Incl,
    v6755.EnumVal AS E6755_Incl,
    v6756.EnumVal AS E6756_Incl,
    v6757.EnumVal AS E6757_Incl,
    v6758.EnumVal AS E6758_Incl,
    v6759.EnumVal AS E6759_Incl,
    v6760.EnumVal AS E6760_Incl,
    v6761.EnumVal AS E6761_Incl,
    v6762.EnumVal AS E6762_Incl,
    v6763.EnumVal AS E6763_Incl,
    v6764.EnumVal AS E6764_Incl,
    v6765.EnumVal AS E6765_Incl,
    v6766.EnumVal AS E6766_Incl,
    ROW_NUMBER() OVER ( PARTITION BY ce.PersonId ORDER BY EventTime DESC ) AS OrderNo590 
  FROM dbo.ClinForm cf
  JOIN dbo.ClinVisit ce ON ( ce.EventId = cf.EventId ) 
    LEFT OUTER JOIN dbo.ClinDataPoint v6736 ON v6736.EventId=ce.EventId and v6736.ItemId=6736
    LEFT OUTER JOIN dbo.ClinDataPoint v6737 ON v6737.EventId=ce.EventId and v6737.ItemId=6737
    LEFT OUTER JOIN dbo.ClinDataPoint v6738 ON v6738.EventId=ce.EventId and v6738.ItemId=6738
    LEFT OUTER JOIN dbo.ClinDataPoint v6739 ON v6739.EventId=ce.EventId and v6739.ItemId=6739
    LEFT OUTER JOIN dbo.ClinDataPoint v6740 ON v6740.EventId=ce.EventId and v6740.ItemId=6740
    LEFT OUTER JOIN dbo.ClinDataPoint v6741 ON v6741.EventId=ce.EventId and v6741.ItemId=6741
    LEFT OUTER JOIN dbo.ClinDataPoint v6742 ON v6742.EventId=ce.EventId and v6742.ItemId=6742
    LEFT OUTER JOIN dbo.ClinDataPoint v6743 ON v6743.EventId=ce.EventId and v6743.ItemId=6743
    LEFT OUTER JOIN dbo.ClinDataPoint v6744 ON v6744.EventId=ce.EventId and v6744.ItemId=6744
    LEFT OUTER JOIN dbo.ClinDataPoint v6745 ON v6745.EventId=ce.EventId and v6745.ItemId=6745
    LEFT OUTER JOIN dbo.ClinDataPoint v6746 ON v6746.EventId=ce.EventId and v6746.ItemId=6746
    LEFT OUTER JOIN dbo.ClinDataPoint v6747 ON v6747.EventId=ce.EventId and v6747.ItemId=6747
    LEFT OUTER JOIN dbo.ClinDataPoint v6748 ON v6748.EventId=ce.EventId and v6748.ItemId=6748
    LEFT OUTER JOIN dbo.ClinDataPoint v6749 ON v6749.EventId=ce.EventId and v6749.ItemId=6749
    LEFT OUTER JOIN dbo.ClinDataPoint v6750 ON v6750.EventId=ce.EventId and v6750.ItemId=6750
    LEFT OUTER JOIN dbo.ClinDataPoint v6751 ON v6751.EventId=ce.EventId and v6751.ItemId=6751
    LEFT OUTER JOIN dbo.ClinDataPoint v6752 ON v6752.EventId=ce.EventId and v6752.ItemId=6752
    LEFT OUTER JOIN dbo.ClinDataPoint v6753 ON v6753.EventId=ce.EventId and v6753.ItemId=6753
    LEFT OUTER JOIN dbo.ClinDataPoint v6754 ON v6754.EventId=ce.EventId and v6754.ItemId=6754
    LEFT OUTER JOIN dbo.ClinDataPoint v6755 ON v6755.EventId=ce.EventId and v6755.ItemId=6755
    LEFT OUTER JOIN dbo.ClinDataPoint v6756 ON v6756.EventId=ce.EventId and v6756.ItemId=6756
    LEFT OUTER JOIN dbo.ClinDataPoint v6757 ON v6757.EventId=ce.EventId and v6757.ItemId=6757
    LEFT OUTER JOIN dbo.ClinDataPoint v6758 ON v6758.EventId=ce.EventId and v6758.ItemId=6758
    LEFT OUTER JOIN dbo.ClinDataPoint v6759 ON v6759.EventId=ce.EventId and v6759.ItemId=6759
    LEFT OUTER JOIN dbo.ClinDataPoint v6760 ON v6760.EventId=ce.EventId and v6760.ItemId=6760
    LEFT OUTER JOIN dbo.ClinDataPoint v6761 ON v6761.EventId=ce.EventId and v6761.ItemId=6761
    LEFT OUTER JOIN dbo.ClinDataPoint v6762 ON v6762.EventId=ce.EventId and v6762.ItemId=6762
    LEFT OUTER JOIN dbo.ClinDataPoint v6763 ON v6763.EventId=ce.EventId and v6763.ItemId=6763
    LEFT OUTER JOIN dbo.ClinDataPoint v6764 ON v6764.EventId=ce.EventId and v6764.ItemId=6764
    LEFT OUTER JOIN dbo.ClinDataPoint v6765 ON v6765.EventId=ce.EventId and v6765.ItemId=6765
    LEFT OUTER JOIN dbo.ClinDataPoint v6766 ON v6766.EventId=ce.EventId and v6766.ItemId=6766
  WHERE ( cf.DeletedAt IS NULL )
    AND ( cf.FormId=590 )
GO

ALTER VIEW FettVest.Form592 AS
  SELECT 
    ce.PersonId AS F592PersonId, 
    ce.EventId AS F592EventId, ce.EventTime AS F592EventTime, 
    cf.ClinFormId AS F592ClinFormId, cf.FormStatus AS F592FormStatus, cf.FormComplete AS F592FormComplete,
    v6736.EnumVal AS E6736_12m,
    v6737.EnumVal AS E6737_12m,
    v6738.EnumVal AS E6738_12m,
    v6739.EnumVal AS E6739_12m,
    v6740.EnumVal AS E6740_12m,
    v6741.EnumVal AS E6741_12m,
    v6742.EnumVal AS E6742_12m,
    v6743.EnumVal AS E6743_12m,
    v6744.EnumVal AS E6744_12m,
    v6745.EnumVal AS E6745_12m,
    v6746.EnumVal AS E6746_12m,
    v6747.EnumVal AS E6747_12m,
    v6748.EnumVal AS E6748_12m,
    v6749.EnumVal AS E6749_12m,
    v6750.EnumVal AS E6750_12m,
    v6751.EnumVal AS E6751_12m,
    v6752.EnumVal AS E6752_12m,
    v6753.EnumVal AS E6753_12m,
    v6754.EnumVal AS E6754_12m,
    v6755.EnumVal AS E6755_12m,
    v6756.EnumVal AS E6756_12m,
    v6757.EnumVal AS E6757_12m,
    v6758.EnumVal AS E6758_12m,
    v6759.EnumVal AS E6759_12m,
    v6760.EnumVal AS E6760_12m,
    v6761.EnumVal AS E6761_12m,
    v6762.EnumVal AS E6762_12m,
    v6763.EnumVal AS E6763_12m,
    v6764.EnumVal AS E6764_12m,
    v6765.EnumVal AS E6765_12m,
    v6766.EnumVal AS E6766_12m,
    ROW_NUMBER() OVER ( PARTITION BY ce.PersonId ORDER BY EventTime DESC ) AS OrderNo592
  FROM dbo.ClinForm cf
  JOIN dbo.ClinVisit ce ON ( ce.EventId = cf.EventId ) 
    LEFT OUTER JOIN dbo.ClinDataPoint v6736 ON v6736.EventId=ce.EventId and v6736.ItemId=6736
    LEFT OUTER JOIN dbo.ClinDataPoint v6737 ON v6737.EventId=ce.EventId and v6737.ItemId=6737
    LEFT OUTER JOIN dbo.ClinDataPoint v6738 ON v6738.EventId=ce.EventId and v6738.ItemId=6738
    LEFT OUTER JOIN dbo.ClinDataPoint v6739 ON v6739.EventId=ce.EventId and v6739.ItemId=6739
    LEFT OUTER JOIN dbo.ClinDataPoint v6740 ON v6740.EventId=ce.EventId and v6740.ItemId=6740
    LEFT OUTER JOIN dbo.ClinDataPoint v6741 ON v6741.EventId=ce.EventId and v6741.ItemId=6741
    LEFT OUTER JOIN dbo.ClinDataPoint v6742 ON v6742.EventId=ce.EventId and v6742.ItemId=6742
    LEFT OUTER JOIN dbo.ClinDataPoint v6743 ON v6743.EventId=ce.EventId and v6743.ItemId=6743
    LEFT OUTER JOIN dbo.ClinDataPoint v6744 ON v6744.EventId=ce.EventId and v6744.ItemId=6744
    LEFT OUTER JOIN dbo.ClinDataPoint v6745 ON v6745.EventId=ce.EventId and v6745.ItemId=6745
    LEFT OUTER JOIN dbo.ClinDataPoint v6746 ON v6746.EventId=ce.EventId and v6746.ItemId=6746
    LEFT OUTER JOIN dbo.ClinDataPoint v6747 ON v6747.EventId=ce.EventId and v6747.ItemId=6747
    LEFT OUTER JOIN dbo.ClinDataPoint v6748 ON v6748.EventId=ce.EventId and v6748.ItemId=6748
    LEFT OUTER JOIN dbo.ClinDataPoint v6749 ON v6749.EventId=ce.EventId and v6749.ItemId=6749
    LEFT OUTER JOIN dbo.ClinDataPoint v6750 ON v6750.EventId=ce.EventId and v6750.ItemId=6750
    LEFT OUTER JOIN dbo.ClinDataPoint v6751 ON v6751.EventId=ce.EventId and v6751.ItemId=6751
    LEFT OUTER JOIN dbo.ClinDataPoint v6752 ON v6752.EventId=ce.EventId and v6752.ItemId=6752
    LEFT OUTER JOIN dbo.ClinDataPoint v6753 ON v6753.EventId=ce.EventId and v6753.ItemId=6753
    LEFT OUTER JOIN dbo.ClinDataPoint v6754 ON v6754.EventId=ce.EventId and v6754.ItemId=6754
    LEFT OUTER JOIN dbo.ClinDataPoint v6755 ON v6755.EventId=ce.EventId and v6755.ItemId=6755
    LEFT OUTER JOIN dbo.ClinDataPoint v6756 ON v6756.EventId=ce.EventId and v6756.ItemId=6756
    LEFT OUTER JOIN dbo.ClinDataPoint v6757 ON v6757.EventId=ce.EventId and v6757.ItemId=6757
    LEFT OUTER JOIN dbo.ClinDataPoint v6758 ON v6758.EventId=ce.EventId and v6758.ItemId=6758
    LEFT OUTER JOIN dbo.ClinDataPoint v6759 ON v6759.EventId=ce.EventId and v6759.ItemId=6759
    LEFT OUTER JOIN dbo.ClinDataPoint v6760 ON v6760.EventId=ce.EventId and v6760.ItemId=6760
    LEFT OUTER JOIN dbo.ClinDataPoint v6761 ON v6761.EventId=ce.EventId and v6761.ItemId=6761
    LEFT OUTER JOIN dbo.ClinDataPoint v6762 ON v6762.EventId=ce.EventId and v6762.ItemId=6762
    LEFT OUTER JOIN dbo.ClinDataPoint v6763 ON v6763.EventId=ce.EventId and v6763.ItemId=6763
    LEFT OUTER JOIN dbo.ClinDataPoint v6764 ON v6764.EventId=ce.EventId and v6764.ItemId=6764
    LEFT OUTER JOIN dbo.ClinDataPoint v6765 ON v6765.EventId=ce.EventId and v6765.ItemId=6765
    LEFT OUTER JOIN dbo.ClinDataPoint v6766 ON v6766.EventId=ce.EventId and v6766.ItemId=6766
  WHERE ( cf.DeletedAt IS NULL )
    AND ( cf.FormId=592 )
GO

ALTER VIEW FettVest.Form604 AS
  SELECT 
    ce.PersonId AS F604PersonId, 
    ce.EventId AS F604EventId, ce.EventTime AS F604EventTime, 
    cf.ClinFormId AS F604ClinFormId, cf.FormStatus AS F604FormStatus, cf.FormComplete AS F604FormComplete,
    v6706.DTVal AS D6706_Opr,
    v6709.Quantity AS Q6709_Opr,
    v7137.DTVal AS D7137_Opr,
    v7141.EnumVal AS E7141_Opr,
    v7142.EnumVal AS E7142_Opr,
    v7143.EnumVal AS E7143_Opr,
    v7144.EnumVal AS E7144_Opr,
    v7145.Quantity AS Q7145_Opr,
    v7146.EnumVal AS E7146_Opr,
    v7147.EnumVal AS E7147_Opr,
    v7148.EnumVal AS E7148_Opr,
    v7149.EnumVal AS E7149_Opr,
    v7150.EnumVal AS E7150_Opr,
    v7151.EnumVal AS E7151_Opr,
    v7152.EnumVal AS E7152_Opr,
    v7153.EnumVal AS E7153_Opr,
    v7154.EnumVal AS E7154_Opr,
    CONVERT(VARCHAR(16),v7155.TextVal) AS T7155_Opr,
    v7156.EnumVal AS E7156_Opr,
    v7157.EnumVal AS E7157_Opr,
    v7158.EnumVal AS E7158_Opr,
    v7159.EnumVal AS E7159_Opr,
    v7160.EnumVal AS E7160_Opr,
    v7161.EnumVal AS E7161_Opr,
    v7162.EnumVal AS E7162_Opr,
    v7163.EnumVal AS E7163_Opr,
    CONVERT(VARCHAR(16),v7164.TextVal) AS T7164_Opr,
    v7165.EnumVal AS E7165_Opr,
    v7174.EnumVal AS E7174_Opr,
    v7179.EnumVal AS E7179_Opr,
    v7183.Quantity AS Q7183_Opr,
    v7184.Quantity AS Q7184_Opr,
    v7185.EnumVal AS E7185_Opr,
    v7187.EnumVal AS E7187_Opr,
    v7188.EnumVal AS E7188_Opr,
    v7189.EnumVal AS E7189_Opr,
    v7190.EnumVal AS E7190_Opr,
    v7191.EnumVal AS E7191_Opr,
    v7193.EnumVal AS E7193_Opr,
    v7194.EnumVal AS E7194_Opr,
    v7195.EnumVal AS E7195_Opr,
    v7196.Quantity AS Q7196_Opr,
    v7197.Quantity AS Q7197_Opr,
    v7198.EnumVal AS E7198_Opr,
    v7199.EnumVal AS E7199_Opr,
    v7200.Quantity AS Q7200_Opr,
    v7201.Quantity AS Q7201_Opr,
    v7202.EnumVal AS E7202_Opr,
    v7203.Quantity AS Q7203_Opr,
    v7204.EnumVal AS E7204_Opr,
    v7208.EnumVal AS E7208_Opr,
    v7212.EnumVal AS E7212_Opr,
    v7213.EnumVal AS E7213_Opr,
    v7214.Quantity AS Q7214_Opr,
    v7215.Quantity AS Q7215_Opr,
    v7216.EnumVal AS E7216_Opr,
    v7217.Quantity AS Q7217_Opr,
    v7218.EnumVal AS E7218_Opr,
    v7222.EnumVal AS E7222_Opr,
    v7226.EnumVal AS E7226_Opr,
    v7227.EnumVal AS E7227_Opr,
    v7228.EnumVal AS E7228_Opr,
    v7229.EnumVal AS E7229_Opr,
    v7230.Quantity AS Q7230_Opr,
    v7231.Quantity AS Q7231_Opr,
    v7232.EnumVal AS E7232_Opr,
    v7233.EnumVal AS E7233_Opr,
    v7234.Quantity AS Q7234_Opr,
    v7235.Quantity AS Q7235_Opr,
    v7236.EnumVal AS E7236_Opr,
    v7237.Quantity AS Q7237_Opr,
    v7238.EnumVal AS E7238_Opr,
    v7239.EnumVal AS E7239_Opr,
    v7240.EnumVal AS E7240_Opr,
    v7241.EnumVal AS E7241_Opr,
    v7242.EnumVal AS E7242_Opr,
    v7243.EnumVal AS E7243_Opr,
    v7244.EnumVal AS E7244_Opr,
    v7245.EnumVal AS E7245_Opr,
    v7246.EnumVal AS E7246_Opr,
    v7247.EnumVal AS E7247_Opr,
    CONVERT(VARCHAR(16),v7248.TextVal) AS T7248_Opr,
    v7249.EnumVal AS E7249_Opr,
    CONVERT(VARCHAR(16),v7250.TextVal) AS T7250_Opr,
    v7251.EnumVal AS E7251_Opr,
    v7252.EnumVal AS E7252_Opr,
    v7253.EnumVal AS E7253_Opr,
    v7254.EnumVal AS E7254_Opr,
    CONVERT(VARCHAR(16),v7255.TextVal) AS T7255_Opr,
    v7256.Quantity AS Q7256_Opr,
    v7257.EnumVal AS E7257_Opr,
    v7258.EnumVal AS E7258_Opr,
    v7259.EnumVal AS E7259_Opr,
    v7260.EnumVal AS E7260_Opr,
    CONVERT(VARCHAR(16),v7261.TextVal) AS T7261_Opr,
    v7262.EnumVal AS E7262_Opr,
    v7263.EnumVal AS E7263_Opr,
    v7264.EnumVal AS E7264_Opr,
    v7265.EnumVal AS E7265_Opr,
    v7266.EnumVal AS E7266_Opr,
    v7267.EnumVal AS E7267_Opr,
    v7268.EnumVal AS E7268_Opr,
    CONVERT(VARCHAR(16),v7269.TextVal) AS T7269_Opr,
    v7270.Quantity AS Q7270_Opr,
    v7271.EnumVal AS E7271_Opr,
    v7490.EnumVal AS E7490_Opr,
    ROW_NUMBER() OVER ( PARTITION BY ce.PersonId ORDER BY EventTime DESC ) AS OrderNo604
  FROM dbo.ClinForm cf
  JOIN dbo.ClinVisit ce ON ( ce.EventId = cf.EventId ) 
    LEFT OUTER JOIN dbo.ClinDataPoint v6706 ON v6706.EventId=ce.EventId and v6706.ItemId=6706
    LEFT OUTER JOIN dbo.ClinDataPoint v6709 ON v6709.EventId=ce.EventId and v6709.ItemId=6709
    LEFT OUTER JOIN dbo.ClinDataPoint v7137 ON v7137.EventId=ce.EventId and v7137.ItemId=7137
    LEFT OUTER JOIN dbo.ClinDataPoint v7141 ON v7141.EventId=ce.EventId and v7141.ItemId=7141
    LEFT OUTER JOIN dbo.ClinDataPoint v7142 ON v7142.EventId=ce.EventId and v7142.ItemId=7142
    LEFT OUTER JOIN dbo.ClinDataPoint v7143 ON v7143.EventId=ce.EventId and v7143.ItemId=7143
    LEFT OUTER JOIN dbo.ClinDataPoint v7144 ON v7144.EventId=ce.EventId and v7144.ItemId=7144
    LEFT OUTER JOIN dbo.ClinDataPoint v7145 ON v7145.EventId=ce.EventId and v7145.ItemId=7145
    LEFT OUTER JOIN dbo.ClinDataPoint v7146 ON v7146.EventId=ce.EventId and v7146.ItemId=7146
    LEFT OUTER JOIN dbo.ClinDataPoint v7147 ON v7147.EventId=ce.EventId and v7147.ItemId=7147
    LEFT OUTER JOIN dbo.ClinDataPoint v7148 ON v7148.EventId=ce.EventId and v7148.ItemId=7148
    LEFT OUTER JOIN dbo.ClinDataPoint v7149 ON v7149.EventId=ce.EventId and v7149.ItemId=7149
    LEFT OUTER JOIN dbo.ClinDataPoint v7150 ON v7150.EventId=ce.EventId and v7150.ItemId=7150
    LEFT OUTER JOIN dbo.ClinDataPoint v7151 ON v7151.EventId=ce.EventId and v7151.ItemId=7151
    LEFT OUTER JOIN dbo.ClinDataPoint v7152 ON v7152.EventId=ce.EventId and v7152.ItemId=7152
    LEFT OUTER JOIN dbo.ClinDataPoint v7153 ON v7153.EventId=ce.EventId and v7153.ItemId=7153
    LEFT OUTER JOIN dbo.ClinDataPoint v7154 ON v7154.EventId=ce.EventId and v7154.ItemId=7154
    LEFT OUTER JOIN dbo.ClinDataPoint v7155 ON v7155.EventId=ce.EventId and v7155.ItemId=7155
    LEFT OUTER JOIN dbo.ClinDataPoint v7156 ON v7156.EventId=ce.EventId and v7156.ItemId=7156
    LEFT OUTER JOIN dbo.ClinDataPoint v7157 ON v7157.EventId=ce.EventId and v7157.ItemId=7157
    LEFT OUTER JOIN dbo.ClinDataPoint v7158 ON v7158.EventId=ce.EventId and v7158.ItemId=7158
    LEFT OUTER JOIN dbo.ClinDataPoint v7159 ON v7159.EventId=ce.EventId and v7159.ItemId=7159
    LEFT OUTER JOIN dbo.ClinDataPoint v7160 ON v7160.EventId=ce.EventId and v7160.ItemId=7160
    LEFT OUTER JOIN dbo.ClinDataPoint v7161 ON v7161.EventId=ce.EventId and v7161.ItemId=7161
    LEFT OUTER JOIN dbo.ClinDataPoint v7162 ON v7162.EventId=ce.EventId and v7162.ItemId=7162
    LEFT OUTER JOIN dbo.ClinDataPoint v7163 ON v7163.EventId=ce.EventId and v7163.ItemId=7163
    LEFT OUTER JOIN dbo.ClinDataPoint v7164 ON v7164.EventId=ce.EventId and v7164.ItemId=7164
    LEFT OUTER JOIN dbo.ClinDataPoint v7165 ON v7165.EventId=ce.EventId and v7165.ItemId=7165
    LEFT OUTER JOIN dbo.ClinDataPoint v7174 ON v7174.EventId=ce.EventId and v7174.ItemId=7174
    LEFT OUTER JOIN dbo.ClinDataPoint v7179 ON v7179.EventId=ce.EventId and v7179.ItemId=7179
    LEFT OUTER JOIN dbo.ClinDataPoint v7183 ON v7183.EventId=ce.EventId and v7183.ItemId=7183
    LEFT OUTER JOIN dbo.ClinDataPoint v7184 ON v7184.EventId=ce.EventId and v7184.ItemId=7184
    LEFT OUTER JOIN dbo.ClinDataPoint v7185 ON v7185.EventId=ce.EventId and v7185.ItemId=7185
    LEFT OUTER JOIN dbo.ClinDataPoint v7187 ON v7187.EventId=ce.EventId and v7187.ItemId=7187
    LEFT OUTER JOIN dbo.ClinDataPoint v7188 ON v7188.EventId=ce.EventId and v7188.ItemId=7188
    LEFT OUTER JOIN dbo.ClinDataPoint v7189 ON v7189.EventId=ce.EventId and v7189.ItemId=7189
    LEFT OUTER JOIN dbo.ClinDataPoint v7190 ON v7190.EventId=ce.EventId and v7190.ItemId=7190
    LEFT OUTER JOIN dbo.ClinDataPoint v7191 ON v7191.EventId=ce.EventId and v7191.ItemId=7191
    LEFT OUTER JOIN dbo.ClinDataPoint v7193 ON v7193.EventId=ce.EventId and v7193.ItemId=7193
    LEFT OUTER JOIN dbo.ClinDataPoint v7194 ON v7194.EventId=ce.EventId and v7194.ItemId=7194
    LEFT OUTER JOIN dbo.ClinDataPoint v7195 ON v7195.EventId=ce.EventId and v7195.ItemId=7195
    LEFT OUTER JOIN dbo.ClinDataPoint v7196 ON v7196.EventId=ce.EventId and v7196.ItemId=7196
    LEFT OUTER JOIN dbo.ClinDataPoint v7197 ON v7197.EventId=ce.EventId and v7197.ItemId=7197
    LEFT OUTER JOIN dbo.ClinDataPoint v7198 ON v7198.EventId=ce.EventId and v7198.ItemId=7198
    LEFT OUTER JOIN dbo.ClinDataPoint v7199 ON v7199.EventId=ce.EventId and v7199.ItemId=7199
    LEFT OUTER JOIN dbo.ClinDataPoint v7200 ON v7200.EventId=ce.EventId and v7200.ItemId=7200
    LEFT OUTER JOIN dbo.ClinDataPoint v7201 ON v7201.EventId=ce.EventId and v7201.ItemId=7201
    LEFT OUTER JOIN dbo.ClinDataPoint v7202 ON v7202.EventId=ce.EventId and v7202.ItemId=7202
    LEFT OUTER JOIN dbo.ClinDataPoint v7203 ON v7203.EventId=ce.EventId and v7203.ItemId=7203
    LEFT OUTER JOIN dbo.ClinDataPoint v7204 ON v7204.EventId=ce.EventId and v7204.ItemId=7204
    LEFT OUTER JOIN dbo.ClinDataPoint v7208 ON v7208.EventId=ce.EventId and v7208.ItemId=7208
    LEFT OUTER JOIN dbo.ClinDataPoint v7212 ON v7212.EventId=ce.EventId and v7212.ItemId=7212
    LEFT OUTER JOIN dbo.ClinDataPoint v7213 ON v7213.EventId=ce.EventId and v7213.ItemId=7213
    LEFT OUTER JOIN dbo.ClinDataPoint v7214 ON v7214.EventId=ce.EventId and v7214.ItemId=7214
    LEFT OUTER JOIN dbo.ClinDataPoint v7215 ON v7215.EventId=ce.EventId and v7215.ItemId=7215
    LEFT OUTER JOIN dbo.ClinDataPoint v7216 ON v7216.EventId=ce.EventId and v7216.ItemId=7216
    LEFT OUTER JOIN dbo.ClinDataPoint v7217 ON v7217.EventId=ce.EventId and v7217.ItemId=7217
    LEFT OUTER JOIN dbo.ClinDataPoint v7218 ON v7218.EventId=ce.EventId and v7218.ItemId=7218
    LEFT OUTER JOIN dbo.ClinDataPoint v7222 ON v7222.EventId=ce.EventId and v7222.ItemId=7222
    LEFT OUTER JOIN dbo.ClinDataPoint v7226 ON v7226.EventId=ce.EventId and v7226.ItemId=7226
    LEFT OUTER JOIN dbo.ClinDataPoint v7227 ON v7227.EventId=ce.EventId and v7227.ItemId=7227
    LEFT OUTER JOIN dbo.ClinDataPoint v7228 ON v7228.EventId=ce.EventId and v7228.ItemId=7228
    LEFT OUTER JOIN dbo.ClinDataPoint v7229 ON v7229.EventId=ce.EventId and v7229.ItemId=7229
    LEFT OUTER JOIN dbo.ClinDataPoint v7230 ON v7230.EventId=ce.EventId and v7230.ItemId=7230
    LEFT OUTER JOIN dbo.ClinDataPoint v7231 ON v7231.EventId=ce.EventId and v7231.ItemId=7231
    LEFT OUTER JOIN dbo.ClinDataPoint v7232 ON v7232.EventId=ce.EventId and v7232.ItemId=7232
    LEFT OUTER JOIN dbo.ClinDataPoint v7233 ON v7233.EventId=ce.EventId and v7233.ItemId=7233
    LEFT OUTER JOIN dbo.ClinDataPoint v7234 ON v7234.EventId=ce.EventId and v7234.ItemId=7234
    LEFT OUTER JOIN dbo.ClinDataPoint v7235 ON v7235.EventId=ce.EventId and v7235.ItemId=7235
    LEFT OUTER JOIN dbo.ClinDataPoint v7236 ON v7236.EventId=ce.EventId and v7236.ItemId=7236
    LEFT OUTER JOIN dbo.ClinDataPoint v7237 ON v7237.EventId=ce.EventId and v7237.ItemId=7237
    LEFT OUTER JOIN dbo.ClinDataPoint v7238 ON v7238.EventId=ce.EventId and v7238.ItemId=7238
    LEFT OUTER JOIN dbo.ClinDataPoint v7239 ON v7239.EventId=ce.EventId and v7239.ItemId=7239
    LEFT OUTER JOIN dbo.ClinDataPoint v7240 ON v7240.EventId=ce.EventId and v7240.ItemId=7240
    LEFT OUTER JOIN dbo.ClinDataPoint v7241 ON v7241.EventId=ce.EventId and v7241.ItemId=7241
    LEFT OUTER JOIN dbo.ClinDataPoint v7242 ON v7242.EventId=ce.EventId and v7242.ItemId=7242
    LEFT OUTER JOIN dbo.ClinDataPoint v7243 ON v7243.EventId=ce.EventId and v7243.ItemId=7243
    LEFT OUTER JOIN dbo.ClinDataPoint v7244 ON v7244.EventId=ce.EventId and v7244.ItemId=7244
    LEFT OUTER JOIN dbo.ClinDataPoint v7245 ON v7245.EventId=ce.EventId and v7245.ItemId=7245
    LEFT OUTER JOIN dbo.ClinDataPoint v7246 ON v7246.EventId=ce.EventId and v7246.ItemId=7246
    LEFT OUTER JOIN dbo.ClinDataPoint v7247 ON v7247.EventId=ce.EventId and v7247.ItemId=7247
    LEFT OUTER JOIN dbo.ClinDataPoint v7248 ON v7248.EventId=ce.EventId and v7248.ItemId=7248
    LEFT OUTER JOIN dbo.ClinDataPoint v7249 ON v7249.EventId=ce.EventId and v7249.ItemId=7249
    LEFT OUTER JOIN dbo.ClinDataPoint v7250 ON v7250.EventId=ce.EventId and v7250.ItemId=7250
    LEFT OUTER JOIN dbo.ClinDataPoint v7251 ON v7251.EventId=ce.EventId and v7251.ItemId=7251
    LEFT OUTER JOIN dbo.ClinDataPoint v7252 ON v7252.EventId=ce.EventId and v7252.ItemId=7252
    LEFT OUTER JOIN dbo.ClinDataPoint v7253 ON v7253.EventId=ce.EventId and v7253.ItemId=7253
    LEFT OUTER JOIN dbo.ClinDataPoint v7254 ON v7254.EventId=ce.EventId and v7254.ItemId=7254
    LEFT OUTER JOIN dbo.ClinDataPoint v7255 ON v7255.EventId=ce.EventId and v7255.ItemId=7255
    LEFT OUTER JOIN dbo.ClinDataPoint v7256 ON v7256.EventId=ce.EventId and v7256.ItemId=7256
    LEFT OUTER JOIN dbo.ClinDataPoint v7257 ON v7257.EventId=ce.EventId and v7257.ItemId=7257
    LEFT OUTER JOIN dbo.ClinDataPoint v7258 ON v7258.EventId=ce.EventId and v7258.ItemId=7258
    LEFT OUTER JOIN dbo.ClinDataPoint v7259 ON v7259.EventId=ce.EventId and v7259.ItemId=7259
    LEFT OUTER JOIN dbo.ClinDataPoint v7260 ON v7260.EventId=ce.EventId and v7260.ItemId=7260
    LEFT OUTER JOIN dbo.ClinDataPoint v7261 ON v7261.EventId=ce.EventId and v7261.ItemId=7261
    LEFT OUTER JOIN dbo.ClinDataPoint v7262 ON v7262.EventId=ce.EventId and v7262.ItemId=7262
    LEFT OUTER JOIN dbo.ClinDataPoint v7263 ON v7263.EventId=ce.EventId and v7263.ItemId=7263
    LEFT OUTER JOIN dbo.ClinDataPoint v7264 ON v7264.EventId=ce.EventId and v7264.ItemId=7264
    LEFT OUTER JOIN dbo.ClinDataPoint v7265 ON v7265.EventId=ce.EventId and v7265.ItemId=7265
    LEFT OUTER JOIN dbo.ClinDataPoint v7266 ON v7266.EventId=ce.EventId and v7266.ItemId=7266
    LEFT OUTER JOIN dbo.ClinDataPoint v7267 ON v7267.EventId=ce.EventId and v7267.ItemId=7267
    LEFT OUTER JOIN dbo.ClinDataPoint v7268 ON v7268.EventId=ce.EventId and v7268.ItemId=7268
    LEFT OUTER JOIN dbo.ClinDataPoint v7269 ON v7269.EventId=ce.EventId and v7269.ItemId=7269
    LEFT OUTER JOIN dbo.ClinDataPoint v7270 ON v7270.EventId=ce.EventId and v7270.ItemId=7270
    LEFT OUTER JOIN dbo.ClinDataPoint v7271 ON v7271.EventId=ce.EventId and v7271.ItemId=7271
    LEFT OUTER JOIN dbo.ClinDataPoint v7490 ON v7490.EventId=ce.EventId and v7490.ItemId=7490
  WHERE ( cf.DeletedAt IS NULL )
    AND ( cf.FormId=604 )
GO

ALTER VIEW FettVest.Form606 AS
  SELECT 
    ce.PersonId AS F606PersonId, 
    ce.EventId AS F606EventId, ce.EventTime AS F606EventTime, 
    cf.ClinFormId AS F606ClinFormId, cf.FormStatus AS F606FormStatus, cf.FormComplete AS F606FormComplete,
    v3196.EnumVal AS E3196_Incl,
    v3224.Quantity AS Q3224_Incl,
    v3225.Quantity AS Q3225_Incl,
    v3227.EnumVal AS E3227_Incl,
    v3230.Quantity AS Q3230_Incl,
    v3231.Quantity AS Q3231_Incl,
    v3310.Quantity AS Q3310_Incl,
    v3322.EnumVal AS E3322_Incl,
    v3337.EnumVal AS E3337_Incl,
    v3486.Quantity AS Q3486_Incl,
    v4060.EnumVal AS E4060_Incl,
    v4079.Quantity AS Q4079_Incl,
    v4255.EnumVal AS E4255_Incl,
    v4754.EnumVal AS E4754_Incl,
    v4755.EnumVal AS E4755_Incl,
    v4756.EnumVal AS E4756_Incl,
    v6153.Quantity AS Q6153_Incl,
    v6154.Quantity AS Q6154_Incl,
    v6155.Quantity AS Q6155_Incl,
    v6323.Quantity AS Q6323_Incl,
    v6684.Quantity AS Q6684_Incl,
    v6685.Quantity AS Q6685_Incl,
    v6686.Quantity AS Q6686_Incl,
    v6687.Quantity AS Q6687_Incl,
    v6688.Quantity AS Q6688_Incl,
    v6689.Quantity AS Q6689_Incl,
    v6690.Quantity AS Q6690_Incl,
    v6691.EnumVal AS E6691_Incl,
    v6692.EnumVal AS E6692_Incl,
    v6693.EnumVal AS E6693_Incl,
    v6694.EnumVal AS E6694_Incl,
    v6695.EnumVal AS E6695_Incl,
    v6696.EnumVal AS E6696_Incl,
    v6697.EnumVal AS E6697_Incl,
    v6701.EnumVal AS E6701_Incl,
    v6702.Quantity AS Q6702_Incl,
    v6704.EnumVal AS E6704_Incl,
    v6705.EnumVal AS E6705_Incl,
    v6780.EnumVal AS E6780_Incl,
    v6811.Quantity AS Q6811_Incl,
    v6812.EnumVal AS E6812_Incl,
    v6813.Quantity AS Q6813_Incl,
    v6814.EnumVal AS E6814_Incl,
    v6815.EnumVal AS E6815_Incl,
    v6816.EnumVal AS E6816_Incl,
    v6817.EnumVal AS E6817_Incl,
    v6818.EnumVal AS E6818_Incl,
    v6819.Quantity AS Q6819_Incl,
    v6820.Quantity AS Q6820_Incl,
    v6821.Quantity AS Q6821_Incl,
    v6822.Quantity AS Q6822_Incl,
    v6823.EnumVal AS E6823_Incl,
    v6824.EnumVal AS E6824_Incl,
    v6826.DTVal AS D6826_Incl,
    v6828.EnumVal AS E6828_Incl,
    v6830.Quantity AS Q6830_Incl,
    v6831.Quantity AS Q6831_Incl,
    v7063.DTVal AS D7063_Incl,
    v7064.DTVal AS D7064_Incl,
    v7065.DTVal AS D7065_Incl,
    v7066.Quantity AS Q7066_Incl,
    v7067.Quantity AS Q7067_Incl,
    v7068.Quantity AS Q7068_Incl,
    v7109.Quantity AS Q7109_Incl,
    v7110.Quantity AS Q7110_Incl,
    v7112.EnumVal AS E7112_Incl,
    v7113.EnumVal AS E7113_Incl,
    v7114.EnumVal AS E7114_Incl,
    v7115.EnumVal AS E7115_Incl,
    v7116.EnumVal AS E7116_Incl,
    v7117.EnumVal AS E7117_Incl,
    v7118.EnumVal AS E7118_Incl,
    v7119.EnumVal AS E7119_Incl,
    CONVERT(VARCHAR(16),v7120.TextVal) AS T7120_Incl,
    v7121.EnumVal AS E7121_Incl,
    v7122.Quantity AS Q7122_Incl,
    v7123.EnumVal AS E7123_Incl,
    v7135.EnumVal AS E7135_Incl,
    v7136.Quantity AS Q7136_Incl,
    v7140.Quantity AS Q7140_Incl,
    v7491.EnumVal AS E7491_Incl,
    v7492.EnumVal AS E7492_Incl,
    v7493.EnumVal AS E7493_Incl,
    v7494.EnumVal AS E7494_Incl,
    v7530.EnumVal AS E7530_Incl,
    v7576.EnumVal AS E7576_Incl,
    v7577.EnumVal AS E7577_Incl,
    v7578.EnumVal AS E7578_Incl,
    v7579.EnumVal AS E7579_Incl,
    v7650.Quantity AS Q7650_Incl,
    v7651.Quantity AS Q7651_Incl,
    v7652.EnumVal AS E7652_Incl,
    v7653.EnumVal AS E7653_Incl,
    v7655.EnumVal AS E7655_Incl,
    ROW_NUMBER() OVER ( PARTITION BY ce.PersonId ORDER BY EventTime DESC ) AS OrderNo606 
  FROM dbo.ClinForm cf
  JOIN dbo.ClinVisit ce ON ( ce.EventId = cf.EventId ) 
    LEFT OUTER JOIN dbo.ClinDataPoint v3196 ON v3196.EventId=ce.EventId and v3196.ItemId=3196
    LEFT OUTER JOIN dbo.ClinDataPoint v3224 ON v3224.EventId=ce.EventId and v3224.ItemId=3224
    LEFT OUTER JOIN dbo.ClinDataPoint v3225 ON v3225.EventId=ce.EventId and v3225.ItemId=3225
    LEFT OUTER JOIN dbo.ClinDataPoint v3227 ON v3227.EventId=ce.EventId and v3227.ItemId=3227
    LEFT OUTER JOIN dbo.ClinDataPoint v3230 ON v3230.EventId=ce.EventId and v3230.ItemId=3230
    LEFT OUTER JOIN dbo.ClinDataPoint v3231 ON v3231.EventId=ce.EventId and v3231.ItemId=3231
    LEFT OUTER JOIN dbo.ClinDataPoint v3310 ON v3310.EventId=ce.EventId and v3310.ItemId=3310
    LEFT OUTER JOIN dbo.ClinDataPoint v3322 ON v3322.EventId=ce.EventId and v3322.ItemId=3322
    LEFT OUTER JOIN dbo.ClinDataPoint v3337 ON v3337.EventId=ce.EventId and v3337.ItemId=3337
    LEFT OUTER JOIN dbo.ClinDataPoint v3486 ON v3486.EventId=ce.EventId and v3486.ItemId=3486
    LEFT OUTER JOIN dbo.ClinDataPoint v4060 ON v4060.EventId=ce.EventId and v4060.ItemId=4060
    LEFT OUTER JOIN dbo.ClinDataPoint v4079 ON v4079.EventId=ce.EventId and v4079.ItemId=4079
    LEFT OUTER JOIN dbo.ClinDataPoint v4255 ON v4255.EventId=ce.EventId and v4255.ItemId=4255
    LEFT OUTER JOIN dbo.ClinDataPoint v4754 ON v4754.EventId=ce.EventId and v4754.ItemId=4754
    LEFT OUTER JOIN dbo.ClinDataPoint v4755 ON v4755.EventId=ce.EventId and v4755.ItemId=4755
    LEFT OUTER JOIN dbo.ClinDataPoint v4756 ON v4756.EventId=ce.EventId and v4756.ItemId=4756
    LEFT OUTER JOIN dbo.ClinDataPoint v6153 ON v6153.EventId=ce.EventId and v6153.ItemId=6153
    LEFT OUTER JOIN dbo.ClinDataPoint v6154 ON v6154.EventId=ce.EventId and v6154.ItemId=6154
    LEFT OUTER JOIN dbo.ClinDataPoint v6155 ON v6155.EventId=ce.EventId and v6155.ItemId=6155
    LEFT OUTER JOIN dbo.ClinDataPoint v6323 ON v6323.EventId=ce.EventId and v6323.ItemId=6323
    LEFT OUTER JOIN dbo.ClinDataPoint v6684 ON v6684.EventId=ce.EventId and v6684.ItemId=6684
    LEFT OUTER JOIN dbo.ClinDataPoint v6685 ON v6685.EventId=ce.EventId and v6685.ItemId=6685
    LEFT OUTER JOIN dbo.ClinDataPoint v6686 ON v6686.EventId=ce.EventId and v6686.ItemId=6686
    LEFT OUTER JOIN dbo.ClinDataPoint v6687 ON v6687.EventId=ce.EventId and v6687.ItemId=6687
    LEFT OUTER JOIN dbo.ClinDataPoint v6688 ON v6688.EventId=ce.EventId and v6688.ItemId=6688
    LEFT OUTER JOIN dbo.ClinDataPoint v6689 ON v6689.EventId=ce.EventId and v6689.ItemId=6689
    LEFT OUTER JOIN dbo.ClinDataPoint v6690 ON v6690.EventId=ce.EventId and v6690.ItemId=6690
    LEFT OUTER JOIN dbo.ClinDataPoint v6691 ON v6691.EventId=ce.EventId and v6691.ItemId=6691
    LEFT OUTER JOIN dbo.ClinDataPoint v6692 ON v6692.EventId=ce.EventId and v6692.ItemId=6692
    LEFT OUTER JOIN dbo.ClinDataPoint v6693 ON v6693.EventId=ce.EventId and v6693.ItemId=6693
    LEFT OUTER JOIN dbo.ClinDataPoint v6694 ON v6694.EventId=ce.EventId and v6694.ItemId=6694
    LEFT OUTER JOIN dbo.ClinDataPoint v6695 ON v6695.EventId=ce.EventId and v6695.ItemId=6695
    LEFT OUTER JOIN dbo.ClinDataPoint v6696 ON v6696.EventId=ce.EventId and v6696.ItemId=6696
    LEFT OUTER JOIN dbo.ClinDataPoint v6697 ON v6697.EventId=ce.EventId and v6697.ItemId=6697
    LEFT OUTER JOIN dbo.ClinDataPoint v6701 ON v6701.EventId=ce.EventId and v6701.ItemId=6701
    LEFT OUTER JOIN dbo.ClinDataPoint v6702 ON v6702.EventId=ce.EventId and v6702.ItemId=6702
    LEFT OUTER JOIN dbo.ClinDataPoint v6704 ON v6704.EventId=ce.EventId and v6704.ItemId=6704
    LEFT OUTER JOIN dbo.ClinDataPoint v6705 ON v6705.EventId=ce.EventId and v6705.ItemId=6705
    LEFT OUTER JOIN dbo.ClinDataPoint v6780 ON v6780.EventId=ce.EventId and v6780.ItemId=6780
    LEFT OUTER JOIN dbo.ClinDataPoint v6811 ON v6811.EventId=ce.EventId and v6811.ItemId=6811
    LEFT OUTER JOIN dbo.ClinDataPoint v6812 ON v6812.EventId=ce.EventId and v6812.ItemId=6812
    LEFT OUTER JOIN dbo.ClinDataPoint v6813 ON v6813.EventId=ce.EventId and v6813.ItemId=6813
    LEFT OUTER JOIN dbo.ClinDataPoint v6814 ON v6814.EventId=ce.EventId and v6814.ItemId=6814
    LEFT OUTER JOIN dbo.ClinDataPoint v6815 ON v6815.EventId=ce.EventId and v6815.ItemId=6815
    LEFT OUTER JOIN dbo.ClinDataPoint v6816 ON v6816.EventId=ce.EventId and v6816.ItemId=6816
    LEFT OUTER JOIN dbo.ClinDataPoint v6817 ON v6817.EventId=ce.EventId and v6817.ItemId=6817
    LEFT OUTER JOIN dbo.ClinDataPoint v6818 ON v6818.EventId=ce.EventId and v6818.ItemId=6818
    LEFT OUTER JOIN dbo.ClinDataPoint v6819 ON v6819.EventId=ce.EventId and v6819.ItemId=6819
    LEFT OUTER JOIN dbo.ClinDataPoint v6820 ON v6820.EventId=ce.EventId and v6820.ItemId=6820
    LEFT OUTER JOIN dbo.ClinDataPoint v6821 ON v6821.EventId=ce.EventId and v6821.ItemId=6821
    LEFT OUTER JOIN dbo.ClinDataPoint v6822 ON v6822.EventId=ce.EventId and v6822.ItemId=6822
    LEFT OUTER JOIN dbo.ClinDataPoint v6823 ON v6823.EventId=ce.EventId and v6823.ItemId=6823
    LEFT OUTER JOIN dbo.ClinDataPoint v6824 ON v6824.EventId=ce.EventId and v6824.ItemId=6824
    LEFT OUTER JOIN dbo.ClinDataPoint v6826 ON v6826.EventId=ce.EventId and v6826.ItemId=6826
    LEFT OUTER JOIN dbo.ClinDataPoint v6828 ON v6828.EventId=ce.EventId and v6828.ItemId=6828
    LEFT OUTER JOIN dbo.ClinDataPoint v6830 ON v6830.EventId=ce.EventId and v6830.ItemId=6830
    LEFT OUTER JOIN dbo.ClinDataPoint v6831 ON v6831.EventId=ce.EventId and v6831.ItemId=6831
    LEFT OUTER JOIN dbo.ClinDataPoint v7063 ON v7063.EventId=ce.EventId and v7063.ItemId=7063
    LEFT OUTER JOIN dbo.ClinDataPoint v7064 ON v7064.EventId=ce.EventId and v7064.ItemId=7064
    LEFT OUTER JOIN dbo.ClinDataPoint v7065 ON v7065.EventId=ce.EventId and v7065.ItemId=7065
    LEFT OUTER JOIN dbo.ClinDataPoint v7066 ON v7066.EventId=ce.EventId and v7066.ItemId=7066
    LEFT OUTER JOIN dbo.ClinDataPoint v7067 ON v7067.EventId=ce.EventId and v7067.ItemId=7067
    LEFT OUTER JOIN dbo.ClinDataPoint v7068 ON v7068.EventId=ce.EventId and v7068.ItemId=7068
    LEFT OUTER JOIN dbo.ClinDataPoint v7109 ON v7109.EventId=ce.EventId and v7109.ItemId=7109
    LEFT OUTER JOIN dbo.ClinDataPoint v7110 ON v7110.EventId=ce.EventId and v7110.ItemId=7110
    LEFT OUTER JOIN dbo.ClinDataPoint v7112 ON v7112.EventId=ce.EventId and v7112.ItemId=7112
    LEFT OUTER JOIN dbo.ClinDataPoint v7113 ON v7113.EventId=ce.EventId and v7113.ItemId=7113
    LEFT OUTER JOIN dbo.ClinDataPoint v7114 ON v7114.EventId=ce.EventId and v7114.ItemId=7114
    LEFT OUTER JOIN dbo.ClinDataPoint v7115 ON v7115.EventId=ce.EventId and v7115.ItemId=7115
    LEFT OUTER JOIN dbo.ClinDataPoint v7116 ON v7116.EventId=ce.EventId and v7116.ItemId=7116
    LEFT OUTER JOIN dbo.ClinDataPoint v7117 ON v7117.EventId=ce.EventId and v7117.ItemId=7117
    LEFT OUTER JOIN dbo.ClinDataPoint v7118 ON v7118.EventId=ce.EventId and v7118.ItemId=7118
    LEFT OUTER JOIN dbo.ClinDataPoint v7119 ON v7119.EventId=ce.EventId and v7119.ItemId=7119
    LEFT OUTER JOIN dbo.ClinDataPoint v7120 ON v7120.EventId=ce.EventId and v7120.ItemId=7120
    LEFT OUTER JOIN dbo.ClinDataPoint v7121 ON v7121.EventId=ce.EventId and v7121.ItemId=7121
    LEFT OUTER JOIN dbo.ClinDataPoint v7122 ON v7122.EventId=ce.EventId and v7122.ItemId=7122
    LEFT OUTER JOIN dbo.ClinDataPoint v7123 ON v7123.EventId=ce.EventId and v7123.ItemId=7123
    LEFT OUTER JOIN dbo.ClinDataPoint v7135 ON v7135.EventId=ce.EventId and v7135.ItemId=7135
    LEFT OUTER JOIN dbo.ClinDataPoint v7136 ON v7136.EventId=ce.EventId and v7136.ItemId=7136
    LEFT OUTER JOIN dbo.ClinDataPoint v7140 ON v7140.EventId=ce.EventId and v7140.ItemId=7140
    LEFT OUTER JOIN dbo.ClinDataPoint v7491 ON v7491.EventId=ce.EventId and v7491.ItemId=7491
    LEFT OUTER JOIN dbo.ClinDataPoint v7492 ON v7492.EventId=ce.EventId and v7492.ItemId=7492
    LEFT OUTER JOIN dbo.ClinDataPoint v7493 ON v7493.EventId=ce.EventId and v7493.ItemId=7493
    LEFT OUTER JOIN dbo.ClinDataPoint v7494 ON v7494.EventId=ce.EventId and v7494.ItemId=7494
    LEFT OUTER JOIN dbo.ClinDataPoint v7530 ON v7530.EventId=ce.EventId and v7530.ItemId=7530
    LEFT OUTER JOIN dbo.ClinDataPoint v7576 ON v7576.EventId=ce.EventId and v7576.ItemId=7576
    LEFT OUTER JOIN dbo.ClinDataPoint v7577 ON v7577.EventId=ce.EventId and v7577.ItemId=7577
    LEFT OUTER JOIN dbo.ClinDataPoint v7578 ON v7578.EventId=ce.EventId and v7578.ItemId=7578
    LEFT OUTER JOIN dbo.ClinDataPoint v7579 ON v7579.EventId=ce.EventId and v7579.ItemId=7579
    LEFT OUTER JOIN dbo.ClinDataPoint v7650 ON v7650.EventId=ce.EventId and v7650.ItemId=7650
    LEFT OUTER JOIN dbo.ClinDataPoint v7651 ON v7651.EventId=ce.EventId and v7651.ItemId=7651
    LEFT OUTER JOIN dbo.ClinDataPoint v7652 ON v7652.EventId=ce.EventId and v7652.ItemId=7652
    LEFT OUTER JOIN dbo.ClinDataPoint v7653 ON v7653.EventId=ce.EventId and v7653.ItemId=7653
    LEFT OUTER JOIN dbo.ClinDataPoint v7655 ON v7655.EventId=ce.EventId and v7655.ItemId=7655
  WHERE ( cf.DeletedAt IS NULL )
    AND ( cf.FormId=606 )
GO

ALTER VIEW FettVest.Form616 AS
  SELECT 
    ce.PersonId AS F616PersonId, 
    ce.EventId AS F616EventId, ce.EventTime AS F616EventTime, 
    cf.ClinFormId AS F616ClinFormId, cf.FormStatus AS F616FormStatus, cf.FormComplete AS F616FormComplete,
    v3935.EnumVal AS E3935_Incl,
    v3936.EnumVal AS E3936_Incl,
    v6449.EnumVal AS E6449_Incl,
    v6450.EnumVal AS E6450_Incl,
    v6451.EnumVal AS E6451_Incl,
    v6452.EnumVal AS E6452_Incl,
    v6453.EnumVal AS E6453_Incl,
    v6454.EnumVal AS E6454_Incl,
    v6455.EnumVal AS E6455_Incl,
    v6456.EnumVal AS E6456_Incl,
    v6457.EnumVal AS E6457_Incl,
    v6458.EnumVal AS E6458_Incl,
    v6459.EnumVal AS E6459_Incl,
    v6460.EnumVal AS E6460_Incl,
    v6461.EnumVal AS E6461_Incl,
    v6462.EnumVal AS E6462_Incl,
    v6463.EnumVal AS E6463_Incl,
    v6464.EnumVal AS E6464_Incl,
    v6465.EnumVal AS E6465_Incl,
    v6466.EnumVal AS E6466_Incl,
    v6467.EnumVal AS E6467_Incl,
    v6468.EnumVal AS E6468_Incl,
    v6469.EnumVal AS E6469_Incl,
    v6470.EnumVal AS E6470_Incl,
    v6471.EnumVal AS E6471_Incl,
    v6472.EnumVal AS E6472_Incl,
    v6473.EnumVal AS E6473_Incl,
    v6474.EnumVal AS E6474_Incl,
    v6475.EnumVal AS E6475_Incl,
    v6476.EnumVal AS E6476_Incl,
    v6481.EnumVal AS E6481_Incl,
    v6482.EnumVal AS E6482_Incl,
    v6483.EnumVal AS E6483_Incl,
    v6484.EnumVal AS E6484_Incl,
    v6485.EnumVal AS E6485_Incl,
    v6896.EnumVal AS E6896_Incl,
    v7617.EnumVal AS E7617_Incl,
    v7618.EnumVal AS E7618_Incl,
    v7619.EnumVal AS E7619_Incl,
    v7620.EnumVal AS E7620_Incl,
    v7621.EnumVal AS E7621_Incl,
    v7622.EnumVal AS E7622_Incl,
    v7623.EnumVal AS E7623_Incl,
    v7624.EnumVal AS E7624_Incl,
    v7625.EnumVal AS E7625_Incl,
    v7626.EnumVal AS E7626_Incl,
    v7627.EnumVal AS E7627_Incl,
    v7628.EnumVal AS E7628_Incl,
    v7629.EnumVal AS E7629_Incl,
    v7630.EnumVal AS E7630_Incl,
    v7631.EnumVal AS E7631_Incl,
    v7632.EnumVal AS E7632_Incl,
    v7633.EnumVal AS E7633_Incl,
    v7634.EnumVal AS E7634_Incl,
    v7635.EnumVal AS E7635_Incl,
    v7636.Quantity AS Q7636_Incl,
    v7637.EnumVal AS E7637_Incl,
    ROW_NUMBER() OVER ( PARTITION BY ce.PersonId ORDER BY EventTime DESC ) AS OrderNo616 
  FROM dbo.ClinForm cf
  JOIN dbo.ClinVisit ce ON ( ce.EventId = cf.EventId ) 
    LEFT OUTER JOIN dbo.ClinDataPoint v3935 ON v3935.EventId=ce.EventId and v3935.ItemId=3935
    LEFT OUTER JOIN dbo.ClinDataPoint v3936 ON v3936.EventId=ce.EventId and v3936.ItemId=3936
    LEFT OUTER JOIN dbo.ClinDataPoint v6449 ON v6449.EventId=ce.EventId and v6449.ItemId=6449
    LEFT OUTER JOIN dbo.ClinDataPoint v6450 ON v6450.EventId=ce.EventId and v6450.ItemId=6450
    LEFT OUTER JOIN dbo.ClinDataPoint v6451 ON v6451.EventId=ce.EventId and v6451.ItemId=6451
    LEFT OUTER JOIN dbo.ClinDataPoint v6452 ON v6452.EventId=ce.EventId and v6452.ItemId=6452
    LEFT OUTER JOIN dbo.ClinDataPoint v6453 ON v6453.EventId=ce.EventId and v6453.ItemId=6453
    LEFT OUTER JOIN dbo.ClinDataPoint v6454 ON v6454.EventId=ce.EventId and v6454.ItemId=6454
    LEFT OUTER JOIN dbo.ClinDataPoint v6455 ON v6455.EventId=ce.EventId and v6455.ItemId=6455
    LEFT OUTER JOIN dbo.ClinDataPoint v6456 ON v6456.EventId=ce.EventId and v6456.ItemId=6456
    LEFT OUTER JOIN dbo.ClinDataPoint v6457 ON v6457.EventId=ce.EventId and v6457.ItemId=6457
    LEFT OUTER JOIN dbo.ClinDataPoint v6458 ON v6458.EventId=ce.EventId and v6458.ItemId=6458
    LEFT OUTER JOIN dbo.ClinDataPoint v6459 ON v6459.EventId=ce.EventId and v6459.ItemId=6459
    LEFT OUTER JOIN dbo.ClinDataPoint v6460 ON v6460.EventId=ce.EventId and v6460.ItemId=6460
    LEFT OUTER JOIN dbo.ClinDataPoint v6461 ON v6461.EventId=ce.EventId and v6461.ItemId=6461
    LEFT OUTER JOIN dbo.ClinDataPoint v6462 ON v6462.EventId=ce.EventId and v6462.ItemId=6462
    LEFT OUTER JOIN dbo.ClinDataPoint v6463 ON v6463.EventId=ce.EventId and v6463.ItemId=6463
    LEFT OUTER JOIN dbo.ClinDataPoint v6464 ON v6464.EventId=ce.EventId and v6464.ItemId=6464
    LEFT OUTER JOIN dbo.ClinDataPoint v6465 ON v6465.EventId=ce.EventId and v6465.ItemId=6465
    LEFT OUTER JOIN dbo.ClinDataPoint v6466 ON v6466.EventId=ce.EventId and v6466.ItemId=6466
    LEFT OUTER JOIN dbo.ClinDataPoint v6467 ON v6467.EventId=ce.EventId and v6467.ItemId=6467
    LEFT OUTER JOIN dbo.ClinDataPoint v6468 ON v6468.EventId=ce.EventId and v6468.ItemId=6468
    LEFT OUTER JOIN dbo.ClinDataPoint v6469 ON v6469.EventId=ce.EventId and v6469.ItemId=6469
    LEFT OUTER JOIN dbo.ClinDataPoint v6470 ON v6470.EventId=ce.EventId and v6470.ItemId=6470
    LEFT OUTER JOIN dbo.ClinDataPoint v6471 ON v6471.EventId=ce.EventId and v6471.ItemId=6471
    LEFT OUTER JOIN dbo.ClinDataPoint v6472 ON v6472.EventId=ce.EventId and v6472.ItemId=6472
    LEFT OUTER JOIN dbo.ClinDataPoint v6473 ON v6473.EventId=ce.EventId and v6473.ItemId=6473
    LEFT OUTER JOIN dbo.ClinDataPoint v6474 ON v6474.EventId=ce.EventId and v6474.ItemId=6474
    LEFT OUTER JOIN dbo.ClinDataPoint v6475 ON v6475.EventId=ce.EventId and v6475.ItemId=6475
    LEFT OUTER JOIN dbo.ClinDataPoint v6476 ON v6476.EventId=ce.EventId and v6476.ItemId=6476
    LEFT OUTER JOIN dbo.ClinDataPoint v6481 ON v6481.EventId=ce.EventId and v6481.ItemId=6481
    LEFT OUTER JOIN dbo.ClinDataPoint v6482 ON v6482.EventId=ce.EventId and v6482.ItemId=6482
    LEFT OUTER JOIN dbo.ClinDataPoint v6483 ON v6483.EventId=ce.EventId and v6483.ItemId=6483
    LEFT OUTER JOIN dbo.ClinDataPoint v6484 ON v6484.EventId=ce.EventId and v6484.ItemId=6484
    LEFT OUTER JOIN dbo.ClinDataPoint v6485 ON v6485.EventId=ce.EventId and v6485.ItemId=6485
    LEFT OUTER JOIN dbo.ClinDataPoint v6896 ON v6896.EventId=ce.EventId and v6896.ItemId=6896
    LEFT OUTER JOIN dbo.ClinDataPoint v7617 ON v7617.EventId=ce.EventId and v7617.ItemId=7617
    LEFT OUTER JOIN dbo.ClinDataPoint v7618 ON v7618.EventId=ce.EventId and v7618.ItemId=7618
    LEFT OUTER JOIN dbo.ClinDataPoint v7619 ON v7619.EventId=ce.EventId and v7619.ItemId=7619
    LEFT OUTER JOIN dbo.ClinDataPoint v7620 ON v7620.EventId=ce.EventId and v7620.ItemId=7620
    LEFT OUTER JOIN dbo.ClinDataPoint v7621 ON v7621.EventId=ce.EventId and v7621.ItemId=7621
    LEFT OUTER JOIN dbo.ClinDataPoint v7622 ON v7622.EventId=ce.EventId and v7622.ItemId=7622
    LEFT OUTER JOIN dbo.ClinDataPoint v7623 ON v7623.EventId=ce.EventId and v7623.ItemId=7623
    LEFT OUTER JOIN dbo.ClinDataPoint v7624 ON v7624.EventId=ce.EventId and v7624.ItemId=7624
    LEFT OUTER JOIN dbo.ClinDataPoint v7625 ON v7625.EventId=ce.EventId and v7625.ItemId=7625
    LEFT OUTER JOIN dbo.ClinDataPoint v7626 ON v7626.EventId=ce.EventId and v7626.ItemId=7626
    LEFT OUTER JOIN dbo.ClinDataPoint v7627 ON v7627.EventId=ce.EventId and v7627.ItemId=7627
    LEFT OUTER JOIN dbo.ClinDataPoint v7628 ON v7628.EventId=ce.EventId and v7628.ItemId=7628
    LEFT OUTER JOIN dbo.ClinDataPoint v7629 ON v7629.EventId=ce.EventId and v7629.ItemId=7629
    LEFT OUTER JOIN dbo.ClinDataPoint v7630 ON v7630.EventId=ce.EventId and v7630.ItemId=7630
    LEFT OUTER JOIN dbo.ClinDataPoint v7631 ON v7631.EventId=ce.EventId and v7631.ItemId=7631
    LEFT OUTER JOIN dbo.ClinDataPoint v7632 ON v7632.EventId=ce.EventId and v7632.ItemId=7632
    LEFT OUTER JOIN dbo.ClinDataPoint v7633 ON v7633.EventId=ce.EventId and v7633.ItemId=7633
    LEFT OUTER JOIN dbo.ClinDataPoint v7634 ON v7634.EventId=ce.EventId and v7634.ItemId=7634
    LEFT OUTER JOIN dbo.ClinDataPoint v7635 ON v7635.EventId=ce.EventId and v7635.ItemId=7635
    LEFT OUTER JOIN dbo.ClinDataPoint v7636 ON v7636.EventId=ce.EventId and v7636.ItemId=7636
    LEFT OUTER JOIN dbo.ClinDataPoint v7637 ON v7637.EventId=ce.EventId and v7637.ItemId=7637
  WHERE ( cf.DeletedAt IS NULL )
    AND ( cf.FormId=616 )
GO

ALTER VIEW FettVest.Form628 AS
  SELECT 
    ce.PersonId AS F628PersonId, 
    ce.EventId AS F628EventId, ce.EventTime AS F628EventTime, 
    cf.ClinFormId AS F628ClinFormId, cf.FormStatus AS F628FormStatus, cf.FormComplete AS F628FormComplete,
    v7769.EnumVal AS E7769_Incl,
    v7770.EnumVal AS E7770_Incl,
    v7771.EnumVal AS E7771_Incl,
    v7772.EnumVal AS E7772_Incl,
    v7773.EnumVal AS E7773_Incl,
    v7774.EnumVal AS E7774_Incl,
    v7775.EnumVal AS E7775_Incl,
    v7776.EnumVal AS E7776_Incl,
    v7777.EnumVal AS E7777_Incl,
    v7778.Quantity AS Q7778_Incl,
    v7779.Quantity AS Q7779_Incl,
    v7780.Quantity AS Q7780_Incl,
    v7781.Quantity AS Q7781_Incl,
    v7782.Quantity AS Q7782_Incl,
    v7783.Quantity AS Q7783_Incl,
    v7784.EnumVal AS E7784_Incl,
    v7785.EnumVal AS E7785_Incl,
    v7786.EnumVal AS E7786_Incl,
    v7787.EnumVal AS E7787_Incl,
    v7788.EnumVal AS E7788_Incl,
    v7789.EnumVal AS E7789_Incl,
    v7790.EnumVal AS E7790_Incl,
    v7791.EnumVal AS E7791_Incl,
    v7792.EnumVal AS E7792_Incl,
    v7793.EnumVal AS E7793_Incl,
    v7794.EnumVal AS E7794_Incl,
    v7795.EnumVal AS E7795_Incl,
    v7796.EnumVal AS E7796_Incl,
    ROW_NUMBER() OVER ( PARTITION BY ce.PersonId ORDER BY EventTime DESC ) AS OrderNo628 
  FROM dbo.ClinForm cf
  JOIN dbo.ClinVisit ce ON ( ce.EventId = cf.EventId ) 
    LEFT OUTER JOIN dbo.ClinDataPoint v7769 ON v7769.EventId=ce.EventId and v7769.ItemId=7769
    LEFT OUTER JOIN dbo.ClinDataPoint v7770 ON v7770.EventId=ce.EventId and v7770.ItemId=7770
    LEFT OUTER JOIN dbo.ClinDataPoint v7771 ON v7771.EventId=ce.EventId and v7771.ItemId=7771
    LEFT OUTER JOIN dbo.ClinDataPoint v7772 ON v7772.EventId=ce.EventId and v7772.ItemId=7772
    LEFT OUTER JOIN dbo.ClinDataPoint v7773 ON v7773.EventId=ce.EventId and v7773.ItemId=7773
    LEFT OUTER JOIN dbo.ClinDataPoint v7774 ON v7774.EventId=ce.EventId and v7774.ItemId=7774
    LEFT OUTER JOIN dbo.ClinDataPoint v7775 ON v7775.EventId=ce.EventId and v7775.ItemId=7775
    LEFT OUTER JOIN dbo.ClinDataPoint v7776 ON v7776.EventId=ce.EventId and v7776.ItemId=7776
    LEFT OUTER JOIN dbo.ClinDataPoint v7777 ON v7777.EventId=ce.EventId and v7777.ItemId=7777
    LEFT OUTER JOIN dbo.ClinDataPoint v7778 ON v7778.EventId=ce.EventId and v7778.ItemId=7778
    LEFT OUTER JOIN dbo.ClinDataPoint v7779 ON v7779.EventId=ce.EventId and v7779.ItemId=7779
    LEFT OUTER JOIN dbo.ClinDataPoint v7780 ON v7780.EventId=ce.EventId and v7780.ItemId=7780
    LEFT OUTER JOIN dbo.ClinDataPoint v7781 ON v7781.EventId=ce.EventId and v7781.ItemId=7781
    LEFT OUTER JOIN dbo.ClinDataPoint v7782 ON v7782.EventId=ce.EventId and v7782.ItemId=7782
    LEFT OUTER JOIN dbo.ClinDataPoint v7783 ON v7783.EventId=ce.EventId and v7783.ItemId=7783
    LEFT OUTER JOIN dbo.ClinDataPoint v7784 ON v7784.EventId=ce.EventId and v7784.ItemId=7784
    LEFT OUTER JOIN dbo.ClinDataPoint v7785 ON v7785.EventId=ce.EventId and v7785.ItemId=7785
    LEFT OUTER JOIN dbo.ClinDataPoint v7786 ON v7786.EventId=ce.EventId and v7786.ItemId=7786
    LEFT OUTER JOIN dbo.ClinDataPoint v7787 ON v7787.EventId=ce.EventId and v7787.ItemId=7787
    LEFT OUTER JOIN dbo.ClinDataPoint v7788 ON v7788.EventId=ce.EventId and v7788.ItemId=7788
    LEFT OUTER JOIN dbo.ClinDataPoint v7789 ON v7789.EventId=ce.EventId and v7789.ItemId=7789
    LEFT OUTER JOIN dbo.ClinDataPoint v7790 ON v7790.EventId=ce.EventId and v7790.ItemId=7790
    LEFT OUTER JOIN dbo.ClinDataPoint v7791 ON v7791.EventId=ce.EventId and v7791.ItemId=7791
    LEFT OUTER JOIN dbo.ClinDataPoint v7792 ON v7792.EventId=ce.EventId and v7792.ItemId=7792
    LEFT OUTER JOIN dbo.ClinDataPoint v7793 ON v7793.EventId=ce.EventId and v7793.ItemId=7793
    LEFT OUTER JOIN dbo.ClinDataPoint v7794 ON v7794.EventId=ce.EventId and v7794.ItemId=7794
    LEFT OUTER JOIN dbo.ClinDataPoint v7795 ON v7795.EventId=ce.EventId and v7795.ItemId=7795
    LEFT OUTER JOIN dbo.ClinDataPoint v7796 ON v7796.EventId=ce.EventId and v7796.ItemId=7796
  WHERE ( cf.DeletedAt IS NULL )
    AND ( cf.FormId=628 )
GO

ALTER VIEW FettVest.Form650 AS
  SELECT 
    ce.PersonId AS F650PersonId, 
    ce.EventId AS F650EventId, ce.EventTime AS F650EventTime, 
    cf.ClinFormId AS F650ClinFormId, cf.FormStatus AS F650FormStatus, cf.FormComplete AS F650FormComplete,
    v7769.EnumVal AS E7769_12mnd,
    v7770.EnumVal AS E7770_12mnd,
    v7771.EnumVal AS E7771_12mnd,
    v7772.EnumVal AS E7772_12mnd,
    v7773.EnumVal AS E7773_12mnd,
    v7774.EnumVal AS E7774_12mnd,
    v7775.EnumVal AS E7775_12mnd,
    v7776.EnumVal AS E7776_12mnd,
    v7777.EnumVal AS E7777_12mnd,
    v7778.Quantity AS Q7778_12mnd,
    v7779.Quantity AS Q7779_12mnd,
    v7780.Quantity AS Q7780_12mnd,
    v7781.Quantity AS Q7781_12mnd,
    v7782.Quantity AS Q7782_12mnd,
    v7783.Quantity AS Q7783_12mnd,
    v7784.EnumVal AS E7784_12mnd,
    v7785.EnumVal AS E7785_12mnd,
    v7786.EnumVal AS E7786_12mnd,
    v7787.EnumVal AS E7787_12mnd,
    v7788.EnumVal AS E7788_12mnd,
    v7789.EnumVal AS E7789_12mnd,
    v7790.EnumVal AS E7790_12mnd,
    v7791.EnumVal AS E7791_12mnd,
    v7792.EnumVal AS E7792_12mnd,
    v7793.EnumVal AS E7793_12mnd,
    v7794.EnumVal AS E7794_12mnd,
    v7795.EnumVal AS E7795_12mnd,
    v7796.EnumVal AS E7796_12mnd,
    ROW_NUMBER() OVER ( PARTITION BY ce.PersonId ORDER BY EventTime DESC ) AS OrderNo650 
  FROM dbo.ClinForm cf
  JOIN dbo.ClinVisit ce ON ( ce.EventId = cf.EventId ) 
    LEFT OUTER JOIN dbo.ClinDataPoint v7769 ON v7769.EventId=ce.EventId and v7769.ItemId=7769
    LEFT OUTER JOIN dbo.ClinDataPoint v7770 ON v7770.EventId=ce.EventId and v7770.ItemId=7770
    LEFT OUTER JOIN dbo.ClinDataPoint v7771 ON v7771.EventId=ce.EventId and v7771.ItemId=7771
    LEFT OUTER JOIN dbo.ClinDataPoint v7772 ON v7772.EventId=ce.EventId and v7772.ItemId=7772
    LEFT OUTER JOIN dbo.ClinDataPoint v7773 ON v7773.EventId=ce.EventId and v7773.ItemId=7773
    LEFT OUTER JOIN dbo.ClinDataPoint v7774 ON v7774.EventId=ce.EventId and v7774.ItemId=7774
    LEFT OUTER JOIN dbo.ClinDataPoint v7775 ON v7775.EventId=ce.EventId and v7775.ItemId=7775
    LEFT OUTER JOIN dbo.ClinDataPoint v7776 ON v7776.EventId=ce.EventId and v7776.ItemId=7776
    LEFT OUTER JOIN dbo.ClinDataPoint v7777 ON v7777.EventId=ce.EventId and v7777.ItemId=7777
    LEFT OUTER JOIN dbo.ClinDataPoint v7778 ON v7778.EventId=ce.EventId and v7778.ItemId=7778
    LEFT OUTER JOIN dbo.ClinDataPoint v7779 ON v7779.EventId=ce.EventId and v7779.ItemId=7779
    LEFT OUTER JOIN dbo.ClinDataPoint v7780 ON v7780.EventId=ce.EventId and v7780.ItemId=7780
    LEFT OUTER JOIN dbo.ClinDataPoint v7781 ON v7781.EventId=ce.EventId and v7781.ItemId=7781
    LEFT OUTER JOIN dbo.ClinDataPoint v7782 ON v7782.EventId=ce.EventId and v7782.ItemId=7782
    LEFT OUTER JOIN dbo.ClinDataPoint v7783 ON v7783.EventId=ce.EventId and v7783.ItemId=7783
    LEFT OUTER JOIN dbo.ClinDataPoint v7784 ON v7784.EventId=ce.EventId and v7784.ItemId=7784
    LEFT OUTER JOIN dbo.ClinDataPoint v7785 ON v7785.EventId=ce.EventId and v7785.ItemId=7785
    LEFT OUTER JOIN dbo.ClinDataPoint v7786 ON v7786.EventId=ce.EventId and v7786.ItemId=7786
    LEFT OUTER JOIN dbo.ClinDataPoint v7787 ON v7787.EventId=ce.EventId and v7787.ItemId=7787
    LEFT OUTER JOIN dbo.ClinDataPoint v7788 ON v7788.EventId=ce.EventId and v7788.ItemId=7788
    LEFT OUTER JOIN dbo.ClinDataPoint v7789 ON v7789.EventId=ce.EventId and v7789.ItemId=7789
    LEFT OUTER JOIN dbo.ClinDataPoint v7790 ON v7790.EventId=ce.EventId and v7790.ItemId=7790
    LEFT OUTER JOIN dbo.ClinDataPoint v7791 ON v7791.EventId=ce.EventId and v7791.ItemId=7791
    LEFT OUTER JOIN dbo.ClinDataPoint v7792 ON v7792.EventId=ce.EventId and v7792.ItemId=7792
    LEFT OUTER JOIN dbo.ClinDataPoint v7793 ON v7793.EventId=ce.EventId and v7793.ItemId=7793
    LEFT OUTER JOIN dbo.ClinDataPoint v7794 ON v7794.EventId=ce.EventId and v7794.ItemId=7794
    LEFT OUTER JOIN dbo.ClinDataPoint v7795 ON v7795.EventId=ce.EventId and v7795.ItemId=7795
    LEFT OUTER JOIN dbo.ClinDataPoint v7796 ON v7796.EventId=ce.EventId and v7796.ItemId=7796
  WHERE ( cf.DeletedAt IS NULL )
    AND ( cf.FormId=650 )
GO

ALTER VIEW FettVest.Form652 AS
  SELECT 
    ce.PersonId AS F652PersonId, 
    ce.EventId AS F652EventId, ce.EventTime AS F652EventTime, 
    cf.ClinFormId AS F650ClinFormId, cf.FormStatus AS F652FormStatus, cf.FormComplete AS F652FormComplete,
    v7137.DTVal AS D7137_3m,
    v7274.EnumVal AS E7274_3m,
    v7275.EnumVal AS E7275_3m,
    v7276.DTVal AS D7276_3m,
    v7277.EnumVal AS E7277_3m,
    v7278.EnumVal AS E7278_3m,
    v7409.EnumVal AS E7409_3m,
    v7411.EnumVal AS E7411_3m,
    v7412.EnumVal AS E7412_3m,
    v7413.EnumVal AS E7413_3m,
    v7414.EnumVal AS E7414_3m,
    v7415.EnumVal AS E7415_3m,
    v7416.EnumVal AS E7416_3m,
    v7417.EnumVal AS E7417_3m,
    v7418.EnumVal AS E7418_3m,
    v7419.EnumVal AS E7419_3m,
    v7420.EnumVal AS E7420_3m,
    v7421.EnumVal AS E7421_3m,
    v7422.EnumVal AS E7422_3m,
    v7423.EnumVal AS E7423_3m,
    v7424.EnumVal AS E7424_3m,
    v7425.EnumVal AS E7425_3m,
    v7426.EnumVal AS E7426_3m,
    v7427.EnumVal AS E7427_3m,
    v7428.EnumVal AS E7428_3m,
    v7429.EnumVal AS E7429_3m,
    v7430.EnumVal AS E7430_3m,
    v7431.EnumVal AS E7431_3m,
    v7432.EnumVal AS E7432_3m,
    v7433.EnumVal AS E7433_3m,
    v7434.EnumVal AS E7434_3m,
    v7435.EnumVal AS E7435_3m,
    v7436.EnumVal AS E7436_3m,
    v7437.EnumVal AS E7437_3m,
    v7438.EnumVal AS E7438_3m,
    v7439.EnumVal AS E7439_3m,
    v7440.EnumVal AS E7440_3m,
    v7441.EnumVal AS E7441_3m,
    v7442.EnumVal AS E7442_3m,
    v7443.EnumVal AS E7443_3m,
    v7444.EnumVal AS E7444_3m,
    v7445.EnumVal AS E7445_3m,
    v7446.EnumVal AS E7446_3m,
    v7447.EnumVal AS E7447_3m,
    CONVERT(VARCHAR(16),v7448.TextVal) AS T7448_3m,
    v7449.EnumVal AS E7449_3m,
    v7450.EnumVal AS E7450_3m,
    v7451.EnumVal AS E7451_3m,
    v7452.EnumVal AS E7452_3m,
    v7453.EnumVal AS E7453_3m,
    v7454.EnumVal AS E7454_3m,
    v7455.Quantity AS Q7455_3m,
    v7456.EnumVal AS E7456_3m,
    v7457.EnumVal AS E7457_3m,
    v7458.EnumVal AS E7458_3m,
    v7459.EnumVal AS E7459_3m,
    v7460.EnumVal AS E7460_3m,
    v7461.EnumVal AS E7461_3m,
    v7462.EnumVal AS E7462_3m,
    v7463.EnumVal AS E7463_3m,
    v7464.EnumVal AS E7464_3m,
    v7465.EnumVal AS E7465_3m,
    v7466.EnumVal AS E7466_3m,
    v7467.EnumVal AS E7467_3m,
    CONVERT(VARCHAR(16),v7468.TextVal) AS T7468_3m,
    v7469.EnumVal AS E7469_3m,
    v7485.EnumVal AS E7485_3m,
    ROW_NUMBER() OVER ( PARTITION BY ce.PersonId ORDER BY EventTime DESC ) AS OrderNo652 
  FROM dbo.ClinForm cf
  JOIN dbo.ClinVisit ce ON ( ce.EventId = cf.EventId ) 
    LEFT OUTER JOIN dbo.ClinDataPoint v7137 ON v7137.EventId=ce.EventId and v7137.ItemId=7137
    LEFT OUTER JOIN dbo.ClinDataPoint v7274 ON v7274.EventId=ce.EventId and v7274.ItemId=7274
    LEFT OUTER JOIN dbo.ClinDataPoint v7275 ON v7275.EventId=ce.EventId and v7275.ItemId=7275
    LEFT OUTER JOIN dbo.ClinDataPoint v7276 ON v7276.EventId=ce.EventId and v7276.ItemId=7276
    LEFT OUTER JOIN dbo.ClinDataPoint v7277 ON v7277.EventId=ce.EventId and v7277.ItemId=7277
    LEFT OUTER JOIN dbo.ClinDataPoint v7278 ON v7278.EventId=ce.EventId and v7278.ItemId=7278
    LEFT OUTER JOIN dbo.ClinDataPoint v7409 ON v7409.EventId=ce.EventId and v7409.ItemId=7409
    LEFT OUTER JOIN dbo.ClinDataPoint v7411 ON v7411.EventId=ce.EventId and v7411.ItemId=7411
    LEFT OUTER JOIN dbo.ClinDataPoint v7412 ON v7412.EventId=ce.EventId and v7412.ItemId=7412
    LEFT OUTER JOIN dbo.ClinDataPoint v7413 ON v7413.EventId=ce.EventId and v7413.ItemId=7413
    LEFT OUTER JOIN dbo.ClinDataPoint v7414 ON v7414.EventId=ce.EventId and v7414.ItemId=7414
    LEFT OUTER JOIN dbo.ClinDataPoint v7415 ON v7415.EventId=ce.EventId and v7415.ItemId=7415
    LEFT OUTER JOIN dbo.ClinDataPoint v7416 ON v7416.EventId=ce.EventId and v7416.ItemId=7416
    LEFT OUTER JOIN dbo.ClinDataPoint v7417 ON v7417.EventId=ce.EventId and v7417.ItemId=7417
    LEFT OUTER JOIN dbo.ClinDataPoint v7418 ON v7418.EventId=ce.EventId and v7418.ItemId=7418
    LEFT OUTER JOIN dbo.ClinDataPoint v7419 ON v7419.EventId=ce.EventId and v7419.ItemId=7419
    LEFT OUTER JOIN dbo.ClinDataPoint v7420 ON v7420.EventId=ce.EventId and v7420.ItemId=7420
    LEFT OUTER JOIN dbo.ClinDataPoint v7421 ON v7421.EventId=ce.EventId and v7421.ItemId=7421
    LEFT OUTER JOIN dbo.ClinDataPoint v7422 ON v7422.EventId=ce.EventId and v7422.ItemId=7422
    LEFT OUTER JOIN dbo.ClinDataPoint v7423 ON v7423.EventId=ce.EventId and v7423.ItemId=7423
    LEFT OUTER JOIN dbo.ClinDataPoint v7424 ON v7424.EventId=ce.EventId and v7424.ItemId=7424
    LEFT OUTER JOIN dbo.ClinDataPoint v7425 ON v7425.EventId=ce.EventId and v7425.ItemId=7425
    LEFT OUTER JOIN dbo.ClinDataPoint v7426 ON v7426.EventId=ce.EventId and v7426.ItemId=7426
    LEFT OUTER JOIN dbo.ClinDataPoint v7427 ON v7427.EventId=ce.EventId and v7427.ItemId=7427
    LEFT OUTER JOIN dbo.ClinDataPoint v7428 ON v7428.EventId=ce.EventId and v7428.ItemId=7428
    LEFT OUTER JOIN dbo.ClinDataPoint v7429 ON v7429.EventId=ce.EventId and v7429.ItemId=7429
    LEFT OUTER JOIN dbo.ClinDataPoint v7430 ON v7430.EventId=ce.EventId and v7430.ItemId=7430
    LEFT OUTER JOIN dbo.ClinDataPoint v7431 ON v7431.EventId=ce.EventId and v7431.ItemId=7431
    LEFT OUTER JOIN dbo.ClinDataPoint v7432 ON v7432.EventId=ce.EventId and v7432.ItemId=7432
    LEFT OUTER JOIN dbo.ClinDataPoint v7433 ON v7433.EventId=ce.EventId and v7433.ItemId=7433
    LEFT OUTER JOIN dbo.ClinDataPoint v7434 ON v7434.EventId=ce.EventId and v7434.ItemId=7434
    LEFT OUTER JOIN dbo.ClinDataPoint v7435 ON v7435.EventId=ce.EventId and v7435.ItemId=7435
    LEFT OUTER JOIN dbo.ClinDataPoint v7436 ON v7436.EventId=ce.EventId and v7436.ItemId=7436
    LEFT OUTER JOIN dbo.ClinDataPoint v7437 ON v7437.EventId=ce.EventId and v7437.ItemId=7437
    LEFT OUTER JOIN dbo.ClinDataPoint v7438 ON v7438.EventId=ce.EventId and v7438.ItemId=7438
    LEFT OUTER JOIN dbo.ClinDataPoint v7439 ON v7439.EventId=ce.EventId and v7439.ItemId=7439
    LEFT OUTER JOIN dbo.ClinDataPoint v7440 ON v7440.EventId=ce.EventId and v7440.ItemId=7440
    LEFT OUTER JOIN dbo.ClinDataPoint v7441 ON v7441.EventId=ce.EventId and v7441.ItemId=7441
    LEFT OUTER JOIN dbo.ClinDataPoint v7442 ON v7442.EventId=ce.EventId and v7442.ItemId=7442
    LEFT OUTER JOIN dbo.ClinDataPoint v7443 ON v7443.EventId=ce.EventId and v7443.ItemId=7443
    LEFT OUTER JOIN dbo.ClinDataPoint v7444 ON v7444.EventId=ce.EventId and v7444.ItemId=7444
    LEFT OUTER JOIN dbo.ClinDataPoint v7445 ON v7445.EventId=ce.EventId and v7445.ItemId=7445
    LEFT OUTER JOIN dbo.ClinDataPoint v7446 ON v7446.EventId=ce.EventId and v7446.ItemId=7446
    LEFT OUTER JOIN dbo.ClinDataPoint v7447 ON v7447.EventId=ce.EventId and v7447.ItemId=7447
    LEFT OUTER JOIN dbo.ClinDataPoint v7448 ON v7448.EventId=ce.EventId and v7448.ItemId=7448
    LEFT OUTER JOIN dbo.ClinDataPoint v7449 ON v7449.EventId=ce.EventId and v7449.ItemId=7449
    LEFT OUTER JOIN dbo.ClinDataPoint v7450 ON v7450.EventId=ce.EventId and v7450.ItemId=7450
    LEFT OUTER JOIN dbo.ClinDataPoint v7451 ON v7451.EventId=ce.EventId and v7451.ItemId=7451
    LEFT OUTER JOIN dbo.ClinDataPoint v7452 ON v7452.EventId=ce.EventId and v7452.ItemId=7452
    LEFT OUTER JOIN dbo.ClinDataPoint v7453 ON v7453.EventId=ce.EventId and v7453.ItemId=7453
    LEFT OUTER JOIN dbo.ClinDataPoint v7454 ON v7454.EventId=ce.EventId and v7454.ItemId=7454
    LEFT OUTER JOIN dbo.ClinDataPoint v7455 ON v7455.EventId=ce.EventId and v7455.ItemId=7455
    LEFT OUTER JOIN dbo.ClinDataPoint v7456 ON v7456.EventId=ce.EventId and v7456.ItemId=7456
    LEFT OUTER JOIN dbo.ClinDataPoint v7457 ON v7457.EventId=ce.EventId and v7457.ItemId=7457
    LEFT OUTER JOIN dbo.ClinDataPoint v7458 ON v7458.EventId=ce.EventId and v7458.ItemId=7458
    LEFT OUTER JOIN dbo.ClinDataPoint v7459 ON v7459.EventId=ce.EventId and v7459.ItemId=7459
    LEFT OUTER JOIN dbo.ClinDataPoint v7460 ON v7460.EventId=ce.EventId and v7460.ItemId=7460
    LEFT OUTER JOIN dbo.ClinDataPoint v7461 ON v7461.EventId=ce.EventId and v7461.ItemId=7461
    LEFT OUTER JOIN dbo.ClinDataPoint v7462 ON v7462.EventId=ce.EventId and v7462.ItemId=7462
    LEFT OUTER JOIN dbo.ClinDataPoint v7463 ON v7463.EventId=ce.EventId and v7463.ItemId=7463
    LEFT OUTER JOIN dbo.ClinDataPoint v7464 ON v7464.EventId=ce.EventId and v7464.ItemId=7464
    LEFT OUTER JOIN dbo.ClinDataPoint v7465 ON v7465.EventId=ce.EventId and v7465.ItemId=7465
    LEFT OUTER JOIN dbo.ClinDataPoint v7466 ON v7466.EventId=ce.EventId and v7466.ItemId=7466
    LEFT OUTER JOIN dbo.ClinDataPoint v7467 ON v7467.EventId=ce.EventId and v7467.ItemId=7467
    LEFT OUTER JOIN dbo.ClinDataPoint v7468 ON v7468.EventId=ce.EventId and v7468.ItemId=7468
    LEFT OUTER JOIN dbo.ClinDataPoint v7469 ON v7469.EventId=ce.EventId and v7469.ItemId=7469
    LEFT OUTER JOIN dbo.ClinDataPoint v7485 ON v7485.EventId=ce.EventId and v7485.ItemId=7485
  WHERE ( cf.DeletedAt IS NULL )
    AND ( cf.FormId=652 )
GO

ALTER VIEW FettVest.Form681 AS
  SELECT 
    ce.PersonId AS F681PersonId, 
    ce.EventId AS F681EventId, ce.EventTime AS F681EventTime, 
    cf.ClinFormId AS F681ClinFormId, cf.FormStatus AS F681FormStatus, cf.FormComplete AS F681FormComplete,
    v3935.EnumVal AS E3935_12m,
    v3936.EnumVal AS E3936_12m,
    v6449.EnumVal AS E6449_12m,
    v6450.EnumVal AS E6450_12m,
    v6451.EnumVal AS E6451_12m,
    v6452.EnumVal AS E6452_12m,
    v6453.EnumVal AS E6453_12m,
    v6454.EnumVal AS E6454_12m,
    v6455.EnumVal AS E6455_12m,
    v6456.EnumVal AS E6456_12m,
    v6457.EnumVal AS E6457_12m,
    v6458.EnumVal AS E6458_12m,
    v6459.EnumVal AS E6459_12m,
    v6460.EnumVal AS E6460_12m,
    v6461.EnumVal AS E6461_12m,
    v6462.EnumVal AS E6462_12m,
    v6463.EnumVal AS E6463_12m,
    v6464.EnumVal AS E6464_12m,
    v6465.EnumVal AS E6465_12m,
    v6466.EnumVal AS E6466_12m,
    v6467.EnumVal AS E6467_12m,
    v6468.EnumVal AS E6468_12m,
    v6469.EnumVal AS E6469_12m,
    v6470.EnumVal AS E6470_12m,
    v6471.EnumVal AS E6471_12m,
    v6472.EnumVal AS E6472_12m,
    v6473.EnumVal AS E6473_12m,
    v6474.EnumVal AS E6474_12m,
    v6475.EnumVal AS E6475_12m,
    v6476.EnumVal AS E6476_12m,
    v6481.EnumVal AS E6481_12m,
    v6482.EnumVal AS E6482_12m,
    v6483.EnumVal AS E6483_12m,
    v6484.EnumVal AS E6484_12m,
    v6485.EnumVal AS E6485_12m,
    v6896.EnumVal AS E6896_12m,
    v7617.EnumVal AS E7617_12m,
    v7618.EnumVal AS E7618_12m,
    v7619.EnumVal AS E7619_12m,
    v7620.EnumVal AS E7620_12m,
    v7621.EnumVal AS E7621_12m,
    v7622.EnumVal AS E7622_12m,
    v7623.EnumVal AS E7623_12m,
    v7624.EnumVal AS E7624_12m,
    v7625.EnumVal AS E7625_12m,
    v7626.EnumVal AS E7626_12m,
    v7627.EnumVal AS E7627_12m,
    v7628.EnumVal AS E7628_12m,
    v7629.EnumVal AS E7629_12m,
    v7630.EnumVal AS E7630_12m,
    v7631.EnumVal AS E7631_12m,
    v7632.EnumVal AS E7632_12m,
    v7633.EnumVal AS E7633_12m,
    v7634.EnumVal AS E7634_12m,
    v7635.EnumVal AS E7635_12m,
    v7636.Quantity AS Q7636_12m,
    v7637.EnumVal AS E7637_12m,
    ROW_NUMBER() OVER ( PARTITION BY ce.PersonId ORDER BY EventTime DESC ) AS OrderNo681 
  FROM dbo.ClinForm cf
  JOIN dbo.ClinVisit ce ON ( ce.EventId = cf.EventId ) 
    LEFT OUTER JOIN dbo.ClinDataPoint v3935 ON v3935.EventId=ce.EventId and v3935.ItemId=3935
    LEFT OUTER JOIN dbo.ClinDataPoint v3936 ON v3936.EventId=ce.EventId and v3936.ItemId=3936
    LEFT OUTER JOIN dbo.ClinDataPoint v6449 ON v6449.EventId=ce.EventId and v6449.ItemId=6449
    LEFT OUTER JOIN dbo.ClinDataPoint v6450 ON v6450.EventId=ce.EventId and v6450.ItemId=6450
    LEFT OUTER JOIN dbo.ClinDataPoint v6451 ON v6451.EventId=ce.EventId and v6451.ItemId=6451
    LEFT OUTER JOIN dbo.ClinDataPoint v6452 ON v6452.EventId=ce.EventId and v6452.ItemId=6452
    LEFT OUTER JOIN dbo.ClinDataPoint v6453 ON v6453.EventId=ce.EventId and v6453.ItemId=6453
    LEFT OUTER JOIN dbo.ClinDataPoint v6454 ON v6454.EventId=ce.EventId and v6454.ItemId=6454
    LEFT OUTER JOIN dbo.ClinDataPoint v6455 ON v6455.EventId=ce.EventId and v6455.ItemId=6455
    LEFT OUTER JOIN dbo.ClinDataPoint v6456 ON v6456.EventId=ce.EventId and v6456.ItemId=6456
    LEFT OUTER JOIN dbo.ClinDataPoint v6457 ON v6457.EventId=ce.EventId and v6457.ItemId=6457
    LEFT OUTER JOIN dbo.ClinDataPoint v6458 ON v6458.EventId=ce.EventId and v6458.ItemId=6458
    LEFT OUTER JOIN dbo.ClinDataPoint v6459 ON v6459.EventId=ce.EventId and v6459.ItemId=6459
    LEFT OUTER JOIN dbo.ClinDataPoint v6460 ON v6460.EventId=ce.EventId and v6460.ItemId=6460
    LEFT OUTER JOIN dbo.ClinDataPoint v6461 ON v6461.EventId=ce.EventId and v6461.ItemId=6461
    LEFT OUTER JOIN dbo.ClinDataPoint v6462 ON v6462.EventId=ce.EventId and v6462.ItemId=6462
    LEFT OUTER JOIN dbo.ClinDataPoint v6463 ON v6463.EventId=ce.EventId and v6463.ItemId=6463
    LEFT OUTER JOIN dbo.ClinDataPoint v6464 ON v6464.EventId=ce.EventId and v6464.ItemId=6464
    LEFT OUTER JOIN dbo.ClinDataPoint v6465 ON v6465.EventId=ce.EventId and v6465.ItemId=6465
    LEFT OUTER JOIN dbo.ClinDataPoint v6466 ON v6466.EventId=ce.EventId and v6466.ItemId=6466
    LEFT OUTER JOIN dbo.ClinDataPoint v6467 ON v6467.EventId=ce.EventId and v6467.ItemId=6467
    LEFT OUTER JOIN dbo.ClinDataPoint v6468 ON v6468.EventId=ce.EventId and v6468.ItemId=6468
    LEFT OUTER JOIN dbo.ClinDataPoint v6469 ON v6469.EventId=ce.EventId and v6469.ItemId=6469
    LEFT OUTER JOIN dbo.ClinDataPoint v6470 ON v6470.EventId=ce.EventId and v6470.ItemId=6470
    LEFT OUTER JOIN dbo.ClinDataPoint v6471 ON v6471.EventId=ce.EventId and v6471.ItemId=6471
    LEFT OUTER JOIN dbo.ClinDataPoint v6472 ON v6472.EventId=ce.EventId and v6472.ItemId=6472
    LEFT OUTER JOIN dbo.ClinDataPoint v6473 ON v6473.EventId=ce.EventId and v6473.ItemId=6473
    LEFT OUTER JOIN dbo.ClinDataPoint v6474 ON v6474.EventId=ce.EventId and v6474.ItemId=6474
    LEFT OUTER JOIN dbo.ClinDataPoint v6475 ON v6475.EventId=ce.EventId and v6475.ItemId=6475
    LEFT OUTER JOIN dbo.ClinDataPoint v6476 ON v6476.EventId=ce.EventId and v6476.ItemId=6476
    LEFT OUTER JOIN dbo.ClinDataPoint v6481 ON v6481.EventId=ce.EventId and v6481.ItemId=6481
    LEFT OUTER JOIN dbo.ClinDataPoint v6482 ON v6482.EventId=ce.EventId and v6482.ItemId=6482
    LEFT OUTER JOIN dbo.ClinDataPoint v6483 ON v6483.EventId=ce.EventId and v6483.ItemId=6483
    LEFT OUTER JOIN dbo.ClinDataPoint v6484 ON v6484.EventId=ce.EventId and v6484.ItemId=6484
    LEFT OUTER JOIN dbo.ClinDataPoint v6485 ON v6485.EventId=ce.EventId and v6485.ItemId=6485
    LEFT OUTER JOIN dbo.ClinDataPoint v6896 ON v6896.EventId=ce.EventId and v6896.ItemId=6896
    LEFT OUTER JOIN dbo.ClinDataPoint v7617 ON v7617.EventId=ce.EventId and v7617.ItemId=7617
    LEFT OUTER JOIN dbo.ClinDataPoint v7618 ON v7618.EventId=ce.EventId and v7618.ItemId=7618
    LEFT OUTER JOIN dbo.ClinDataPoint v7619 ON v7619.EventId=ce.EventId and v7619.ItemId=7619
    LEFT OUTER JOIN dbo.ClinDataPoint v7620 ON v7620.EventId=ce.EventId and v7620.ItemId=7620
    LEFT OUTER JOIN dbo.ClinDataPoint v7621 ON v7621.EventId=ce.EventId and v7621.ItemId=7621
    LEFT OUTER JOIN dbo.ClinDataPoint v7622 ON v7622.EventId=ce.EventId and v7622.ItemId=7622
    LEFT OUTER JOIN dbo.ClinDataPoint v7623 ON v7623.EventId=ce.EventId and v7623.ItemId=7623
    LEFT OUTER JOIN dbo.ClinDataPoint v7624 ON v7624.EventId=ce.EventId and v7624.ItemId=7624
    LEFT OUTER JOIN dbo.ClinDataPoint v7625 ON v7625.EventId=ce.EventId and v7625.ItemId=7625
    LEFT OUTER JOIN dbo.ClinDataPoint v7626 ON v7626.EventId=ce.EventId and v7626.ItemId=7626
    LEFT OUTER JOIN dbo.ClinDataPoint v7627 ON v7627.EventId=ce.EventId and v7627.ItemId=7627
    LEFT OUTER JOIN dbo.ClinDataPoint v7628 ON v7628.EventId=ce.EventId and v7628.ItemId=7628
    LEFT OUTER JOIN dbo.ClinDataPoint v7629 ON v7629.EventId=ce.EventId and v7629.ItemId=7629
    LEFT OUTER JOIN dbo.ClinDataPoint v7630 ON v7630.EventId=ce.EventId and v7630.ItemId=7630
    LEFT OUTER JOIN dbo.ClinDataPoint v7631 ON v7631.EventId=ce.EventId and v7631.ItemId=7631
    LEFT OUTER JOIN dbo.ClinDataPoint v7632 ON v7632.EventId=ce.EventId and v7632.ItemId=7632
    LEFT OUTER JOIN dbo.ClinDataPoint v7633 ON v7633.EventId=ce.EventId and v7633.ItemId=7633
    LEFT OUTER JOIN dbo.ClinDataPoint v7634 ON v7634.EventId=ce.EventId and v7634.ItemId=7634
    LEFT OUTER JOIN dbo.ClinDataPoint v7635 ON v7635.EventId=ce.EventId and v7635.ItemId=7635
    LEFT OUTER JOIN dbo.ClinDataPoint v7636 ON v7636.EventId=ce.EventId and v7636.ItemId=7636
    LEFT OUTER JOIN dbo.ClinDataPoint v7637 ON v7637.EventId=ce.EventId and v7637.ItemId=7637
  WHERE ( cf.DeletedAt IS NULL )
    AND ( cf.FormId=681 )
GO

ALTER VIEW FettVest.Form709 AS
  SELECT 
    ce.PersonId AS F709PersonId, 
    ce.EventId AS F709EventId, ce.EventTime AS F709EventTime, 
    cf.ClinFormId AS F709ClinFormId, cf.FormStatus AS F709FormStatus, cf.FormComplete AS F709FormComplete,
    v3196.EnumVal AS E3196_12m,
    v3224.Quantity AS Q3224_12m,
    v3225.Quantity AS Q3225_12m,
    v3227.EnumVal AS E3227_12m,
    v3230.Quantity AS Q3230_12m,
    v3231.Quantity AS Q3231_12m,
    v3310.Quantity AS Q3310_12m,
    v3322.EnumVal AS E3322_12m,
    v3337.EnumVal AS E3337_12m,
    v3486.Quantity AS Q3486_12m,
    v4060.EnumVal AS E4060_12m,
    v4079.Quantity AS Q4079_12m,
    v4255.EnumVal AS E4255_12m,
    v4754.EnumVal AS E4754_12m,
    v4755.EnumVal AS E4755_12m,
    v4756.EnumVal AS E4756_12m,
    v6153.Quantity AS Q6153_12m,
    v6154.Quantity AS Q6154_12m,
    v6155.Quantity AS Q6155_12m,
    v6323.Quantity AS Q6323_12m,
    v6684.Quantity AS Q6684_12m,
    v6685.Quantity AS Q6685_12m,
    v6686.Quantity AS Q6686_12m,
    v6687.Quantity AS Q6687_12m,
    v6688.Quantity AS Q6688_12m,
    v6689.Quantity AS Q6689_12m,
    v6690.Quantity AS Q6690_12m,
    v6691.EnumVal AS E6691_12m,
    v6692.EnumVal AS E6692_12m,
    v6693.EnumVal AS E6693_12m,
    v6694.EnumVal AS E6694_12m,
    v6695.EnumVal AS E6695_12m,
    v6696.EnumVal AS E6696_12m,
    v6697.EnumVal AS E6697_12m,
    v6701.EnumVal AS E6701_12m,
    v6702.Quantity AS Q6702_12m,
    v6704.EnumVal AS E6704_12m,
    v6705.EnumVal AS E6705_12m,
    v6780.EnumVal AS E6780_12m,
    v6811.Quantity AS Q6811_12m,
    v6812.EnumVal AS E6812_12m,
    v6813.Quantity AS Q6813_12m,
    v6814.EnumVal AS E6814_12m,
    v6815.EnumVal AS E6815_12m,
    v6816.EnumVal AS E6816_12m,
    v6817.EnumVal AS E6817_12m,
    v6818.EnumVal AS E6818_12m,
    v6819.Quantity AS Q6819_12m,
    v6820.Quantity AS Q6820_12m,
    v6821.Quantity AS Q6821_12m,
    v6822.Quantity AS Q6822_12m,
    v6823.EnumVal AS E6823_12m,
    v6824.EnumVal AS E6824_12m,
    v6826.DTVal AS D6826_12m,
    v6828.EnumVal AS E6828_12m,
    v7067.Quantity AS Q7067_12m,
    v7137.DTVal AS D7137_12m,
    v7287.DTVal AS D7287_12m,
    v7288.Quantity AS Q7288_12m,
    v7289.Quantity AS Q7289_12m,
    v7290.Quantity AS Q7290_12m,
    v7302.Quantity AS Q7302_12m,
    v7303.Quantity AS Q7303_12m,
    v7304.EnumVal AS E7304_12m,
    v7306.EnumVal AS E7306_12m,
    v7308.EnumVal AS E7308_12m,
    v7310.EnumVal AS E7310_12m,
    v7311.Quantity AS Q7311_12m,
    v7312.EnumVal AS E7312_12m,
    v7314.EnumVal AS E7314_12m,
    v7316.EnumVal AS E7316_12m,
    v7318.EnumVal AS E7318_12m,
    v7322.EnumVal AS E7322_12m,
    v7491.EnumVal AS E7491_12m,
    v7492.EnumVal AS E7492_12m,
    v7493.EnumVal AS E7493_12m,
    v7494.EnumVal AS E7494_12m,
    v7530.EnumVal AS E7530_12m,
    v7576.EnumVal AS E7576_12m,
    v7577.EnumVal AS E7577_12m,
    v7578.EnumVal AS E7578_12m,
    v7579.EnumVal AS E7579_12m,
    v7650.Quantity AS Q7650_12m,
    v7652.EnumVal AS E7652_12m,
    v7653.EnumVal AS E7653_12m,
    v7655.EnumVal AS E7655_12m,
    CONVERT(VARCHAR(16),v8770.TextVal) AS T8770_12m,
    v8776.Quantity AS Q8776_12m,
    ROW_NUMBER() OVER ( PARTITION BY ce.PersonId ORDER BY EventTime DESC ) AS OrderNo709 
  FROM dbo.ClinForm cf
  JOIN dbo.ClinVisit ce ON ( ce.EventId = cf.EventId ) 
    LEFT OUTER JOIN dbo.ClinDataPoint v3196 ON v3196.EventId=ce.EventId and v3196.ItemId=3196
    LEFT OUTER JOIN dbo.ClinDataPoint v3224 ON v3224.EventId=ce.EventId and v3224.ItemId=3224
    LEFT OUTER JOIN dbo.ClinDataPoint v3225 ON v3225.EventId=ce.EventId and v3225.ItemId=3225
    LEFT OUTER JOIN dbo.ClinDataPoint v3227 ON v3227.EventId=ce.EventId and v3227.ItemId=3227
    LEFT OUTER JOIN dbo.ClinDataPoint v3230 ON v3230.EventId=ce.EventId and v3230.ItemId=3230
    LEFT OUTER JOIN dbo.ClinDataPoint v3231 ON v3231.EventId=ce.EventId and v3231.ItemId=3231
    LEFT OUTER JOIN dbo.ClinDataPoint v3310 ON v3310.EventId=ce.EventId and v3310.ItemId=3310
    LEFT OUTER JOIN dbo.ClinDataPoint v3322 ON v3322.EventId=ce.EventId and v3322.ItemId=3322
    LEFT OUTER JOIN dbo.ClinDataPoint v3337 ON v3337.EventId=ce.EventId and v3337.ItemId=3337
    LEFT OUTER JOIN dbo.ClinDataPoint v3486 ON v3486.EventId=ce.EventId and v3486.ItemId=3486
    LEFT OUTER JOIN dbo.ClinDataPoint v4060 ON v4060.EventId=ce.EventId and v4060.ItemId=4060
    LEFT OUTER JOIN dbo.ClinDataPoint v4079 ON v4079.EventId=ce.EventId and v4079.ItemId=4079
    LEFT OUTER JOIN dbo.ClinDataPoint v4255 ON v4255.EventId=ce.EventId and v4255.ItemId=4255
    LEFT OUTER JOIN dbo.ClinDataPoint v4754 ON v4754.EventId=ce.EventId and v4754.ItemId=4754
    LEFT OUTER JOIN dbo.ClinDataPoint v4755 ON v4755.EventId=ce.EventId and v4755.ItemId=4755
    LEFT OUTER JOIN dbo.ClinDataPoint v4756 ON v4756.EventId=ce.EventId and v4756.ItemId=4756
    LEFT OUTER JOIN dbo.ClinDataPoint v6153 ON v6153.EventId=ce.EventId and v6153.ItemId=6153
    LEFT OUTER JOIN dbo.ClinDataPoint v6154 ON v6154.EventId=ce.EventId and v6154.ItemId=6154
    LEFT OUTER JOIN dbo.ClinDataPoint v6155 ON v6155.EventId=ce.EventId and v6155.ItemId=6155
    LEFT OUTER JOIN dbo.ClinDataPoint v6323 ON v6323.EventId=ce.EventId and v6323.ItemId=6323
    LEFT OUTER JOIN dbo.ClinDataPoint v6684 ON v6684.EventId=ce.EventId and v6684.ItemId=6684
    LEFT OUTER JOIN dbo.ClinDataPoint v6685 ON v6685.EventId=ce.EventId and v6685.ItemId=6685
    LEFT OUTER JOIN dbo.ClinDataPoint v6686 ON v6686.EventId=ce.EventId and v6686.ItemId=6686
    LEFT OUTER JOIN dbo.ClinDataPoint v6687 ON v6687.EventId=ce.EventId and v6687.ItemId=6687
    LEFT OUTER JOIN dbo.ClinDataPoint v6688 ON v6688.EventId=ce.EventId and v6688.ItemId=6688
    LEFT OUTER JOIN dbo.ClinDataPoint v6689 ON v6689.EventId=ce.EventId and v6689.ItemId=6689
    LEFT OUTER JOIN dbo.ClinDataPoint v6690 ON v6690.EventId=ce.EventId and v6690.ItemId=6690
    LEFT OUTER JOIN dbo.ClinDataPoint v6691 ON v6691.EventId=ce.EventId and v6691.ItemId=6691
    LEFT OUTER JOIN dbo.ClinDataPoint v6692 ON v6692.EventId=ce.EventId and v6692.ItemId=6692
    LEFT OUTER JOIN dbo.ClinDataPoint v6693 ON v6693.EventId=ce.EventId and v6693.ItemId=6693
    LEFT OUTER JOIN dbo.ClinDataPoint v6694 ON v6694.EventId=ce.EventId and v6694.ItemId=6694
    LEFT OUTER JOIN dbo.ClinDataPoint v6695 ON v6695.EventId=ce.EventId and v6695.ItemId=6695
    LEFT OUTER JOIN dbo.ClinDataPoint v6696 ON v6696.EventId=ce.EventId and v6696.ItemId=6696
    LEFT OUTER JOIN dbo.ClinDataPoint v6697 ON v6697.EventId=ce.EventId and v6697.ItemId=6697
    LEFT OUTER JOIN dbo.ClinDataPoint v6701 ON v6701.EventId=ce.EventId and v6701.ItemId=6701
    LEFT OUTER JOIN dbo.ClinDataPoint v6702 ON v6702.EventId=ce.EventId and v6702.ItemId=6702
    LEFT OUTER JOIN dbo.ClinDataPoint v6704 ON v6704.EventId=ce.EventId and v6704.ItemId=6704
    LEFT OUTER JOIN dbo.ClinDataPoint v6705 ON v6705.EventId=ce.EventId and v6705.ItemId=6705
    LEFT OUTER JOIN dbo.ClinDataPoint v6780 ON v6780.EventId=ce.EventId and v6780.ItemId=6780
    LEFT OUTER JOIN dbo.ClinDataPoint v6811 ON v6811.EventId=ce.EventId and v6811.ItemId=6811
    LEFT OUTER JOIN dbo.ClinDataPoint v6812 ON v6812.EventId=ce.EventId and v6812.ItemId=6812
    LEFT OUTER JOIN dbo.ClinDataPoint v6813 ON v6813.EventId=ce.EventId and v6813.ItemId=6813
    LEFT OUTER JOIN dbo.ClinDataPoint v6814 ON v6814.EventId=ce.EventId and v6814.ItemId=6814
    LEFT OUTER JOIN dbo.ClinDataPoint v6815 ON v6815.EventId=ce.EventId and v6815.ItemId=6815
    LEFT OUTER JOIN dbo.ClinDataPoint v6816 ON v6816.EventId=ce.EventId and v6816.ItemId=6816
    LEFT OUTER JOIN dbo.ClinDataPoint v6817 ON v6817.EventId=ce.EventId and v6817.ItemId=6817
    LEFT OUTER JOIN dbo.ClinDataPoint v6818 ON v6818.EventId=ce.EventId and v6818.ItemId=6818
    LEFT OUTER JOIN dbo.ClinDataPoint v6819 ON v6819.EventId=ce.EventId and v6819.ItemId=6819
    LEFT OUTER JOIN dbo.ClinDataPoint v6820 ON v6820.EventId=ce.EventId and v6820.ItemId=6820
    LEFT OUTER JOIN dbo.ClinDataPoint v6821 ON v6821.EventId=ce.EventId and v6821.ItemId=6821
    LEFT OUTER JOIN dbo.ClinDataPoint v6822 ON v6822.EventId=ce.EventId and v6822.ItemId=6822
    LEFT OUTER JOIN dbo.ClinDataPoint v6823 ON v6823.EventId=ce.EventId and v6823.ItemId=6823
    LEFT OUTER JOIN dbo.ClinDataPoint v6824 ON v6824.EventId=ce.EventId and v6824.ItemId=6824
    LEFT OUTER JOIN dbo.ClinDataPoint v6826 ON v6826.EventId=ce.EventId and v6826.ItemId=6826
    LEFT OUTER JOIN dbo.ClinDataPoint v6828 ON v6828.EventId=ce.EventId and v6828.ItemId=6828
    LEFT OUTER JOIN dbo.ClinDataPoint v7067 ON v7067.EventId=ce.EventId and v7067.ItemId=7067
    LEFT OUTER JOIN dbo.ClinDataPoint v7137 ON v7137.EventId=ce.EventId and v7137.ItemId=7137
    LEFT OUTER JOIN dbo.ClinDataPoint v7287 ON v7287.EventId=ce.EventId and v7287.ItemId=7287
    LEFT OUTER JOIN dbo.ClinDataPoint v7288 ON v7288.EventId=ce.EventId and v7288.ItemId=7288
    LEFT OUTER JOIN dbo.ClinDataPoint v7289 ON v7289.EventId=ce.EventId and v7289.ItemId=7289
    LEFT OUTER JOIN dbo.ClinDataPoint v7290 ON v7290.EventId=ce.EventId and v7290.ItemId=7290
    LEFT OUTER JOIN dbo.ClinDataPoint v7302 ON v7302.EventId=ce.EventId and v7302.ItemId=7302
    LEFT OUTER JOIN dbo.ClinDataPoint v7303 ON v7303.EventId=ce.EventId and v7303.ItemId=7303
    LEFT OUTER JOIN dbo.ClinDataPoint v7304 ON v7304.EventId=ce.EventId and v7304.ItemId=7304
    LEFT OUTER JOIN dbo.ClinDataPoint v7306 ON v7306.EventId=ce.EventId and v7306.ItemId=7306
    LEFT OUTER JOIN dbo.ClinDataPoint v7308 ON v7308.EventId=ce.EventId and v7308.ItemId=7308
    LEFT OUTER JOIN dbo.ClinDataPoint v7310 ON v7310.EventId=ce.EventId and v7310.ItemId=7310
    LEFT OUTER JOIN dbo.ClinDataPoint v7311 ON v7311.EventId=ce.EventId and v7311.ItemId=7311
    LEFT OUTER JOIN dbo.ClinDataPoint v7312 ON v7312.EventId=ce.EventId and v7312.ItemId=7312
    LEFT OUTER JOIN dbo.ClinDataPoint v7314 ON v7314.EventId=ce.EventId and v7314.ItemId=7314
    LEFT OUTER JOIN dbo.ClinDataPoint v7316 ON v7316.EventId=ce.EventId and v7316.ItemId=7316
    LEFT OUTER JOIN dbo.ClinDataPoint v7318 ON v7318.EventId=ce.EventId and v7318.ItemId=7318
    LEFT OUTER JOIN dbo.ClinDataPoint v7322 ON v7322.EventId=ce.EventId and v7322.ItemId=7322
    LEFT OUTER JOIN dbo.ClinDataPoint v7491 ON v7491.EventId=ce.EventId and v7491.ItemId=7491
    LEFT OUTER JOIN dbo.ClinDataPoint v7492 ON v7492.EventId=ce.EventId and v7492.ItemId=7492
    LEFT OUTER JOIN dbo.ClinDataPoint v7493 ON v7493.EventId=ce.EventId and v7493.ItemId=7493
    LEFT OUTER JOIN dbo.ClinDataPoint v7494 ON v7494.EventId=ce.EventId and v7494.ItemId=7494
    LEFT OUTER JOIN dbo.ClinDataPoint v7530 ON v7530.EventId=ce.EventId and v7530.ItemId=7530
    LEFT OUTER JOIN dbo.ClinDataPoint v7576 ON v7576.EventId=ce.EventId and v7576.ItemId=7576
    LEFT OUTER JOIN dbo.ClinDataPoint v7577 ON v7577.EventId=ce.EventId and v7577.ItemId=7577
    LEFT OUTER JOIN dbo.ClinDataPoint v7578 ON v7578.EventId=ce.EventId and v7578.ItemId=7578
    LEFT OUTER JOIN dbo.ClinDataPoint v7579 ON v7579.EventId=ce.EventId and v7579.ItemId=7579
    LEFT OUTER JOIN dbo.ClinDataPoint v7650 ON v7650.EventId=ce.EventId and v7650.ItemId=7650
    LEFT OUTER JOIN dbo.ClinDataPoint v7652 ON v7652.EventId=ce.EventId and v7652.ItemId=7652
    LEFT OUTER JOIN dbo.ClinDataPoint v7653 ON v7653.EventId=ce.EventId and v7653.ItemId=7653
    LEFT OUTER JOIN dbo.ClinDataPoint v7655 ON v7655.EventId=ce.EventId and v7655.ItemId=7655
    LEFT OUTER JOIN dbo.ClinDataPoint v8770 ON v8770.EventId=ce.EventId and v8770.ItemId=8770
    LEFT OUTER JOIN dbo.ClinDataPoint v8776 ON v8776.EventId=ce.EventId and v8776.ItemId=8776
  WHERE ( cf.DeletedAt IS NULL )
    AND ( cf.FormId=709 )
GO

IF NOT OBJECT_ID('FettVest.T590') IS NULL DROP TABLE FettVest.T590
IF NOT OBJECT_ID('FettVest.T592') IS NULL DROP TABLE FettVest.T592
IF NOT OBJECT_ID('FettVest.T604') IS NULL DROP TABLE FettVest.T604
IF NOT OBJECT_ID('FettVest.T606') IS NULL DROP TABLE FettVest.T606
IF NOT OBJECT_ID('FettVest.T616') IS NULL DROP TABLE FettVest.T616
IF NOT OBJECT_ID('FettVest.T628') IS NULL DROP TABLE FettVest.T628
IF NOT OBJECT_ID('FettVest.T650') IS NULL DROP TABLE FettVest.T650
IF NOT OBJECT_ID('FettVest.T652') IS NULL DROP TABLE FettVest.T652
IF NOT OBJECT_ID('FettVest.T681') IS NULL DROP TABLE FettVest.T681
IF NOT OBJECT_ID('FettVest.T709') IS NULL DROP TABLE FettVest.T709
GO

SELECT * FROM FettVest.CaseList1Year c 
LEFT OUTER JOIN FettVest.T590 ON T590.F590PersonId=c.PersonId
LEFT OUTER JOIN FettVest.T592 ON T592.F592PersonId=c.PersonId
LEFT OUTER JOIN FettVest.T604 ON T604.F604PersonId=c.PersonId
LEFT OUTER JOIN FettVest.T606 ON T606.F606PersonId=c.PersonId
LEFT OUTER JOIN FettVest.T616 ON T616.F616PersonId=c.PersonId
LEFT OUTER JOIN FettVest.T628 ON T628.F628PersonId=c.PersonId
LEFT OUTER JOIN FettVest.T650 ON T650.F650PersonId=c.PersonId
LEFT OUTER JOIN FettVest.T652 ON T652.F652PersonId=c.PersonId
LEFT OUTER JOIN FettVest.T681 ON T681.F681PersonId=c.PersonId
LEFT OUTER JOIN FettVest.T709 ON T709.F709PersonId=c.PersonId
GO



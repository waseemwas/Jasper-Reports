select Sponsor AS [Sponsor Name]
,s.SiteId AS [Room Id]
, [Study Room] AS [Study Name]
, [Document ID] AS [Document Id]
, [Document Status] AS [Document Status]
, [Date Submitted] AS [Submitted On]
, [Date qc1 was completed] AS [QC1 Approved Date]
, [Date Finalized] AS [Published Date]
, CASE WHEN [Date qc1 clarification sent] IS NOT NULL OR [Date qc2 clarification sent] IS NOT NULL THEN 'Yes' ELSE '' END  AS Clarification
, CASE WHEN QueryDate IS NOT NULL THEN QueryStatus ELSE '' END AS Queries
, CASE WHEN MAX(wh.ReviewDate) IS NOT NULL THEN 'Yes' ELSE '' END AS [Under Review]
from [dbo].[vw_DocsQCData] dqd
LEFT JOIN vw_QueryDataFull qdf
	ON qdf.DocumentId = dqd.[Document ID]
LEFT JOIN WorkflowHistory wh
	ON wh.TopicId = dqd.[Document ID] AND Activity = 'QC Workflow - In Progress'
INNER JOIN Site s
	ON s.SiteName = dqd.[Study Room]
LEFT JOIN SiteMetadata sm ON sm.SiteId = s.SiteId
where
[Document Status] = 'Final' AND
sm.CDSReportStatus = 'Active' AND
[Date Finalized] >= '1/19/2026' AND [Date Finalized] <= '1/24/2026'
GROUP BY Sponsor,s.SiteId, [Study Room], [Document ID], [Document Status], [Date Submitted]
, [Date qc1 was completed], [Date Finalized], [Date qc1 clarification sent]
, [Date qc2 clarification sent], QueryDate, QueryStatus
ORDER BY Sponsor, s.SiteId, [Date Finalized]
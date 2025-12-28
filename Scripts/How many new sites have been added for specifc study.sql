--SELECT s.SiteName, s.SiteId, isd.[$AutoSiteName$], isd.[SiteNumber], isd.[StatusName]
--FROM dbo.Site s
--INNER JOIN vw_InvestigativeSiteData isd ON isd.SiteId = s.SiteId


SELECT COUNT(*) AS NewSiteCount FROM dbo.Site s 
INNER JOIN vw_InvestigativeSiteData isd ON isd.SiteId = s.SiteId WHERE s.CreatedDate >= '2025-07-01' AND s.SiteName = '410407' -- Uncomment and replace if filtering by specific site



SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Site' AND TABLE_SCHEMA = 'dbo';
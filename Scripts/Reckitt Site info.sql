SELECT s.SiteName, s.SiteId, isd.[$AutoSiteName$], isd.[SiteNumber], isd.[StatusName]
FROM dbo.Site s
INNER JOIN vw_InvestigativeSiteData isd ON isd.SiteId = s.SiteId
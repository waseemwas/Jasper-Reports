select s.SiteName ,[$$InstitutionName$$]
--, isd.TopicId
--,[$$DomainTopicId$$]
--, isd.CreatedDate, s.CreatedDate
, COUNT(dm.TopicId)
from [dbo].[vw_InvestigativeSiteData] isd
INNER JOIN site s
	ON s.SiteId = isd.SiteId
INNER JOIN SiteMetadata sm
	ON sm.SiteId = s.SiteId
INNER JOIN SiteCategory sc
	ON sc.SiteCategoryId = sm.SiteCategoryId
LEFT JOIN DocumentMetadata dm
	ON dm.InvestigativeSiteId = isd.[$$DomainTopicId$$]
WHERE sc.SiteCategoryName LIKE '%Premier%' and isd.CreatedDate > '02/14/2019'
and s.CreatedDate > '1/31/2019' --and dm.TopicId IS NULL
--AND [$$InstitutionName$$] = 'Woodland International Research Group'
GROUP BY s.SiteName ,[$$InstitutionName$$]
ORDER BY s.SiteName,[$$InstitutionName$$]
--HAVING COUNT(dm.TopicId) <> 0
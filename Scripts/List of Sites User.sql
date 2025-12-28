SELECT ism.SiteNumber, ism.[$AutoSiteName$], u.FullName
FROM InvestigativeSiteContacts isc
INNER JOIN [User] u ON u.UserId = isc.ContactId
INNER JOIN InvestigativeSiteMetadata ism ON ism.[$$ParentId$$] = isc.InvestigativeSiteId AND ism.SiteId = isc.SiteId
Where isc.SiteId in (6213)
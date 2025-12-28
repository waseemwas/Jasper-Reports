--SELECT 
--SiteName AS [Room Name],
--sud.FullName AS [Full Name],
--sud.[$$LastLoginDate$$] AS [Last Login],
--sud.EmailAddress AS [Email Address],
--[$$OrganizationName$$] AS [Organization Name],
--[$$RoleName$$] AS [Role Name]
--FROM vw_SiteUserData sud 
--INNER JOIN dbo.[User] u ON u.UserId = sud.UserId
--INNER JOIN dbo.UserMetadataVirtual umv ON umv.UserId = u.UserId AND umv.SiteId = sud.SiteId
--WHERE ISNULL(umv.RoleLevel, 0) < 500 AND sud.SiteName <> 'System' AND [$$InvitedBy$$] <> 'API Service' AND sud.UserName NOT LIKE '%contact.ct%'
--AND NOT EXISTS (SELECT * FROM [dbo].[InvestigativeSiteContacts] isc WHERE isc.SiteID = sud.[SiteId] AND isc.ContactId = sud.UserId) AND [$$OrganizationName$$] LIKE '%Niaid%'



SELECT
    s.SiteName AS [Room Name],
    u.FullName AS [Full Name],
    u.emailAddress AS [Email Address],
    MAX(ual.CreatedDate) AS [Last Login],
    u.OrganizationName AS [Organization Name],
    r.RoleName AS [Role Name]
FROM dbo.UserActivityLog ual
INNER JOIN dbo.Site s ON s.SiteId = ual.SiteId
INNER JOIN dbo.[User] u ON u.UserId = ual.CreatedBy
LEFT JOIN dbo.UserRole ur ON ur.UserId = u.UserId AND ur.SiteId = s.SiteId
LEFT JOIN dbo.Role r ON r.RoleLevel = ur.RoleLevel
WHERE ual.UserActivityTypeId = 36
GROUP BY
    s.SiteName,
    u.FullName,
    u.emailAddress,
    u.OrganizationName,
    r.RoleName
SELECT 
sud.SiteId AS [Room Id],
SiteName AS [Room Name],
sud.FullName AS [Full Name],
sud.FirstName AS [First Name],
sud.LastName AS [Last Name],
sud.UserName AS [Email Address],
[$$OrganizationName$$] AS [Organization Name],
[$$RoleName$$] AS [Role Name]
FROM vw_SiteUserData sud 
INNER JOIN dbo.[User] u ON u.UserId = sud.UserId
INNER JOIN dbo.UserMetadataVirtual umv ON umv.UserId = u.UserId AND umv.SiteId = sud.SiteId
WHERE ISNULL(umv.RoleLevel, 0) < 500 AND sud.SiteName <> 'System' AND [$$InvitedBy$$] <> 'API Service' AND sud.UserName NOT LIKE '%contact.ct%'
AND NOT EXISTS (SELECT * FROM [dbo].[InvestigativeSiteContacts] isc WHERE isc.SiteID = sud.[SiteId] AND isc.ContactId = sud.UserId) 
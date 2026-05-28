SELECT 
sud.SiteId AS [Room Id],
sud.SiteName AS [Room Name],
sud.FullName AS [Full Name],
sud.EmailAddress AS [Email Address],
sud.[$$OrganizationName$$] AS [Organization Name]
FROM vw_SiteUserData sud 
WHERE sud.SiteId = 711
AND sud.[$$IsDeleted$$] = 1
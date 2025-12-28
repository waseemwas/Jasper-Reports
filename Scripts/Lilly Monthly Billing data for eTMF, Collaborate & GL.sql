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
INNER JOIN dbo.[User] u 
    ON u.UserId = sud.UserId
INNER JOIN dbo.UserMetadataVirtual umv 
    ON umv.UserId = u.UserId 
    AND umv.SiteId = sud.SiteId
WHERE ISNULL(umv.RoleLevel, 0) < 500
  AND sud.SiteName <> 'System'
  AND [$$InvitedBy$$] <> 'API Service'
  AND sud.UserName NOT LIKE '%contact.ct%'
  AND NOT EXISTS (
        SELECT * 
        FROM [dbo].[InvestigativeSiteContacts] isc 
        WHERE isc.SiteID = sud.[SiteId] 
          AND isc.ContactId = sud.UserId
    )
  AND sud.SiteId IN (
        10,18,19,22,23,30,32,34,35,36,37,38,39,41,42,43,44,45,46,47,
        48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,
        68,69,70,71,72,73,74,75,76,77,78
    );

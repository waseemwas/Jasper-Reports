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
  AND sud.SiteId BETWEEN 10 AND 200;


------Add the SiteID as needed-------

-------Updated one---------

SELECT 
    sud.SiteId AS [Room Id], 
    sud.SiteName AS [Room Name],
    [$$InvitedOn$$] AS [Invited On], 
    sud.FullName AS [User Full Name], 
    sud.UserName AS [User Email Address], 
    [$$InvitedBy$$] AS [Invited By],
    [$$OrganizationName$$] AS [Organization Name], 
    [$$RoleName$$] AS [Current Access Level],
    [$$Actions$$] AS [Actions]

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
        FROM dbo.[InvestigativeSiteContacts] isc 
        WHERE isc.SiteID = sud.SiteId 
          AND isc.ContactId = sud.UserId
    )
  AND sud.SiteId BETWEEN 10 AND 300;

------ Add the SiteID as needed ------

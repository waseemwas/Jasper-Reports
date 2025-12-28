select umv.UserId, u.UserName, u.FirstName + ' ' + u.LastName AS UserFullName, u.OrganizationName
, umv.InvitedOn, umv.RoleName, umv.AccessRevokedOn, umv.Actions, umv.Groups, s.SiteName
from UserMetadataVirtual umv (NOLOCK)
INNER JOIN [User] u (NOLOCK)
	ON umv.UserId = u.UserId
INNER JOIN Site s	
	ON s.SiteId = umv.SiteId
WHERE RoleName <> 'SuperAdministrator'
AND UserName NOT LIKE '%@transperfect.com%'
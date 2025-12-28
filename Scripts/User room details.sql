DECLARE @UserId INT = (SELECT UserId FROM dbo.[User] u WHERE u.UserName = 'nurkhairunnisa@crc.moh.gov.my')
SELECT s.SiteId, s.SiteName, la.CreatedDate AS LastAccess, r.RoleName
FROM Site s 
INNER JOIN dbo.UserRole ur ON ur.SiteId = s.SiteId
    AND ur.UserId = @UserId
INNER JOIN dbo.Role r ON r.RoleLevel = ur.RoleLevel
LEFT JOIN 
(
                SELECT ual.SiteId, MAX(ual.CreatedDate) CreatedDate
                FROM dbo.UserActivityLog ual 
                WHERE ual.UserActivityTypeId = 36 --Login To Site
                    AND ual.CreatedBy = @UserId
                GROUP BY ual.SiteId
) la ON la.SiteId = s.SiteId
ORDER BY LastAccess DESC

 
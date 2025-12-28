DECLARE @SiteTopicTypeId INT
DECLARE @SiteCategoryTopicTypeId INT

DECLARE @DomainId INT = 1

SELECT @SiteTopicTypeId = TopicTypeId FROM TopicType WHERE TypeName = N'Site'
SELECT @SiteCategoryTopicTypeId = tt.TopicTypeId FROM dbo.TopicType tt WHERE tt.TypeName = N'SiteCategory'

CREATE TABLE #SiteInfo (SiteId INT, StatusId INT, SiteName VARCHAR(255), SiteIndexPath VARCHAR(255), SiteCreatedDate DATE, SiteClonedFrom VARCHAR(255))

;WITH SiteFolders(FolderId, ParentFolderId, IndexPath) AS
(
SELECT sf.TopicId, sf.ParentId, CAST(sf.TopicName AS NVARCHAR(MAX)) AS IndexPath
FROM Topic sf (NOLOCK)
WHERE sf.TopicTypeId = @SiteCategoryTopicTypeId
    AND sf.ParentId IS NULL

UNION ALL 
            
SELECT 
      chf.TopicId AS FolderId,
      chf.ParentId AS ParentFolderId,
      ISNULL(f.IndexPath + N'\', N'') + chf.TopicName AS IndexPath
FROM SiteFolders f
INNER JOIN dbo.Topic chf ON chf.ParentId = f.FolderId
    AND chf.TopicTypeId = @SiteCategoryTopicTypeId
)

INSERT INTO #SiteInfo (SiteId, StatusId, SiteName,SiteIndexPath,SiteClonedFrom)
SELECT s.SiteId, s.StatusId, s.SiteName, ISNULL(sf.IndexPath, N'Root (no folder specified)') AS IndexPath
--, CASE WHEN tf.Fieldvalue = '' THEN s.LastUpdated ELSE tf.Fieldvalue END
,sc.SiteName
FROM dbo.Site s (NOLOCK)
INNER JOIN dbo.Topic st (NOLOCK) ON st.TopicTypeId = @SiteTopicTypeId
    AND st.TopicName = s.SiteName 
LEFT JOIN dbo.TopicFields tf (NOLOCK) ON
st.TopicId = tf.TopicId AND tf.FieldName = 'ClonedFromSiteId'
--AND FieldName = 'DeactivationDate'
LEFT JOIN SiteFolders sf ON sf.FolderId = st.ParentId
INNER JOIN Site sc (NOLOCK)
	ON tf.Fieldvalue = sc.SiteId
WHERE  s.SiteTypeId = 1
    AND s.StatusId = 1
	--AND sf.IndexPath LIKE '%3.0%'
	--AND s.SiteId IN (737)
ORDER BY s.SiteName,s.Createddate,IndexPath

--SELECT * FROM #SiteInfo
DECLARE @LoginActivityTypeId INT;
    SET @LoginActivityTypeId = (SELECT UserActivityTypeId FROM UserActivityType WHERE UserActivityType = 'Login To Site');

CREATE TABLE #UserInfo (
SiteId INT,
SiteName NVARCHAR(100),
UserId INT,
UserName NVARCHAR(100),
FirstName NVARCHAR(100),
LastName NVARCHAR(100),
UserFullName NVARCHAR(100),
UserStatus NVARCHAR(100),
UserInvitedBy NVARCHAR(100),
DateUserInvited DATETIME,
DateAccessRevoked DATETIME,
UserRole NVARCHAR(100),
LoginCount INT,
Organization NVARCHAR(100),
SiteIndexPath VARCHAR(255),
--LastLoginDate DATETIME,
--NumberofInboxSubmissions INT,
--LastEmailSentDate DATETIME,
GroupName VARCHAR(255),
SystemGroup BIT
)

INSERT INTO #UserInfo
select DISTINCT acct.SiteId, s.SiteName AS RoomName
--, acct.TopicId AS DocumentId
--, t.TopicName AS InvestigativeSiteName
, u.UserId,u.UserName, u.FirstName, u.LastName, u.FirstName + ' ' + u.LastName AS [User Full Name]
, CASE WHEN u.StatusId = 1 AND r.RoleName <> 'No Access' THEN 'Invited'
WHEN u.StatusId = 1 AND r.RoleName = 'No Access' THEN 'Access Revoked' END
, createdBy.UserName
, acct.CreatedDate AS [Date User Invited]
--, '' AS DateAccessRevoked
, CASE WHEN r.RoleName = 'No Access' THEN CONVERT(varchar,	acct.CreatedDate,120) WHEN r.RoleName <> 'No Access' THEN ' ' END AS [Date Access was Revoked]
--, createdBy.UserId
--, createdBy.FirstName + ' ' + createdBy.LastName AS [Created By]
--, actType.UserActivityType As ActivityType
--, acct.SubsystemId
, r.RoleName AS [User Role]
, '' AS LoginCount
, u.OrganizationName AS Organization
, s.SiteIndexPath
--, '' AS LastLoginDate
--, '' AS NumberofInboxSubmissions
--, '' AS LastEmailSentDate
, g1.DisplayName
, g1.IsSystemGroup
--, ap.Title
--CASE WHEN acct.TextFld IS NULL THEN g.DisplayName ELSE acct.TextFld END [Activity Text]
--acct.TextFld AS [Activity Text], acct.IntFld--, g.DisplayName AS [Group Name]
--,actType.Notes
from UserActivityLog (nolock) acct
inner join UserActivityType (NOLOCK) actType on acct.UserActivityTypeId = actType.UserActivityTypeId
inner join [User] (nolock)  u on acct.SubsystemId = u.UserId --ANd u.Password IS NOT NULL
--inner join TopicArchive t (nolock) ON  acct.TopicId = t.TopicId
inner join [User] createdBy (nolock) ON acct.CreatedBy = createdBy.UserId
inner join #SiteInfo s (nolock) ON acct.SiteId = s.SiteId
OUTER APPLY dbo.GetUserRolesTable(s.SiteId,  acct.SubsystemId) ur
LEFT JOIN dbo.[Role] r ON r.RoleLevel = ur.RoleLevel
INNER JOIN
(
	SELECT sg.SiteId, ug.UserId, g.GroupId, g.GroupName, g.DisplayName, g.IsSystemGroup
		        FROM [dbo].[UserGroup] ug
		        INNER JOIN [dbo].[SiteUsers] AS sg ON ug.[GroupId] = sg.[GroupId]
		        INNER JOIN [dbo].[Group] AS g ON sg.[GroupId] = g.[GroupId]
												 AND (g.[DomainId] = @DomainId OR @DomainId IS NULL)
) g1 ON g1.SiteId = acct.SiteId AND g1.UserId = u.UserId
--inner join AuditProfile ap (nolock) ON acct.SubsystemId = ap.AuditProfileId
--left join [Group] g (nolock) ON acct.IntFld = g.GroupId AND acct.UserActivityTypeId = 109
where --acct.SubsystemId IN (47387,
--19381,
--114994,
--57347,
--143275,
--29998) AND
u.StatusId <> 2
AND 
actType.UserActivityType IN ('Invite User') --AND actType.UserActivityType = 'Invite User'
--AND u.CreatedDate >= '07/20/2020' AND u.CreatedDate <= '08/01/2020'
--AND r.RoleName = 'No Access'
--AND u.UserName LIKE '%natalia.cappelletti%'
--AND acct.CreatedDate >= '01/01/2018'
--AND acct.SubsystemId = 205234
--actType.UserActivityType LIKE '%Audit%'
--AND actType.UserActivityType <> 'Publish Documents To Audit'
--t.TopicId IN (1863185)
--,,1863181,1863175
--AND acct.SiteId IN (29) --AND acct.CreatedBy = 5040
AND g1.IsSystemGroup = 0
--AND 
--acct.[SubsystemTypeId] = 4 
--and acct.UserActivityTypeId <> 36
order by s.SiteName, acct.CreatedDate
--t.TopicId,
-- ap.Title,

--SELECT * FROM #UserInfo

--;WITH ualLoginAttempts AS
--(
--	SELECT ui.SiteId, ui.UserId, LoginCount = COUNT(UserActivityLog.UserActivityLogId)
--	, LastLoginDate = MAX(UserActivityLog.CreatedDate) 
--	FROM UserActivityLog
--	INNER JOIN #UserInfo ui ON ui.SiteId = UserActivityLog.SiteId AND ui.UserId = UserActivityLog.CreatedBy
--	AND UserActivityLog.UserActivityTypeId = 36 
--	WHERE UserActivityLog.CreatedDate >= DATEADD(DAY, -90, GETDATE())
--	GROUP BY ui.SiteId, ui.UserId
--)

--UPDATE ui2
--SET ui2.LastLoginDate = ula.LastLoginDate
--, ui2.LoginCount = ula.LoginCount
--FROM #UserInfo ui2
--INNER JOIN ualLoginAttempts ula 
--ON ui2.SiteId = ula.SiteId AND ui2.UserId = ula.userid 

--UPDATE ui
--SET ui.DateAccessRevoked = ualDeactivate.CreatedDate
--FROM #UserInfo ui
--INNER JOIN UserActivityLog ualDeactivate 
--ON ui.SiteId = ualDeactivate.SiteId AND ui.UserId = ualDeactivate.SubsystemId AND ualDeactivate.UserActivityTypeId = 167

--;WITH tfSenderAddress AS
--(
--	SELECT ui.SiteId, ui.UserId, NumberofInboxSubmissions = COUNT(FieldId), LastEmailSentDate = MAX(tf.CreatedDate) FROM TopicFields tf
--	INNER JOIN #UserInfo ui ON ui.SiteId = tf.SiteId AND ui.UserName = tf.Fieldvalue AND tf.FieldName = 'Sender Address'
--	GROUP BY ui.SiteId, ui.UserId
--)

----SELECT * FROM tfSenderAddress

--UPDATE ui3
--SET ui3.NumberofInboxSubmissions = tsa.NumberofInboxSubmissions
--, ui3.LastEmailSentDate = tsa.LastEmailSentDate
--FROM #UserInfo ui3
--INNER JOIN tfSenderAddress tsa 
--ON ui3.SiteId = tsa.SiteId AND ui3.UserId = tsa.UserId

SELECT DISTINCT SiteName AS [Room Name], FirstName AS [First Name], LastName AS [Last Name], UserFullName AS [User Full Name],
UserName AS [User Name], UserRole AS [Role Name], Organization, MAX(DateUserInvited) AS [Invited On]
,CASE WHEN MAX(DateAccessRevoked) = '1900-01-01 00:00:00.000' THEN ' ' ELSE MAX(DateAccessRevoked) END AS [Access Revoked Date]
FROM #UserInfo
GROUP BY SiteName, FirstName, LastName, UserName, UserFullName, UserRole, Organization

DROP TABLE #SiteInfo
DROP TABLE #UserInfo

------------------------------------------------------------
-- specify Domain Id and Instance name ---------------------

DECLARE @DomainId INT = 1
DECLARE @SystemName NVARCHAR(200) = N'Deal Interactive'

------------------------------------------------------------

DECLARE @SystemSiteId INT
SELECT @SystemSiteId = s.SiteId
FROM dbo.Site s
WHERE s.DomainId = @DomainId 
    AND s.SiteTypeId = 2 -- system site type

CREATE TABLE #RoomsInfo ( 
    RoomId INT PRIMARY KEY, 
    RoomName NVARCHAR(100), 
    Sponsor NVARCHAR(2000), 
    ProtocolNumber NVARCHAR(2000),
    Study NVARCHAR(2000)
)

DECLARE @SiteTopicTypeId INT
SELECT @SiteTopicTypeId = tt.TopicTypeId
FROM TopicType tt
WHERE tt.TypeName = N'Site'

DECLARE @ProtocolNumberLbl NVARCHAR(150) = dbo.GetLabelNameForTopicAttributes(@SystemSiteId, @SiteTopicTypeId, N'ProtocolNumber')
DECLARE @SponsorIdLbl NVARCHAR(150) = dbo.GetLabelNameForTopicAttributes(@SystemSiteId, @SiteTopicTypeId, N'SponsorId')
DECLARE @StudyLbl NVARCHAR(150) = dbo.GetLabelNameForTopicAttributes(@SystemSiteId, @SiteTopicTypeId, N'Study')

DECLARE @Query NVARCHAR(4000) = N'
    INSERT INTO #RoomsInfo ( RoomId, RoomName )
    SELECT s.SiteId, s.SiteName
    FROM dbo.Site s
    INNER JOIN dbo.Topic st ON st.SiteId = @SystemSiteId
        AND st.TopicTypeId = @SiteTopicTypeId
        AND s.SiteName = st.TopicName
    --INNER JOIN dbo.' + dbo.GetTopicAttributesTableName(@SystemSiteId) + N' ta ON st.TopicId = ta.TopicId
    --LEFT JOIN dbo.Topic sp ON ta.' + @SponsorIdLbl + N' = sp.TopicId
    WHERE s.StatusId = 1 -- Active
        AND s.SiteTypeId = 1 -- Regular Rooms
        --AND st.ParentId = 245131
        AND s.DomainId = @DomainId
		--AND s.SiteId = 1603
'

--SELECT @Query

DECLARE @ParamDefinition NVARCHAR(500)
SET @ParamDefinition = N'@DomainId INT, @SystemSiteId INT, @SiteTopicTypeId INT'

EXEC SP_EXECUTESQL @Query, @ParamDefinition, 
    @DomainId = @DomainId, 
    @SystemSiteId = @SystemSiteId, 
    @SiteTopicTypeId = @SiteTopicTypeId

DECLARE @RegularUserTypeId INT = 3; -- TypeId from UserType where TypeName = 'Regular User'

CREATE TABLE #result (
    SystemName NVARCHAR(200),
    UserId INT,
    UserName NVARCHAR(50),
    Password NVARCHAR(2000),
    FullName NVARCHAR(150),
    RoomName NVARCHAR(100),
    Sponsor NVARCHAR(2000),
    ProtocolNumber NVARCHAR(2000),
    Study NVARCHAR(2000),
    RoleName NVARCHAR(50)
)

INSERT INTO #result
        ( SystemName ,
          UserId ,
          UserName ,
          Password ,
          FullName ,
          RoomName ,
          Sponsor ,
          ProtocolNumber ,
          Study ,
          RoleName
        )
SELECT 
    @SystemName, 
    un.UserId, 
    un.UserName,
    u.Password, 
    un.FullName,
    ri.RoomName, 
    ri.Sponsor, 
    ri.ProtocolNumber, 
    --ri.RoomId AS [Room Id], 
    ri.Study,
    r.RoleName
FROM dbo.GetUserNames() un
CROSS JOIN #RoomsInfo ri
CROSS APPLY dbo.GetUserRolesTable(ri.RoomId, un.UserId) ur
LEFT JOIN [dbo].[Role] r ON r.RoleLevel = ur.RoleLevel
LEFT JOIN [User] u ON un.UserId = u.UserId
WHERE un.UserTypeId = @RegularUserTypeId
    AND r.RoleLevel > 1
	AND u.UserName NOT LIKE '%@ti.com%'
	AND u.UserName NOT LIKE '%@titest.com%'
	AND u.UserName NOT LIKE '%@test.com%'
	AND u.UserName NOT LIKE '%@demo.com%'
    --AND r.RoleName = 'No Access'
	--AND un.UserId = 28694
ORDER BY un.UserId, ri.RoomName

SELECT DISTINCT
    --SystemName AS [System Name],
  --  (SELECT AVG(TotalUsers)
  --  FROM
  --  (SELECT SUM(numberOfUsers)
		--	FROM (
		--			SELECT COUNT(UserId) as numberOfUsers FROM #result
		--			)
		--		 AS TotalUsers
		--) AS averageNumberOfUsers),
	--r.UserId,
	--FullName AS [User Full Name],
	r.UserName AS Email,
	u.LastName,
	u.FirstName,
    u.OrganizationName,
    --Password,
    --RoomName AS [Room Name],
    --Sponsor,
    --ProtocolNumber AS [Protocol Number],
    --Study AS [Study #],
   -- STUFF((SELECT  '; ' + tmp2.RoomName  AS [text()]
			--FROM #result tmp2
			--WHERE tmp2.UserName = r.UserName --AND tmp2.RoleName = r.RoleName
			--ORDER BY tmp2.RoomName
			--FOR XML PATH('')),1,1,'') AS AllRooms,
	RoleName AS [Access Level],
	u.City,
	u.State,
	u.Country
	--u.CreatedDate AS [Invited On],
	--u.LastUpdated
	--,DATEDIFF(MM,u.CreatedDate,GETDATE()) AS [Months Active]
FROM #result r
INNER JOIN [User] u (NOLOCK)
	ON r.UserName = u.UserName
--WHERE u.Country = 'US'
--u.OrganizationName NOT IN ('Trial Interactive, Inc.',
--'TransPerfect Trial Interactive',
--'ti.com',
--'transperfect.com',
--'TransPerfect',
--'Trial Interactive',
--'TransPerfect Trialinteractive',
--'elilink',
--'s.com',
--'titest.com',
--'transperect.com',
--'_obsolete'
--) --AND
--r.Username NOT LIKE '%@syneoshealth.com%'
--AND r.Username NOT LIKE '%@incresearch.com%'
--RoleName = 'Administrator'
--GROUP BY RoomName, RoleName
ORDER BY r.UserName

DROP TABLE #result
DROP TABLE #RoomsInfo


DECLARE @DomainId INT = 1
DECLARE @SystemName NVARCHAR(200) = N'Deal Interactive'

------------------------------------------------------------

DECLARE @SystemSiteId INT
SELECT @SystemSiteId = s.SiteId
FROM dbo.Site s
WHERE s.DomainId = @DomainId 
    AND s.SiteTypeId = 2 -- system site type

--CREATE TABLE #RoomsInfo ( 
--    RoomId INT PRIMARY KEY, 
--    RoomName NVARCHAR(100), 
--    Sponsor NVARCHAR(2000), 
--    ProtocolNumber NVARCHAR(2000),
--    Study NVARCHAR(2000)
--)

DECLARE @SiteTopicTypeId INT
SELECT @SiteTopicTypeId = tt.TopicTypeId
FROM TopicType tt
WHERE tt.TypeName = N'Site'
DECLARE @SiteCategoryTopicTypeId INT

DECLARE @InvTopicTypeId INT = (SELECT TopicTypeId FROM TopicType WHERE TypeName = 'InvestigativeSiteInDataRoom')
DECLARE @ProtocolNumberLbl NVARCHAR(150) = dbo.GetLabelNameForTopicAttributes(@SystemSiteId, @SiteTopicTypeId, N'ProtocolNumber')
DECLARE @SponsorIdLbl NVARCHAR(150) = dbo.GetLabelNameForTopicAttributes(@SystemSiteId, @SiteTopicTypeId, N'SponsorId')
DECLARE @StudyLbl NVARCHAR(150) = dbo.GetLabelNameForTopicAttributes(@SystemSiteId, @SiteTopicTypeId, N'Study')

SELECT @SiteTopicTypeId = TopicTypeId FROM TopicType WHERE TypeName = N'Site'
SELECT @SiteCategoryTopicTypeId = tt.TopicTypeId FROM dbo.TopicType tt WHERE tt.TypeName = N'SiteCategory'

CREATE TABLE #SiteInfo (SiteId INT, SiteName VARCHAR(255), SiteIndexPath VARCHAR(255), StatusId INT, IsRoomEnabledforMyTI VARCHAR(10), SponsorName VARCHAR(255), CompanyCode VARCHAR(100))

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

INSERT INTO #SiteInfo (SiteId, SiteName, SiteIndexPath, StatusId, IsRoomEnabledforMyTI, SponsorName, CompanyCode)
SELECT s.SiteId, s.SiteName, ISNULL(sf.IndexPath, N'Root (no folder specified)') AS IndexPath, s.StatusId
, tf.fieldvalue, sponsor.TopicName, tfCompamyCode.fieldValue
--, CASE WHEN tf.Fieldvalue = '' THEN s.LastUpdated ELSE tf.Fieldvalue END
FROM dbo.Site s (NOLOCK)
INNER JOIN dbo.Topic st (NOLOCK) ON st.TopicTypeId = @SiteTopicTypeId
    AND st.TopicName = s.SiteName 
LEFT JOIN dbo.TopicFields tf (NOLOCK) ON
st.TopicId = tf.TopicId AND tf.FieldName = '$MobileAccessEnabled$'
LEFT JOIN dbo.TopicFields tfSponsor (NOLOCK) ON
	st.TopicId = tfSponsor.TopicId AND tfSponsor.fieldname = 'SponsorId'
LEFT JOIN Topic sponsor (NOLOCK) ON
	tfSponsor.fieldvalue = sponsor.TopicId
LEFT JOIN TopicFields tfCompamyCode (NOLOCK) ON
	sponsor.TopicId = tfCompamyCode.TopicId AND tfCompamyCode.fieldName = '$MobileAccessCompanyCode$'	
--AND FieldName = 'DeactivationDate'
LEFT JOIN SiteFolders sf ON sf.FolderId = st.ParentId
INNER JOIN Site sc (NOLOCK)
	ON tf.Fieldvalue = sc.SiteId
WHERE  s.SiteTypeId = 1
    AND s.StatusId = 1
	AND tf.Fieldvalue = '1'
	--AND s.SiteId = 221
	AND IndexPath LIKE '%Premier%' OR IndexPath LIKE '%Extended%'
	AND IndexPath Not Like '%Test%'
ORDER BY s.SiteName,s.Createddate,IndexPath

SELECT * FROM #SiteInfo

SELECT roomname.SiteId, RoomName.SiteName, COUNT(InvSiteTopic.TopicId) as [Total # of Sites]
FROM Topic InvSiteTopic (nolock)
INNER JOIN #SiteInfo RoomName (nolock)
	ON InvSiteTopic.SiteId = RoomName.SiteId
INNER JOIN Topic siteTopic (nolock) 
	ON RoomName.SiteName = siteTopic.TopicName and siteTopic.TopicTypeId = @SiteTopicTypeId
INNER JOIN Topic siteFolder (nolock)
	ON siteTopic.ParentId = siteFolder.TopicId
LEFT JOIN TopicFields tf (nolock)
	ON tf.TopicId = InvSiteTopic.TopicId AND tf.Fieldvalue = 'StatusId'
WHERE RoomName.StatusId = 1 AND 
InvSiteTopic.TopicTypeId = @InvTopicTypeId 

GROUP BY roomname.SiteId, RoomName.SiteName

DROP TABLE #SiteInfo
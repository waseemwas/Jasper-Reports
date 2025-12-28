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

DECLARE @ProtocolNumberLbl NVARCHAR(150) = dbo.GetLabelNameForTopicAttributes(@SystemSiteId, @SiteTopicTypeId, N'ProtocolNumber')
DECLARE @SponsorIdLbl NVARCHAR(150) = dbo.GetLabelNameForTopicAttributes(@SystemSiteId, @SiteTopicTypeId, N'SponsorId')
DECLARE @StudyLbl NVARCHAR(150) = dbo.GetLabelNameForTopicAttributes(@SystemSiteId, @SiteTopicTypeId, N'Study')

--DECLARE @Query NVARCHAR(4000) = N'
--    INSERT INTO #RoomsInfo ( RoomId, RoomName )
--    SELECT s.SiteId, s.SiteName
--    FROM dbo.Site s
--    INNER JOIN dbo.Topic st ON st.SiteId = @SystemSiteId
--        AND st.TopicTypeId = @SiteTopicTypeId
--        AND s.SiteName = st.TopicName
--    --INNER JOIN dbo.' + dbo.GetTopicAttributesTableName(@SystemSiteId) + N' ta ON st.TopicId = ta.TopicId
--    --LEFT JOIN dbo.Topic sp ON ta.' + @SponsorIdLbl + N' = sp.TopicId
--    WHERE s.StatusId = 1 -- Active
--        AND s.SiteTypeId = 1 -- Regular Rooms
--        --AND st.ParentId = 245131
--        AND s.DomainId = @DomainId
--		--AND s.SiteId = 1603
--'

SELECT @SiteTopicTypeId = TopicTypeId FROM TopicType WHERE TypeName = N'Site'
SELECT @SiteCategoryTopicTypeId = tt.TopicTypeId FROM dbo.TopicType tt WHERE tt.TypeName = N'SiteCategory'

CREATE TABLE #SiteInfo (SiteId INT, SiteName VARCHAR(255), SiteIndexPath VARCHAR(255), IsRoomEnabledforMyTI VARCHAR(10), SponsorName VARCHAR(255), CompanyCode VARCHAR(100))

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

INSERT INTO #SiteInfo (SiteId, SiteName, SiteIndexPath, IsRoomEnabledforMyTI, SponsorName, CompanyCode)
SELECT s.SiteId, s.SiteName, ISNULL(sf.IndexPath, N'Root (no folder specified)') AS IndexPath
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
	AND (IndexPath LIKE '%Premier%' OR IndexPath LIKE '%Extended%')
ORDER BY s.SiteName,s.Createddate,IndexPath

SELECT * FROM #SiteInfo

SELECT doc.SiteId, si.SiteName
, CASE WHEN Fieldvalue = '1' THEN 'myTI for iOS' WHEN Fieldvalue = '2'THEN 'myTI for Android' END AS UploadSource
, COUNT(doc.TopicId)
, MAX(TotalDocCount)
FROM Topic doc (NOLOCK)
INNER JOIN #SiteInfo si
	ON si.SiteId = doc.SiteId
INNER JOIN TopicFields tfDoc (NOLOCK)
	ON doc.TopicId = tfDoc.TopicId AND tfDoc.FieldName = '$UploadSource$'
INNER JOIN
	(
		SELECT SiteId, COUNT(TopicId) AS TotalDocCount
		FROM Topic
		WHERE TopicTypeId = 5
		GROUP BY SiteId
	) tdc ON tdc.SiteId = si.SiteId
WHERE Fieldvalue <> '0'
GROUP BY doc.SiteId, si.SiteName
, CASE WHEN Fieldvalue = '1' THEN 'myTI for iOS' WHEN Fieldvalue = '2'THEN 'myTI for Android' END

DROP TABLE #SiteInfo
Declare @SId INT
    Declare @SName Nvarchar(400)
    DECLARE @SiteTopicTypeId INT
    DECLARE @SiteCategoryTopicTypeId INT
	DECLARE @DocumentTopicTypeId INT

    SELECT @SiteTopicTypeId = TopicTypeId FROM TopicType WHERE TypeName = N'Site'
    SELECT @SiteCategoryTopicTypeId = tt.TopicTypeId FROM dbo.TopicType tt WHERE tt.TypeName = N'SiteCategory'
	SELECT @DocumentTopicTypeId = TopicTypeId FROM TopicType WHERE TypeName = N'Document'

    CREATE TABLE #RoomInfo (RoomId INT, RoomName VARCHAR(255), SiteIndexPath VARCHAR(255), SiteCreatedDate DATE, ClientName VARCHAR(255), StudySponsor VARCHAR(255), StatusId INT)

    ;WITH SiteFolders(FolderId, ParentFolderId, IndexPath) AS
    (
    SELECT sf.TopicId, sf.ParentId, CAST(sf.TopicName AS NVARCHAR(MAX)) AS IndexPath
    FROM Topic sf
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

    INSERT INTO #RoomInfo (RoomId,RoomName,SiteIndexPath,SiteCreatedDate,ClientName,StudySponsor,StatusId)
    SELECT s.SiteId, s.SiteName, ISNULL(sf.IndexPath, N'Root (no folder specified)') AS IndexPath, s.CreatedDate,
 stf.Fieldvalue, stfc.Fieldvalue, s.StatusId
    FROM dbo.Site s
    INNER JOIN dbo.Topic st ON st.TopicTypeId = @SiteTopicTypeId
        AND st.TopicName = s.SiteName
 LEFT JOIN dbo.TopicFields stf ON st.TopicId = stf.TopicId AND stf.FieldName = 'ClientName' 
 LEFT JOIN dbo.TopicFields stfc ON st.TopicId = stfc.TopicId AND stfc.FieldName = '$StudySponsor$'
    LEFT JOIN SiteFolders sf ON sf.FolderId = st.ParentId
   WHERE s.SiteTypeId = 1
        --AND s.StatusId <> 2
		--AND s.SiteId IN (853)
        AND IndexPath LIKE '%Braeburn%'
        AND OBJECT_ID(dbo.GetTopicAttributesTableName(S.SiteId)) IS NOT NULL
    ORDER BY s.SiteName,s.Createddate,IndexPath

--SELECT * FROM #RoomInfo

SELECT ri.RoomId, ri.SiteIndexPath, ri.RoomName
--, MAX(ri.SiteCreatedDate) AS [Room Created Date]
, CASE WHEN ri.StatusId = 1 THEN 'Active' WHEN ri.StatusId = 2 THEN 'Deactivated' END AS RoomStatus
, SUM(CAST(tfl.FileSize AS DECIMAL(38,2))/1024/1024/1024)
--,doc.topicId AS [Document Id], doc.TopicName AS Title
--, tfl.FileSize
--,tfl.FileSize AS FileSize
FROM #RoomInfo ri 
INNER JOIN Topic studyRoom (NOLOCK) ON ri.RoomName = studyRoom.TopicName
--INNER JOIN TopicFields tfRoom (NOLOCK) ON studyRoom.TopicId = tfRoom.TopicId AND tfRoom.FieldName = 'DeactivationDate'
INNER JOIN Topic doc ON doc.SiteId = ri.RoomId AND doc.TopicTypeId = @DocumentTopicTypeId
INNER JOIN TopicFiles tfl ON tfl.TopicId = doc.TopicId
--LEFT JOIN TopicFields tf (NOLOCK)
--	ON tf.TopicId = doc.TopicId AND tf.FieldName = 'DocumentName'
--WHERE
--docStatusId.TopicName = 'Final' --AND invSites.TopicTypeId = 47
--AND ri.SiteCreatedDate >= '3/1/2019'
--and doctfUser.UserName is not null
--and doctfIntegration.Fieldvalue = 1
--(doc.CreatedBy IN (15967)
--AND doc.CreatedDate > '1/31/2019'
--AND doctf.Fieldvalue = 1)
--OR (doc.CreatedBy = 5522 AND doc.CreatedDate > '1/31/2019')
GROUP BY ri.RoomId, ri.SiteIndexPath, ri.RoomName, ri.StatusId
ORDER BY ri.SiteIndexPath, ri.RoomId
DROP TABLE #RoomInfo
--Declare @SId INT
    Declare @SName Nvarchar(400)
    DECLARE @SiteTopicTypeId INT
    DECLARE @SiteCategoryTopicTypeId INT
	DECLARE @DocumentTopicTypeId INT
	DECLARE @TotalTopicCount INT
	DECLARE @DBSize FLOAT = 710.72

    SELECT @SiteTopicTypeId = TopicTypeId FROM TopicType WHERE TypeName = N'Site'
    SELECT @SiteCategoryTopicTypeId = tt.TopicTypeId FROM dbo.TopicType tt WHERE tt.TypeName = N'SiteCategory'
	SELECT @DocumentTopicTypeId = TopicTypeId FROM TopicType WHERE TypeName = N'Document'
	SELECT @TotalTopicCount = COUNT(TopicId) FROM Topic

    CREATE TABLE #RoomInfo (RoomId INT, RoomName VARCHAR(255), SiteIndexPath VARCHAR(255), SiteCreatedDate DATE, SiteUpdatedDate DATE, ClientName VARCHAR(255), StudySponsor VARCHAR(255), StatusId INT)

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

    INSERT INTO #RoomInfo (RoomId,RoomName,SiteIndexPath,SiteCreatedDate,SiteUpdatedDate,ClientName,StudySponsor,StatusId)
    SELECT s.SiteId, s.SiteName, ISNULL(sf.IndexPath, N'Root (no folder specified)') AS IndexPath, s.CreatedDate, s.LastUpdated,
 stf.Fieldvalue, stfc.Fieldvalue, s.StatusId
    FROM dbo.Site s
    INNER JOIN dbo.Topic st ON st.TopicTypeId = @SiteTopicTypeId
        AND st.TopicName = s.SiteName
 LEFT JOIN dbo.TopicFields stf ON st.TopicId = stf.TopicId AND stf.FieldName = 'ClientName' 
 LEFT JOIN dbo.TopicFields stfc ON st.TopicId = stfc.TopicId AND stfc.FieldName = '$StudySponsor$'
    LEFT JOIN SiteFolders sf ON sf.FolderId = st.ParentId
   WHERE s.SiteTypeId = 1
        AND s.StatusId = 1
		AND IndexPath LIKE '%Premier%'
		--AND (s.SiteId IN (759)
  --      OR (IndexPath LIKE '%Braeburn%'))
        AND OBJECT_ID(dbo.GetTopicAttributesTableName(S.SiteId)) IS NOT NULL
    --ORDER BY s.Createddate,s.SiteName,IndexPath

--SELECT * FROM #RoomInfo

SELECT @TotalTopicCount

SELECT ri.RoomId, ri.RoomName, ri.SiteCreatedDate, ri.SiteUpdatedDate
, SUM(CAST(tfl.FileSize AS DECIMAL(38,2))/1024/1024/1024) AS [File Size (GB) in FileShare (Primary)]
, SUM(CAST(tfl.FileSize AS DECIMAL(38,2))/1024/1024/1024) AS [File Size (GB) in FileShare (Secondary)]
, ((SUM(CAST(tfl.FileSize AS DECIMAL(38,2))/1024/1024/1024) + SUM(CAST(tfl.FileSize AS DECIMAL(38,2))/1024/1024/1024))*25) / 100
--, convert(nvarchar(50),SUM(tfl.FileSize)/ (1024) / (1024) / (1024)) +' GB' AS FileSize
FROM #RoomInfo ri 
INNER JOIN Topic doc ON doc.SiteId = ri.RoomId --AND doc.TopicTypeId = @DocumentTopicTypeId
INNER JOIN TopicFiles tfl ON tfl.TopicId = doc.TopicId
INNER JOIN
	(
		SELECT SiteId, COUNT(TopicId) AS topicCount FROM Topic (NOLOCK)
		GROUP BY SiteId
	) tc ON tc.SiteId = ri.RoomId
--WHERE
--ri.SiteCreatedDate < '3/1/2019'
--AND doc.CreatedDate < '6/1/2020'
--docStatusId.TopicName = 'Final' --AND invSites.TopicTypeId = 47
--AND ri.SiteCreatedDate >= '3/1/2019'
--and doctfUser.UserName is not null
--and doctfIntegration.Fieldvalue = 1
--(doc.CreatedBy IN (15967)
--AND doc.CreatedDate > '1/31/2019'
--AND doctf.Fieldvalue = 1)
--OR (doc.CreatedBy = 5522 AND doc.CreatedDate > '1/31/2019')
GROUP BY ri.RoomId, ri.SiteIndexPath, ri.SiteCreatedDate,ri.SiteUpdatedDate, ri.RoomName, ri.StatusId, tc.topicCount
ORDER BY ri.SiteIndexPath, ri.RoomId

DROP TABLE #RoomInfo

--select COUNT(*) FROM Topic
--where siteid = 214 and topictypeid = 5
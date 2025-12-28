SELECT * FROM Topic t (nolock)
inner join FolderIndexPrefix f
	ON f.FolderId = t.ParentId
WHERE t.SiteId = 44 AND TopicTypeId = 4

SELECT * FROM TopicFields
WHERE topicid = 9749

SELECT * FROM TopicFiles
WHERE topicid = 9749

SELECT * FROM SiteFieldMap
WHERE SIteid = 44 and topictypeid = 4

select intFld21 FROM topicattributes044 ta
INNER JOIN Sitefieldmap s ON 
AND s.topictypeid = 4
where ta.siteid = 44

select * from EmailQueueArchive
where statusid= 2

select * from emailqueuepatterns
where emailqueueid = 169

select * from Template
where Id = 252

select * from topic
where topicid = 9609

SELECT * FROM Site (nolock)

select * from FileProcessingQueue
where siteid = 44 and 

select * from HistoryNote
where Siteid = 44 and field = 'CodingTypeId'

select * from [User]


select * from FileProcessingType
where siteid = 44

SELECT * FROM TopicType (nolock)

select * from servertaskqueue

SELECT s.SiteName AS RoomName, 
    s.CreatedDate AS RoomCreatedDate ,
    CASE s.StatusId
    WHEN 1 THEN 'Published'
    WHEN 2 THEN 'Unpublished'
    END RoomStatus,
    p.TopicName AS InstitutionName,
    iss.InvestigativeSiteStatusName,
 tf1.Fieldvalue AS SiteNumber,
    t.CreatedDate AS InvSiteCreatedDate
FROM [Site] s
INNER JOIN dbo.Topic t ON t.SiteId = s.SiteId
INNER JOIN dbo.TopicType tt ON tt.TopicTypeId = t.TopicTypeId AND tt.TypeName = 'InvestigativeSiteInDataRoom'
INNER JOIN Topic p ON p.TopicId = t.ParentId
LEFT JOIN TopicFields tf ON tf.TopicId = t.TopicId AND tf.FieldName LIKE 'StatusId' AND tf.SiteId = t.SiteId
LEFT JOIN dbo.InvestigativeSiteStatus iss ON iss.InvestigativeSiteStatusId = tf.Fieldvalue
LEFT JOIN TopicFields tf1 ON tf1.TopicId = t.TopicId AND tf1.fieldName = 'SiteNumber' AND TF1.SiteId = T.SiteId
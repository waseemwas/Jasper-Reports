--NO TRANSACTION
SET NOCOUNT ON

CREATE TABLE #Site(SiteId INT PRIMARY KEY)

INSERT INTO #Site
(
    SiteId
)
SELECT rm.SiteId 
FROM [dbo].[GetSiteSettingValues]
(
	null,
	'Reports',
	'Reports.ReportsSystem',
	0
) rm 
WHERE rm.SettingValue <> 'Jasper'

DECLARE @SiteSettingsTopicTypeId INT = (SELECT TopicTypeId FROM dbo.TopicType WHERE typename = 'SiteSettings')
DECLARE @SiteId INT
DECLARE @UserId INT 
DECLARE @ErrorCode INT
DECLARE @RaiseErrorMsg NVARCHAR(MAX)
DECLARE @SiteSettingsTopicId INT  
DECLARE @UpdateSiteMap BIT 

CREATE TABLE #EditTopicFields_TopicFields(TopicId INT, FieldId Int, FieldName NVARCHAR(50), Fieldvalue NVARCHAR(Max), FieldType INT, SortOrder INT IDENTITY(1,1), UpdateType INT DEFAULT 1, StringToReplace NVARCHAR(MAX), Delimiter NVARCHAR(50), UpdateReason NVARCHAR(MAX), PRIMARY KEY (TopicId, FieldName))
CREATE TABLE #Error_Records(ObjectId INT, ObjectName NVARCHAR(2000), ObjectType NCHAR(1) DEFAULT (N'T'), ObjectTypeId INT, ErrorCode INT) 

DECLARE SiteCursor CURSOR LOCAL STATIC FOR
SELECT DISTINCT s.SiteId, dsi.DomainSystemUserId
FROM [dbo].[Site] s
INNER JOIN dbo.GetDomainSystemInfo() dsi ON dsi.DomainId = S.DomainId 
    AND dsi.DomainSystemUserId IS NOT NULL
WHERE EXISTS (SELECT * FROM #Site tmp WHERE tmp.SiteId = s.SiteId)
 AND s.StatusId = 1
ORDER BY s.SiteId 

OPEN SiteCursor
FETCH NEXT FROM SiteCursor INTO @SiteId, @UserId
WHILE (@@FETCH_STATUS = 0)
BEGIN
    TRUNCATE TABLE #EditTopicFields_TopicFields


    DECLARE @SettingTopicId INT = (SELECT t.TopicId FROM dbo.Topic t WHERE t.SiteId = @SiteId AND t.TopicTypeId = @SiteSettingsTopicTypeId AND t.TopicName = 'Reports')
                  
    INSERT INTO #EditTopicFields_TopicFields(TopicId, FieldType, FieldName, Fieldvalue)
    VALUES 
        (@SettingTopicId, 1, 'Reports.ReportsSystem', 'Jasper')             
                    
    SET @ErrorCode = 0
    SET @UpdateSiteMap = 0       
    EXEC dbo.SaveTopicFields
        @SiteId = @SiteId, -- int
        @UserId = @UserId, -- int
        @UpdateSiteMap = @UpdateSiteMap, -- bit
        @TopicFieldsInfo = NULL, -- xml
        @SkipSecurity = 1, -- bit
        @SkipTopicsArchive = 1, -- bit
        @OutputTmpTableName = '#Error_Records', -- nvarchar(150)
        @ErrorCode = @ErrorCode OUT  -- int

    PRINT @SiteId                        
    FETCH NEXT FROM SiteCursor INTO @SiteId, @UserId
END
GO 

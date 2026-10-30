CREATE PROC [dbo].[spAPI_FP_Youtube_PlayList_Get]
	@Access_Token NVARCHAR(max)
AS
BEGIN
    DECLARE @ChannelId VARCHAR(200) = 'UCap1uhPh75C525pcOvV375A';
    DECLARE @METHOD VARCHAR(10) = 'GET';
    DECLARE @URL NVARCHAR(1000) = N'https://www.googleapis.com/youtube/v3/playlists?part=snippet&channelId=' + @ChannelId + N'&maxResults=50';
    DECLARE @HEADER NVARCHAR(MAX) = CONCAT('Authorization: Bearer ', @Access_Token);
    DECLARE @BODY NVARCHAR(MAX) = N'}';
    --Bước 1 – Khởi tạo upload (initiate session)
    DECLARE @Response NVARCHAR(MAX) = dbo.httpAPI(@METHOD, @URL, @HEADER, @BODY);


    SELECT JSON_VALUE(Value, '$.id')                          AS PlaylistID
         , JSON_VALUE(Value, '$.snippet.title')               AS Title
         , JSON_VALUE(Value, '$.snippet.description')         AS Description
         , JSON_VALUE(Value, '$.snippet.publishedAt')         AS PublishedAt
         , JSON_VALUE(Value, '$.snippet.channelId')           AS ChannelID
         , JSON_VALUE(Value, '$.snippet.channelTitle')        AS ChannelTitle
         , JSON_VALUE(Value, '$.snippet.thumbnails.high.url') AS ThumbnailUrl
    FROM
           OPENJSON(@Response, '$.items');
END;
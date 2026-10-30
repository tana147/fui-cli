CREATE PROC [dbo].[spAPI_FP_Youtube_Get_List]
AS
BEGIN

    DECLARE @Access_Token NVARCHAR(MAX) = N'';
    SELECT @Access_Token = access_token
    FROM
           dbo.fn_tblGetAccessToken_OAuth_Youtube();

    DECLARE @METHOD VARCHAR(10) = 'GET';
    DECLARE @URL NVARCHAR(200) = N'https://www.googleapis.com/youtube/v3/search?part=snippet&forMine=true&type=video&maxResults=10&order=date';
    DECLARE @HEADER NVARCHAR(MAX) = CONCAT('|', 'Authorization: Bearer ' + @Access_Token);

    DECLARE @Response NVARCHAR(MAX) = dbo.httpAPI(@METHOD, @URL, @HEADER, '');
    SELECT VideoId      = JSON_VALUE(item.Value, '$.id.videoId')
         , Title        = JSON_VALUE(item.Value, '$.snippet.title')
         , ChannelTitle = JSON_VALUE(item.Value, '$.snippet.channelTitle')
         , PublishedAt  = JSON_VALUE(item.Value, '$.snippet.publishedAt')
         , ThumbnailUrl = JSON_VALUE(item.Value, '$.snippet.thumbnails.default.url')
    FROM
           OPENJSON(@Response, '$.items') AS item;
END;
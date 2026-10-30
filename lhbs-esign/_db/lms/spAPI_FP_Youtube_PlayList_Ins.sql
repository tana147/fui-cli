CREATE PROC [dbo].[spAPI_FP_Youtube_PlayList_Ins]
    @TenPlayList  NVARCHAR(200)
  , @Access_Token NVARCHAR(MAX)
AS
BEGIN
    DECLARE @METHOD VARCHAR(10) = 'POST';
    DECLARE @URL NVARCHAR(1000) = N'https://www.googleapis.com/youtube/v3/playlists?part=snippet,status';
    DECLARE @HEADER NVARCHAR(MAX) = CONCAT('Authorization: Bearer ', @Access_Token);
    DECLARE @BODY NVARCHAR(MAX) = N'{
	  "snippet": {
		"title": "' + @TenPlayList + N'",
		"description": ""
	  },
	  "status": {
		"privacyStatus": "private"
	  }
	}';
    --Bước 1 – Khởi tạo upload (initiate session)
    DECLARE @Response NVARCHAR(MAX) = dbo.httpAPI(@METHOD, @URL, @HEADER, @BODY);
    SELECT JSON_VALUE(@Response, '$.id')                          AS PlaylistID
         , JSON_VALUE(@Response, '$.snippet.title')               AS Title
         , JSON_VALUE(@Response, '$.snippet.description')         AS Description
         , JSON_VALUE(@Response, '$.snippet.publishedAt')         AS PublishedAt
         , JSON_VALUE(@Response, '$.snippet.channelId')           AS ChannelID
         , JSON_VALUE(@Response, '$.snippet.channelTitle')        AS ChannelTitle
         , JSON_VALUE(@Response, '$.snippet.thumbnails.high.url') AS ThumbnailUrl
         , JSON_VALUE(@Response, '$.status.privacyStatus')        AS PrivacyStatus;
END;
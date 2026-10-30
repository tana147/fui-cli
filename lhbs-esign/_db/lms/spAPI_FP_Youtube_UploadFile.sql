--[dbo].[spAPI_FP_Youtube_UploadFile] N'Tên File','video/*', 3000000
CREATE PROC [dbo].[spAPI_FP_Youtube_UploadFile]
    @TenFile              NVARCHAR(1000)
  , @XUploadContentType   NVARCHAR(200)
  , @XUploadContentLength INT
AS
BEGIN

    DECLARE @Access_Token NVARCHAR(MAX) = N'';
    SELECT @Access_Token = access_token
    FROM
           dbo.fn_tblGetAccessToken_OAuth_Youtube();

    DECLARE @METHOD VARCHAR(10) = 'POST';
    DECLARE @URL NVARCHAR(1000) = N'https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status,contentDetails';
    DECLARE @HEADER NVARCHAR(MAX) = CONCAT('Authorization: Bearer ', @Access_Token, '|', 'x-upload-content-length: ', @XUploadContentLength, '|', 'X-Upload-Content-Type: ', @XUploadContentType);
    DECLARE @BODY NVARCHAR(MAX) = N'{
		"snippet": {
			"title": "Tên video",
			"description": "",
			"tags": [],
			"categoryId": "27"
		},
		"status": {
			"privacyStatus": "private",
			"madeForKids": true
		}
	}';
    --Bước 1 – Khởi tạo upload (initiate session)
    DECLARE @Response NVARCHAR(MAX) = dbo.httpAPI(@METHOD, @URL, @HEADER, @BODY);
    SELECT @Response;
--Bước 2 – Upload file video đến URL vừa nhận


--SELECT VideoId      = JSON_VALUE(item.Value, '$.id.videoId')
--     , Title        = JSON_VALUE(item.Value, '$.snippet.title')
--     , ChannelTitle = JSON_VALUE(item.Value, '$.snippet.channelTitle')
--     , PublishedAt  = JSON_VALUE(item.Value, '$.snippet.publishedAt')
--     , ThumbnailUrl = JSON_VALUE(item.Value, '$.snippet.thumbnails.default.url')
--FROM
--       OPENJSON(@Response, '$.items') AS item;
END;


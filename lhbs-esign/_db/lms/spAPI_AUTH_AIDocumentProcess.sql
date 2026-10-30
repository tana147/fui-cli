CREATE PROCEDURE [dbo].[spAPI_AUTH_AIDocumentProcess]
    @Action NVARCHAR(50),
    @FileName NVARCHAR(255),
    @FileBase64 NVARCHAR(MAX),
    @PromptId NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Action <> N'CONVERT'
    BEGIN
        SELECT N'ERROR' AS [Status], N'UNSUPPORTED_ACTION' AS [ErrorCode],
            N'Action chưa được hỗ trợ.' AS [ErrorMessage], NULL AS [Data];
        RETURN;
    END;

    IF NULLIF(@FileName, N'') IS NULL OR NULLIF(@FileBase64, N'') IS NULL
    BEGIN
        SELECT N'ERROR' AS [Status], N'MISSING_FILE' AS [ErrorCode],
            N'FileName và FileBase64 là bắt buộc.' AS [ErrorMessage], NULL AS [Data];
        RETURN;
    END;

    DECLARE @RequestBody NVARCHAR(MAX) = N'{"fileName":"' + STRING_ESCAPE(@FileName, 'json') +
        N'","fileBase64":"' + @FileBase64 +
        N'","prompt_id":"' + STRING_ESCAPE(ISNULL(@PromptId, N''), 'json') + N'"}';
    DECLARE @RawResponse NVARCHAR(MAX) = dbo.httpAPI(
        'POST',
        'http://103.72.96.35:8000/convert-base64',
        '',
        @RequestBody
    );

    SELECT
        CASE WHEN ISJSON(@RawResponse) = 1 AND ISNULL(TRY_CONVERT(INT, JSON_VALUE(@RawResponse, '$.httpErrorCode')), 200) BETWEEN 200 AND 299
            THEN N'OK' ELSE N'ERROR' END AS [Status],
        COALESCE(JSON_VALUE(@RawResponse, '$.detail'), JSON_VALUE(@RawResponse, '$.responseData.detail[0].msg')) AS [ErrorMessage],
        @RawResponse AS [Data];
END

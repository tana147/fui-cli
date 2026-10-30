
CREATE PROCEDURE [dbo].[spAPI_WF_Execution_SaveDocument]
    @InstanceID  BIGINT,
    @ExecutionID BIGINT,
    @FileID      UNIQUEIDENTIFIER,
    @FileName    NVARCHAR(255) = NULL,
    @FileUrl     NVARCHAR(500) = NULL,
    @sys_UserID  VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM dbo.tblWF_StepExecution
            WHERE ExecutionID = @ExecutionID
              AND InstanceID  = @InstanceID
              AND [Enable]    = 1
        )
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Không tìm thấy execution.' AS Message;
            RETURN;
        END

        DECLARE @ResolvedUrl NVARCHAR(500) = ISNULL(
            NULLIF(LTRIM(RTRIM(@FileUrl)), ''),
            N'https://file.zentea.vn/iotdev/FileData/' + LTRIM(RTRIM(ISNULL(@FileID, '')))
        );

        UPDATE dbo.tblWF_StepExecution
        SET DocumentFileID   = @FileID,
            DocumentFileName = ISNULL(NULLIF(LTRIM(RTRIM(@FileName)), ''), DocumentFileName),
            DocumentFileUrl  = @ResolvedUrl,
            UpdateUser       = @sys_UserID,
            UpdateTime       = GETDATE()
        WHERE ExecutionID = @ExecutionID
          AND InstanceID  = @InstanceID
          AND [Enable]    = 1;

        SELECT CAST(1 AS BIT) AS Success, N'Đã lưu file signed.' AS Message,
               @FileID AS FileID, @ResolvedUrl AS FileUrl;
    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END


CREATE PROCEDURE dbo.spAPI_LMS_SyncDiemLog_Complete
    @RequestID UNIQUEIDENTIFIER,
    @SyncStatus VARCHAR(20),
    @ResponsePayload NVARCHAR(MAX),
    @ResponseRowsJson NVARCHAR(MAX),
    @ErrorMessage NVARCHAR(4000),
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF @RequestID IS NULL
    BEGIN
        RAISERROR('RequestID la bat buoc.', 16, 1);
        RETURN;
    END;

    IF @SyncStatus NOT IN ('Succeeded', 'Failed', 'InvalidResponse')
    BEGIN
        RAISERROR('SyncStatus khong hop le.', 16, 1);
        RETURN;
    END;

    IF @SyncStatus = 'Succeeded'
       AND (ISNULL(ISJSON(@ResponseRowsJson), 0) <> 1
            OR LEFT(LTRIM(ISNULL(@ResponseRowsJson, '')), 1) <> '[')
    BEGIN
        RAISERROR('ResponseRowsJson phai la mang JSON khi SyncStatus la Succeeded.', 16, 1);
        RETURN;
    END;

    DECLARE @SyncDiemLogID BIGINT;
    SELECT @SyncDiemLogID = header.SyncDiemLogID
    FROM dbo.tbl_LOG_LMS_SyncDiem AS header
    WHERE header.RequestID = @RequestID
      AND header.RequestedBy = @SYS_USERID;

    IF @SyncDiemLogID IS NULL
    BEGIN
        RAISERROR('Khong tim thay log dong bo thuoc nguoi dung hien tai.', 16, 1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.tbl_LOG_LMS_SyncDiem AS header WITH (UPDLOCK, ROWLOCK)
            WHERE header.SyncDiemLogID = @SyncDiemLogID
              AND header.SyncStatus = 'Started'
        )
        BEGIN
            IF ISJSON(@ResponseRowsJson) = 1 AND LEFT(LTRIM(@ResponseRowsJson), 1) = '['
            BEGIN
                ;WITH ParsedResponse AS
                (
                    SELECT
                        TRY_CONVERT(INT, JSON_VALUE(responseRow.value, '$.HocSinhID')) AS HocSinhID,
                        JSON_VALUE(responseRow.value, '$.DTB') AS ResponseDTB,
                        responseRow.value AS ResponseRowJson,
                        ROW_NUMBER() OVER
                        (
                            PARTITION BY TRY_CONVERT(INT, JSON_VALUE(responseRow.value, '$.HocSinhID'))
                            ORDER BY TRY_CONVERT(INT, responseRow.[key])
                        ) AS StudentResultNumber
                    FROM OPENJSON(@ResponseRowsJson) AS responseRow
                )
                UPDATE detail
                SET
                    detail.ResponseDTB = response.ResponseDTB,
                    detail.ResponseRowJson = response.ResponseRowJson
                FROM dbo.tbl_LOG_LMS_SyncDiem_Detail AS detail
                INNER JOIN ParsedResponse AS response
                    ON response.HocSinhID = detail.HocSinhID
                   AND response.StudentResultNumber = 1
                WHERE detail.SyncDiemLogID = @SyncDiemLogID;
            END;

            UPDATE dbo.tbl_LOG_LMS_SyncDiem
            SET
                SyncStatus = @SyncStatus,
                ResponsePayload = @ResponsePayload,
                ResponseRowsJson = @ResponseRowsJson,
                ErrorMessage = @ErrorMessage,
                ResponseStudentCount = CASE
                    WHEN ISJSON(@ResponseRowsJson) = 1 AND LEFT(LTRIM(@ResponseRowsJson), 1) = '['
                        THEN (SELECT COUNT(*) FROM OPENJSON(@ResponseRowsJson))
                    ELSE NULL
                END,
                CompletedAt = SYSDATETIMEOFFSET()
            WHERE SyncDiemLogID = @SyncDiemLogID
              AND SyncStatus = 'Started';
        END;

        COMMIT TRANSACTION;

        SELECT
            header.SyncDiemLogID,
            header.RequestID,
            header.SyncStatus,
            header.RequestedBy,
            header.RequestedAt,
            header.CompletedAt,
            header.StudentCount,
            header.ResponseStudentCount
        FROM dbo.tbl_LOG_LMS_SyncDiem AS header
        WHERE header.SyncDiemLogID = @SyncDiemLogID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @CatchErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@CatchErrorMessage, 16, 1);
    END CATCH;
END;
CREATE PROCEDURE [dbo].[spAPI_WF_InstanceSignBox_UpdatePositions]
    @InstanceID     BIGINT,
    @SignBoxesJSON  NVARCHAR(MAX),
    @sys_UserID     VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Validate InstanceID
        IF NOT EXISTS (
            SELECT 1 FROM dbo.tblWF_Instance
            WHERE InstanceID = @InstanceID AND [Enable] = 1
        )
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Không tìm thấy instance.' AS Message;
            RETURN;
        END

        -- Parse JSON và update từng signBox theo InstanceSignBoxID
        -- JSON format: [{ "InstanceSignBoxID": 1, "PageNo": 1, "PosX": 100.5, "PosY": 200.3, "BoxWidth": 150.0, "BoxHeight": 60.0 }, ...]
        IF ISNULL(LTRIM(RTRIM(@SignBoxesJSON)), '') = '' OR @SignBoxesJSON = '[]'
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'SignBoxesJSON rỗng.' AS Message;
            RETURN;
        END

        DECLARE @UpdateCount INT = 0;

        -- Ràng buộc 1: Nếu đã có bất kỳ chữ ký nào được ký trong luồng -> Khóa không cho cập nhật tọa độ
        IF EXISTS (
            SELECT 1 
            FROM dbo.tblWF_StepSignerExec AS SE
            INNER JOIN dbo.tblWF_StepExecution AS EX ON EX.ExecutionID = SE.ExecutionID
            WHERE EX.InstanceID = @InstanceID
              AND EX.[Enable] = 1
              AND SE.Status = 'SIGNED'
              AND SE.[Enable] = 1
        )
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Hồ sơ đã có chữ ký, không thể thay đổi vị trí ô ký.' AS Message, 0 AS UpdatedCount;
            RETURN;
        END

        -- Ràng buộc 2: Update bảng tblWF_InstanceSignBox nhưng loại trừ các ô ký đã được gán tọa độ trước đó ở các bước khác bước nhập
        UPDATE B
        SET
            B.PageNo    = ISNULL(TRY_CAST(J.[PageNo]    AS INT),     B.PageNo),
            B.PosX      = ISNULL(TRY_CAST(J.[PosX]      AS FLOAT),   B.PosX),
            B.PosY      = ISNULL(TRY_CAST(J.[PosY]      AS FLOAT),   B.PosY),
            B.BoxWidth  = ISNULL(TRY_CAST(J.[BoxWidth]  AS FLOAT),   B.BoxWidth),
            B.BoxHeight = ISNULL(TRY_CAST(J.[BoxHeight] AS FLOAT),   B.BoxHeight),
            B.UpdateUser = @sys_UserID,
            B.UpdateTime = GETDATE()
        FROM dbo.tblWF_InstanceSignBox AS B
        INNER JOIN OPENJSON(@SignBoxesJSON) WITH (
            InstanceSignBoxID BIGINT  '$.InstanceSignBoxID',
            PageNo            INT     '$.PageNo',
            PosX              FLOAT   '$.PosX',
            PosY              FLOAT   '$.PosY',
            BoxWidth          FLOAT   '$.BoxWidth',
            BoxHeight         FLOAT   '$.BoxHeight'
        ) AS J ON J.InstanceSignBoxID = B.InstanceSignBoxID
        INNER JOIN dbo.tblWF_Instance AS I ON I.InstanceID = B.InstanceID
        LEFT JOIN dbo.tblWF_StepDefinition AS SD
            ON SD.DefinitionID = I.DefinitionID
           AND SD.StepOrder = B.StepOrder
           AND SD.[Enable] = 1
        WHERE B.InstanceID = @InstanceID
          AND B.[Enable] = 1
          -- Chỉ cho phép cập nhật nếu chưa được gán tọa độ thực tế (B.UpdateTime IS NULL) đối với bước khác bước nhập (INPUT_ONLY)
          AND NOT (ISNULL(SD.StepType, '') <> 'INPUT_ONLY' AND B.UpdateTime IS NOT NULL);

        SET @UpdateCount = @@ROWCOUNT;

        SELECT
            CAST(1 AS BIT) AS Success,
            N'Đã cập nhật vị trí ' + CAST(@UpdateCount AS NVARCHAR(10)) + N' signBox.' AS Message,
            @UpdateCount AS UpdatedCount;

    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message, 0 AS UpdatedCount;
    END CATCH
END


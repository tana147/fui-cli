CREATE PROCEDURE [dbo].[spAPI_WF_StepChecklistDef_Save]
    @StepDefID BIGINT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Tự động nhận diện cấu trúc của @sys_RawData để trích xuất mảng JSON chính xác
    DECLARE @JsonData NVARCHAR(MAX) = @sys_RawData;

    -- Trường hợp 1: Nếu @sys_RawData là object chứa key "sys_RawData" (do API gateway đóng gói tự động)
    IF ISJSON(@sys_RawData) = 1 AND JSON_VALUE(@sys_RawData, '$.sys_RawData') IS NOT NULL
    BEGIN
        DECLARE @InnerRawData NVARCHAR(MAX) = JSON_VALUE(@sys_RawData, '$.sys_RawData');
        -- Kiểm tra xem chuỗi bên trong có phải là JSON hợp lệ không
        IF ISJSON(@InnerRawData) = 1
        BEGIN
            SET @JsonData = @InnerRawData;
        END
        ELSE
        BEGIN
            SET @JsonData = JSON_QUERY(@sys_RawData, '$.sys_RawData');
        END
    END
    -- Trường hợp 2: Nếu @sys_RawData là object chứa key "Items"
    ELSE IF ISJSON(@sys_RawData) = 1 AND JSON_QUERY(@sys_RawData, '$.Items') IS NOT NULL
    BEGIN
        SET @JsonData = JSON_QUERY(@sys_RawData, '$.Items');
    END

    -- Thao tác đồng bộ: xóa các định nghĩa cũ không nằm trong JSON, chèn/cập nhật các định nghĩa mới
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Đánh dấu Enable = 0 cho các định nghĩa cũ không có trong danh sách mới gửi lên
        UPDATE dbo.tblWF_StepChecklistDef
        SET [Enable] = 0,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE StepDefID = @StepDefID AND [Enable] = 1
          AND ChecklistDefID NOT IN (
              SELECT ISNULL(JSON_VALUE(value, '$.ChecklistDefID'), 0)
              FROM OPENJSON(@JsonData)
          );

        -- Thêm mới hoặc Cập nhật các định nghĩa
        -- Sử dụng ISNULL(..., '') cho ItemCode để tránh lỗi NOT NULL Constraint trong Database
        MERGE dbo.tblWF_StepChecklistDef AS target
        USING (
            SELECT 
                ISNULL(JSON_VALUE(value, '$.ChecklistDefID'), 0) AS ChecklistDefID,
                @StepDefID AS StepDefID,
                ISNULL(JSON_VALUE(value, '$.ItemCode'), '') AS ItemCode,
                JSON_VALUE(value, '$.ItemName') AS ItemName,
                JSON_VALUE(value, '$.Description') AS [Description],
                ISNULL(CAST(JSON_VALUE(value, '$.IsRequired') AS BIT), 1) AS IsRequired,
                ISNULL(JSON_VALUE(value, '$.AllowedMethods'), 'BOTH') AS AllowedMethods,
                ISNULL(CAST(JSON_VALUE(value, '$.AllowDefer') AS BIT), 1) AS AllowDefer
            FROM OPENJSON(@JsonData)
        ) AS source
        ON (target.ChecklistDefID = source.ChecklistDefID AND target.StepDefID = source.StepDefID)
        WHEN MATCHED AND target.[Enable] = 1 THEN
            UPDATE SET 
                ItemCode = source.ItemCode,
                ItemName = source.ItemName,
                [Description] = source.[Description],
                IsRequired = source.IsRequired,
                AllowedMethods = source.AllowedMethods,
                AllowDefer = source.AllowDefer,
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (StepDefID, ItemCode, ItemName, [Description], IsRequired, AllowedMethods, AllowDefer, CreateUser, CreateTime, [Enable])
            VALUES (source.StepDefID, source.ItemCode, source.ItemName, source.[Description], source.IsRequired, source.AllowedMethods, source.AllowDefer, @sys_UserID, GETDATE(), 1);

        COMMIT TRANSACTION;
        SELECT Message = N'Lưu cấu hình checklist thành công.', StepDefID = @StepDefID;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END


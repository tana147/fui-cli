CREATE PROCEDURE dbo.spAPI_HDKH_Rule_Save
    -- Các tham số tường minh, sẽ được t-API map từ payload
    @RuleID INT = 0,
    @FormID INT,
    @RuleDescription NVARCHAR(500),
    @SoGioQuyDoi_Goc DECIMAL(10,2),
    @Formula_TinhGioGoc NVARCHAR(500) = NULL,
    @MaQuyTacPhanChia VARCHAR(50),
    @Apply_AP_Index BIT = 0,
    @NamHocApDung INT,
    
    -- Tham số hệ thống, sẽ được t-API tự động điền
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX) -- Chứa toàn bộ body của request
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra các dữ liệu đầu vào cơ bản
    IF @FormID IS NULL OR @SoGioQuyDoi_Goc IS NULL OR ISNULL(@MaQuyTacPhanChia, '') = '' OR @NamHocApDung IS NULL
    BEGIN
        RAISERROR(N'FormID, Số giờ gốc, Mã quy tắc chia và Năm áp dụng là bắt buộc.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        
        -- Bước 1: Trích xuất chuỗi JSON của mảng 'Conditions' từ @sys_RawData
        -- Payload gửi lên có key là 'json_data', chúng ta dùng JSON_VALUE để lấy giá trị của nó.
        DECLARE @ConditionsJSON NVARCHAR(MAX);
        SELECT @ConditionsJSON = JSON_VALUE(@sys_RawData, '$.json_data');

        -- Bước 2: Thực hiện UPSERT (Thêm mới/Cập nhật) vào bảng Rule_Definition
        MERGE dbo.tblHDKH_Rule_Definition AS T
        USING (SELECT @RuleID AS RuleID) AS S
        ON (T.RuleID = S.RuleID AND S.RuleID > 0)
        WHEN MATCHED THEN
            UPDATE SET
                FormID = @FormID,
                RuleDescription = @RuleDescription,
                SoGioQuyDoi_Goc = @SoGioQuyDoi_Goc,
                Formula_TinhGioGoc = @Formula_TinhGioGoc,
                MaQuyTacPhanChia = @MaQuyTacPhanChia,
                Apply_AP_Index = @Apply_AP_Index,
                NamHocApDung = @NamHocApDung,
                UpdateTime = GETDATE(),
                UpdateUser = @sys_UserID
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (FormID, RuleDescription, SoGioQuyDoi_Goc, Formula_TinhGioGoc, MaQuyTacPhanChia, Apply_AP_Index, NamHocApDung, CreateUser)
            VALUES (@FormID, @RuleDescription, @SoGioQuyDoi_Goc, @Formula_TinhGioGoc, @MaQuyTacPhanChia, @Apply_AP_Index, @NamHocApDung, @sys_UserID);
        
        -- Lấy RuleID vừa được tạo/cập nhật để sử dụng cho bảng con
        IF ISNULL(@RuleID, 0) = 0
            SET @RuleID = SCOPE_IDENTITY();

        -- Bước 3: Xóa (mềm) các Condition cũ không còn tồn tại trong payload mới
        UPDATE C
        SET C.IsDeleted = 1, C.UpdateTime = GETDATE(), C.UpdateUser = @sys_UserID
        FROM dbo.tblHDKH_Rule_Condition AS C
        LEFT JOIN OPENJSON(@ConditionsJSON) 
            WITH (ConditionID BIGINT '$.ConditionID') AS NewConditions 
            ON C.ConditionID = NewConditions.ConditionID
        WHERE C.RuleID = @RuleID AND NewConditions.ConditionID IS NULL AND C.IsDeleted = 0;

        -- Bước 4: Chèn hoặc Cập nhật các Condition từ chuỗi JSON đã trích xuất
        MERGE dbo.tblHDKH_Rule_Condition AS T
        USING (
            SELECT
                ISNULL(JSON_VALUE(c.value, '$.ConditionID'), 0) AS ConditionID,
                @RuleID AS RuleID,
                JSON_VALUE(c.value, '$.FieldID') AS FieldID,
                ISNULL(JSON_VALUE(c.value, '$.Operator'), '=') AS Operator,
                JSON_VALUE(c.value, '$.ConditionValue') AS ConditionValue
            FROM OPENJSON(@ConditionsJSON) AS c
        ) AS S
        ON (T.ConditionID = S.ConditionID AND S.ConditionID > 0)
        WHEN MATCHED THEN
            UPDATE SET
                FieldID = S.FieldID,
                Operator = S.Operator,
                ConditionValue = S.ConditionValue,
                IsDeleted = 0, -- Kích hoạt lại nếu nó đã bị xóa mềm trước đó
                UpdateTime = GETDATE(),
                UpdateUser = @sys_UserID
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (RuleID, FieldID, Operator, ConditionValue, CreateUser)
            VALUES (S.RuleID, S.FieldID, S.Operator, S.ConditionValue, @sys_UserID);
        
        COMMIT TRANSACTION;
        SELECT Message = N'Lưu Quy tắc thành công.', RuleID = @RuleID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        -- Ném lại lỗi để t-API có thể bắt và trả về cho client
        THROW;
    END CATCH;
END;

CREATE PROCEDURE spAPI_HDKH_Rule_GetListByForm
    @FormID INT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra FormID
    IF NOT EXISTS (SELECT 1 FROM dbo.tblHDKH_Form_Definition WHERE FormID = @FormID AND IsDeleted = 0)
    BEGIN
        RAISERROR(N'Form với ID %d không tồn tại.', 16, 1, @FormID);
        RETURN;
    END

    -- Chỉ cần thực hiện một câu SELECT duy nhất.
    -- t-API sẽ tự động chuyển kết quả của câu SELECT này thành một mảng JSON.
    SELECT
        R.RuleID,
        R.FormID,
        R.RuleDescription,
        R.SoGioQuyDoi_Goc,
        R.Formula_TinhGioGoc,
        R.MaQuyTacPhanChia,
        R.Apply_AP_Index,
        R.NamHocApDung,
        -- Sử dụng subquery với FOR JSON PATH để tạo một chuỗi JSON cho cột 'Conditions'
        -- t-API không tự động parse cột này, chúng ta sẽ parse ở frontend.
        json_data = ( -- Đặt tên cột là json_data để t-API tự động parse
            SELECT
                C.ConditionID,
                C.FieldID,
                F.FieldName,
                F.FieldLabel,
                C.Operator,
                C.ConditionValue
            FROM dbo.tblHDKH_Rule_Condition AS C
            JOIN dbo.tblHDKH_Field_Definition AS F ON C.FieldID = F.FieldID
            WHERE C.RuleID = R.RuleID AND C.IsDeleted = 0
            ORDER BY C.ConditionID
            FOR JSON PATH -- Kết quả của subquery này là một chuỗi, ví dụ: '[{"ConditionID":1,...}]'
        )
    FROM dbo.tblHDKH_Rule_Definition AS R
    WHERE R.FormID = @FormID AND R.IsDeleted = 0
    ORDER BY R.RuleID;

END;

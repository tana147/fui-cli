CREATE  PROCEDURE spAPI_HDKH_Form_Save
    @FormID INT = 0, -- Mặc định là 0 cho trường hợp tạo mới
    @FormCode VARCHAR(50),
    @FormTitle NVARCHAR(255),
    @SortOrder INT,

    -- Tham số hệ thống
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX) -- Có thể không dùng đến nữa hoặc dùng cho mục đích mở rộng
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra các dữ liệu bắt buộc
    IF (ISNULL(@FormCode, '') = '' OR ISNULL(@FormTitle, '') = '')
    BEGIN
        RAISERROR(N'Mã Form (FormCode) và Tên Form (FormTitle) là bắt buộc.', 16, 1);
        RETURN;
    END

    -- Sử dụng MERGE để thực hiện UPSERT
    -- Điều kiện ON bây giờ sẽ dựa vào @FormID
    MERGE tblHDKH_Form_Definition AS T
    USING (SELECT @FormID AS FormID) AS S
    ON (T.FormID = S.FormID AND S.FormID > 0) -- Chỉ MATCH khi FormID > 0
    WHEN MATCHED THEN
        UPDATE SET
            FormCode = @FormCode,
            FormTitle = @FormTitle,
            SortOrder = @SortOrder,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (FormCode, FormTitle, SortOrder, CreateUser)
        VALUES (@FormCode, @FormTitle, @SortOrder, @sys_UserID);

    -- Có thể trả về ID của bản ghi vừa được tạo/cập nhật
    -- Logic này sẽ phức tạp hơn một chút nếu dùng MERGE
    -- Cách đơn giản là trả về thông báo
    SELECT Message = N'Lưu Form thành công.';
END;

CREATE PROCEDURE [dbo].[spAPI_HDKH_DM_DanhMucTapChi_Save]
    @ID INT = 0,
    @TenDanhMuc NVARCHAR(255),
    @IsActive BIT = 1,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF LTRIM(RTRIM(ISNULL(@TenDanhMuc, ''))) = '' 
    BEGIN
        RAISERROR(N'Tên danh mục tạp chí là bắt buộc.', 16, 1);
        RETURN;
    END

    MERGE dbo.tblHDKH_DM_DanhMucTapChi AS T
    USING (SELECT @ID AS ID) AS S
    ON (T.ID = S.ID AND S.ID > 0)
    WHEN MATCHED THEN
        UPDATE SET
            TenDanhMuc = @TenDanhMuc,
            IsActive = @IsActive
            -- Không cập nhật CreateUser/CreateTime
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TenDanhMuc, IsActive)
        VALUES (@TenDanhMuc, @IsActive);
        
    SELECT Message = N'Lưu thông tin danh mục tạp chí thành công.';
END
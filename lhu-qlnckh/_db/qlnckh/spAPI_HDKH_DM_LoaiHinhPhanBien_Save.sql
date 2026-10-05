CREATE PROCEDURE [dbo].[spAPI_HDKH_DM_LoaiHinhPhanBien_Save]
    @ID INT = 0,
    @TenLoaiHinh NVARCHAR(255),
    @IsActive BIT = 1,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF LTRIM(RTRIM(ISNULL(@TenLoaiHinh, ''))) = '' 
    BEGIN
        RAISERROR(N'Tên loại hình phản biện là bắt buộc.', 16, 1);
        RETURN;
    END

    MERGE dbo.tblHDKH_DM_LoaiHinhPhanBien AS T
    USING (SELECT @ID AS ID) AS S
    ON (T.ID = S.ID AND S.ID > 0)
    WHEN MATCHED THEN
        UPDATE SET
            TenLoaiHinh = @TenLoaiHinh,
            IsActive = @IsActive
            -- Không cập nhật CreateUser/CreateTime
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TenLoaiHinh, IsActive)
        VALUES (@TenLoaiHinh, @IsActive);
        
    SELECT Message = N'Lưu thông tin loại hình phản biện thành công.';
END
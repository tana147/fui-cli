CREATE PROCEDURE dbo.spAPI_HDKH_DM_ChucDanhHocVi_Save
    @ID INT = 0,
    @TenChucDanh NVARCHAR(255),
    @DinhMucGioChuan INT,
    @GhiChu NVARCHAR(500) = NULL,
    @IsActive BIT = 1,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF LTRIM(RTRIM(ISNULL(@TenChucDanh, ''))) = '' OR @DinhMucGioChuan IS NULL
    BEGIN
        RAISERROR(N'Tên chức danh và Định mức giờ chuẩn là bắt buộc.', 16, 1);
        RETURN;
    END

    MERGE dbo.tblHDKH_DM_ChucDanhHocVi AS T
    USING (SELECT @ID AS ID) AS S
    ON (T.ID = S.ID AND S.ID > 0)
    WHEN MATCHED THEN
        UPDATE SET
            TenChucDanh = @TenChucDanh,
            DinhMucGioChuan = @DinhMucGioChuan,
            GhiChu = @GhiChu,
            IsActive = @IsActive
            -- Không cập nhật CreateUser/CreateTime
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TenChucDanh, DinhMucGioChuan, GhiChu, IsActive)
        VALUES (@TenChucDanh, @DinhMucGioChuan, @GhiChu, @IsActive);
        
    SELECT Message = N'Lưu thông tin định mức thành công.';
END

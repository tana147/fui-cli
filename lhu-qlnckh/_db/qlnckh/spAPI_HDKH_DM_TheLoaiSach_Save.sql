CREATE PROCEDURE [dbo].[spAPI_HDKH_DM_TheLoaiSach_Save]
    @ID INT = 0,
    @TenTheLoai NVARCHAR(255),
    @IsActive BIT = 1,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF LTRIM(RTRIM(ISNULL(@TenTheLoai, ''))) = '' 
    BEGIN
        RAISERROR(N'Tên thể loại sách là bắt buộc.', 16, 1);
        RETURN;
    END

    MERGE dbo.tblHDKH_DM_TheLoaiSach AS T
    USING (SELECT @ID AS ID) AS S
    ON (T.ID = S.ID AND S.ID > 0)
    WHEN MATCHED THEN
        UPDATE SET
            TenTheLoai = @TenTheLoai,
            IsActive = @IsActive
            -- Không cập nhật CreateUser/CreateTime
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TenTheLoai, IsActive)
        VALUES (@TenTheLoai,@IsActive);
        
    SELECT Message = N'Lưu thông tin thể loại sách thành công.';
END
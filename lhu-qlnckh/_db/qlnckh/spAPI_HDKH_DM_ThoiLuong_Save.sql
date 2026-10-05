CREATE PROCEDURE [dbo].[spAPI_HDKH_DM_ThoiLuong_Save]
    @ID INT = 0,
    @TenThoiLuong NVARCHAR(255),
    @IsActive BIT = 1,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF LTRIM(RTRIM(ISNULL(@TenThoiLuong, ''))) = '' 
    BEGIN
        RAISERROR(N'Tên thời lượng là bắt buộc.', 16, 1);
        RETURN;
    END

    MERGE dbo.tblHDKH_DM_ThoiLuong AS T
    USING (SELECT @ID AS ID) AS S
    ON (T.ID = S.ID AND S.ID > 0)
    WHEN MATCHED THEN
        UPDATE SET
            TenThoiLuong = @TenThoiLuong,
            IsActive = @IsActive
            -- Không cập nhật CreateUser/CreateTime
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TenThoiLuong, IsActive)
        VALUES (@TenThoiLuong,@IsActive);
    SELECT Message = N'Lưu thông tin thời lượng thành công.';
END
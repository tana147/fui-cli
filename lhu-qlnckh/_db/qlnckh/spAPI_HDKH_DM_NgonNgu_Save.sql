CREATE PROCEDURE [dbo].[spAPI_HDKH_DM_NgonNgu_Save]
    @ID INT = 0,
    @TenNgonNgu NVARCHAR(255),
	@HeSoNhan DECIMAL(5,2),
    @IsActive BIT = 1,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF LTRIM(RTRIM(ISNULL(@TenNgonNgu, ''))) = ''
    BEGIN
        RAISERROR(N'Tên ngôn ngữ là bắt buộc.', 16, 1);
        RETURN;
    END

    MERGE dbo.tblHDKH_DM_NgonNgu AS T
    USING (SELECT @ID AS ID) AS S
    ON (T.ID = S.ID AND S.ID > 0)
    WHEN MATCHED THEN
        UPDATE SET
            TenNgonNgu = @TenNgonNgu,
			HeSoNhan = @HeSoNhan,
            IsActive = @IsActive
            -- Không cập nhật CreateUser/CreateTime
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TenNgonNgu,HeSoNhan, IsActive)
        VALUES (@TenNgonNgu,@HeSoNhan, @IsActive);
        
    SELECT Message = N'Lưu thông tin ngôn ngữ thành công.';
END
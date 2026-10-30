CREATE PROCEDURE spAPI_TkbCumTachUpsert
    @ID INT = NULL,
    @MaCumTach VARCHAR(20),
    @Khoi VARCHAR(2),
    @TenCum NVARCHAR(100) = NULL,
    @GhiChu NVARCHAR(300) = NULL,
    @LopNguonJson NVARCHAR(MAX) = '[]',
    @NhomConJson NVARCHAR(MAX) = '[]',
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF @MaCumTach = ''
    BEGIN
        RAISERROR(N'Mã cụm tách không được để trống', 16, 1);
        RETURN;
    END
    IF @Khoi = ''
    BEGIN
        RAISERROR(N'Khối không được để trống', 16, 1);
        RETURN;
    END

    BEGIN TRAN;

    IF @ID IS NULL OR @ID = 0
    BEGIN
        IF EXISTS (SELECT 1 FROM tblTKB_CumTach WHERE MaCumTach = @MaCumTach AND Enable = 1)
        BEGIN
            ROLLBACK TRAN;
            RAISERROR(N'Mã cụm tách đã tồn tại', 16, 1);
            RETURN;
        END
        INSERT INTO tblTKB_CumTach (MaCumTach, Khoi, TenCum, GhiChu, CreateUser, CreateTime, Enable)
        VALUES (@MaCumTach, @Khoi, @TenCum, @GhiChu, @sys_UserID, GETDATE(), 1);
        SET @ID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM tblTKB_CumTach WHERE ID = @ID)
        BEGIN
            ROLLBACK TRAN;
            RAISERROR(N'Không tìm thấy cụm tách này', 16, 1);
            RETURN;
        END
        UPDATE tblTKB_CumTach
        SET MaCumTach = @MaCumTach, Khoi = @Khoi, TenCum = @TenCum, GhiChu = @GhiChu,
            UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE ID = @ID;

        DELETE FROM tblTKB_CumTach_LopNguon WHERE CumTachID = @ID;
        DELETE FROM tblTKB_CumTach_NhomCon WHERE CumTachID = @ID;
    END

    INSERT INTO tblTKB_CumTach_LopNguon (CumTachID, MaLop)
    SELECT @ID, value FROM OPENJSON(@LopNguonJson);

    INSERT INTO tblTKB_CumTach_NhomCon (CumTachID, MaLop)
    SELECT @ID, value FROM OPENJSON(@NhomConJson);

    COMMIT TRAN;

    SELECT N'Đã lưu thành công' AS mess, @ID AS id;
END

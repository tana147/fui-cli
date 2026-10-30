CREATE PROC [dbo].[spAPI_GiaoVienLopV1_Ins]
    @GVLopID INT = NULL,     -- ID của bản ghi, NULL nếu là thêm mới
    @KhoiID INT,
    @LopID INT,              -- Nếu VaiTro = 2 (Khối Trưởng) thì LopID = 0
    @GiaoVienID VARCHAR(9), 
    @VaiTro INT,             -- 1: Giáo viên Lớp; 2: Khối Trưởng; 3: Giáo viên bộ môn
    @MonHocID INT,           -- Nếu VaiTro in [1,2] thì MonHocID = 0
    @MaDonVi INT,
    @Sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NienKhoa INT = 2024;

    -- Nếu GVLopID được cung cấp, tiến hành cập nhật bản ghi
    IF @GVLopID IS NOT NULL
    BEGIN
        UPDATE tblGiaoVienLop
        SET 
            KhoiID = @KhoiID,
            LopID = @LopID,
            GiaoVienID = @GiaoVienID,
            VaiTro = @VaiTro,
            MonHocID = @MonHocID,
            MaDonVi = @MaDonVi,
            UpdateUser = @Sys_UserID,
            UpdateTime = GETDATE()
        WHERE 
            GVLopID = @GVLopID
            AND Enable = 1; -- Chỉ cập nhật bản ghi đang hoạt động

        -- Kiểm tra nếu không có bản ghi nào được cập nhật
        IF @@ROWCOUNT = 0
        BEGIN
            PRINT 'Không tìm thấy bản ghi để cập nhật.';
            RETURN;
        END
    END
    ELSE
    BEGIN
        -- Nếu GVLopID không được cung cấp, tiến hành thêm mới bản ghi
        INSERT INTO tblGiaoVienLop (
            GiaoVienID, KhoiID, LopID, MonHocID, MaDonVi, VaiTro, NienKhoa, CreateUser, CreateTime, Enable
        )
        VALUES (
            @GiaoVienID, @KhoiID, @LopID, @MonHocID, @MaDonVi, @VaiTro, @NienKhoa, @Sys_UserID, GETDATE(), 1
        );
    END
END;
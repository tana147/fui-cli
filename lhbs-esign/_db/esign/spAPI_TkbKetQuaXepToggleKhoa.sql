CREATE PROCEDURE spAPI_TkbKetQuaXepToggleKhoa
    @ID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Bat/tat co "da khoa tay" cho 1 tiet trong tblTKB_KetQuaXep — tiet da khoa se duoc
    -- spAPI_TkbChayAutoPhanConLai giu nguyen (khong xoa, khong cho Auto dung vao slot do); tiet chua
    -- khoa se bi xoa va dua tro lai thanh nhu cau cho Auto tu do xep lai.
    IF NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE ID = @ID)
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Không tìm thấy tiết này' AS Message, CAST(0 AS BIT) AS DaKhoa;
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID = @ID)
    BEGIN
        DELETE FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID = @ID;
        SELECT CAST(1 AS BIT) AS Success, N'Đã mở khóa' AS Message, CAST(0 AS BIT) AS DaKhoa;
    END
    ELSE
    BEGIN
        INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID, KhoaUser, KhoaTime) VALUES (@ID, @sys_UserID, GETDATE());
        SELECT CAST(1 AS BIT) AS Success, N'Đã khóa tiết này' AS Message, CAST(1 AS BIT) AS DaKhoa;
    END
END

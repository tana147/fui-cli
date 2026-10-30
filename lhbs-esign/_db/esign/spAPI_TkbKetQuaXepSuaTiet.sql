CREATE PROCEDURE spAPI_TkbKetQuaXepSuaTiet
    @ID INT,
    @MaMon VARCHAR(10),
    @MaGV VARCHAR(10),
    @MaPhong VARCHAR(10) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RunID INT, @Thu INT, @Buoi VARCHAR(10), @Tiet INT, @MaLop VARCHAR(10);
    SELECT @RunID = RunID, @Thu = Thu, @Buoi = Buoi, @Tiet = Tiet, @MaLop = MaLop
    FROM tblTKB_KetQuaXep WHERE ID = @ID;

    IF @RunID IS NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Không tìm thấy tiết học này' AS Message;
        RETURN;
    END

    -- KiemTraDoiTietTayHopLe: cùng khung giờ (Thu/Buoi/Tiet) trong cùng RunID không được trùng GV hoặc trùng phòng với tiết khác
    DECLARE @TrungGV VARCHAR(10), @TrungPhong VARCHAR(10);
    SELECT TOP 1 @TrungGV = MaLop FROM tblTKB_KetQuaXep
    WHERE RunID = @RunID AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet AND ID <> @ID AND MaGV = @MaGV;

    IF @TrungGV IS NOT NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Giáo viên đã dạy lớp ' + @TrungGV + N' cùng khung giờ này' AS Message;
        RETURN;
    END

    IF @MaPhong IS NOT NULL AND @MaPhong <> ''
    BEGIN
        SELECT TOP 1 @TrungPhong = MaLop FROM tblTKB_KetQuaXep
        WHERE RunID = @RunID AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet AND ID <> @ID AND MaPhong = @MaPhong;

        IF @TrungPhong IS NOT NULL
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Phòng đã được lớp ' + @TrungPhong + N' dùng cùng khung giờ này' AS Message;
            RETURN;
        END
    END

    UPDATE tblTKB_KetQuaXep
    SET MaMon = @MaMon, MaGV = @MaGV, MaPhong = NULLIF(@MaPhong, '')
    WHERE ID = @ID;

    -- Nguoi dung chu dong sua noi dung tiet nay -> danh dau da khoa tay (2026-09-02), xem tblTKB_KetQuaXep_Khoa.
    IF NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID = @ID)
        INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID, KhoaUser, KhoaTime) VALUES (@ID, @sys_UserID, GETDATE());

    SELECT CAST(1 AS BIT) AS Success, N'Đã lưu' AS Message;
END

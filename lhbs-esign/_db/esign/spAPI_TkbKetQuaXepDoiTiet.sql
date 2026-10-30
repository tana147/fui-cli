CREATE PROCEDURE spAPI_TkbKetQuaXepDoiTiet
    @ID1 INT,
    @ID2 INT,
    @ChoPhepKhacLop BIT = 0,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF @ID1 = @ID2
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Phải chọn 2 tiết khác nhau' AS Message;
        RETURN;
    END

    DECLARE @RunID1 INT, @Thu1 INT, @Buoi1 VARCHAR(10), @Tiet1 INT, @MaLop1 VARCHAR(10), @MaGV1 VARCHAR(10), @MaPhong1 VARCHAR(10);
    DECLARE @RunID2 INT, @Thu2 INT, @Buoi2 VARCHAR(10), @Tiet2 INT, @MaLop2 VARCHAR(10), @MaGV2 VARCHAR(10), @MaPhong2 VARCHAR(10);

    SELECT @RunID1 = RunID, @Thu1 = Thu, @Buoi1 = Buoi, @Tiet1 = Tiet, @MaLop1 = MaLop, @MaGV1 = MaGV, @MaPhong1 = MaPhong
    FROM tblTKB_KetQuaXep WHERE ID = @ID1;
    SELECT @RunID2 = RunID, @Thu2 = Thu, @Buoi2 = Buoi, @Tiet2 = Tiet, @MaLop2 = MaLop, @MaGV2 = MaGV, @MaPhong2 = MaPhong
    FROM tblTKB_KetQuaXep WHERE ID = @ID2;

    IF @RunID1 IS NULL OR @RunID2 IS NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Không tìm thấy tiết học' AS Message;
        RETURN;
    END

    IF @RunID1 <> @RunID2
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Hai tiết phải thuộc cùng một lần chạy Auto' AS Message;
        RETURN;
    END

    IF @MaLop1 <> @MaLop2 AND @ChoPhepKhacLop = 0
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Chỉ đổi tiết trong cùng một lớp' AS Message;
        RETURN;
    END

    -- 2026-09-16 (theo de xuat nguoi dung "cho keo giua 2 lop" — doi GIO day giua 2 lop, moi tiet
    -- GIU NGUYEN Mon/GV cua no, chi hoan doi vi tri Thu/Buoi/Tiet): khi @ChoPhepKhacLop=1 va 2 lop
    -- khac nhau, kiem tra THEM xung dot cap LOP (truong hop cung lop thi tu nhien an toan vi 2 slot
    -- dang doi von thuoc chinh no, khong can kiem tra rieng).
    IF @MaLop1 <> @MaLop2
    BEGIN
        DECLARE @XungDotLop VARCHAR(10);
        SELECT TOP 1 @XungDotLop = MaMon FROM tblTKB_KetQuaXep
        WHERE RunID = @RunID1 AND MaLop = @MaLop1 AND Thu = @Thu2 AND Buoi = @Buoi2 AND Tiet = @Tiet2 AND ID NOT IN (@ID1, @ID2);
        IF @XungDotLop IS NOT NULL
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Lớp ' + @MaLop1 + N' đã có tiết ' + @XungDotLop + N' ở khung giờ đích' AS Message;
            RETURN;
        END

        SELECT TOP 1 @XungDotLop = MaMon FROM tblTKB_KetQuaXep
        WHERE RunID = @RunID2 AND MaLop = @MaLop2 AND Thu = @Thu1 AND Buoi = @Buoi1 AND Tiet = @Tiet1 AND ID NOT IN (@ID1, @ID2);
        IF @XungDotLop IS NOT NULL
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Lớp ' + @MaLop2 + N' đã có tiết ' + @XungDotLop + N' ở khung giờ đích' AS Message;
            RETURN;
        END
    END

    -- KiemTraDoiTietTayHopLe: sau khi đổi (Thu/Buoi/Tiet), GV/Phòng của mỗi tiết không được trùng tiết khác (ngoài 2 tiết đang đổi) ở khung giờ mới
    DECLARE @XungDot VARCHAR(10);

    SELECT TOP 1 @XungDot = MaLop FROM tblTKB_KetQuaXep
    WHERE RunID = @RunID1 AND Thu = @Thu2 AND Buoi = @Buoi2 AND Tiet = @Tiet2 AND ID NOT IN (@ID1, @ID2) AND MaGV = @MaGV1;
    IF @XungDot IS NOT NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Sau khi đổi, giáo viên tiết 1 sẽ trùng lịch với lớp ' + @XungDot AS Message;
        RETURN;
    END

    SELECT TOP 1 @XungDot = MaLop FROM tblTKB_KetQuaXep
    WHERE RunID = @RunID2 AND Thu = @Thu1 AND Buoi = @Buoi1 AND Tiet = @Tiet1 AND ID NOT IN (@ID1, @ID2) AND MaGV = @MaGV2;
    IF @XungDot IS NOT NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Sau khi đổi, giáo viên tiết 2 sẽ trùng lịch với lớp ' + @XungDot AS Message;
        RETURN;
    END

    IF @MaPhong1 IS NOT NULL
    BEGIN
        SELECT TOP 1 @XungDot = MaLop FROM tblTKB_KetQuaXep
        WHERE RunID = @RunID1 AND Thu = @Thu2 AND Buoi = @Buoi2 AND Tiet = @Tiet2 AND ID NOT IN (@ID1, @ID2) AND MaPhong = @MaPhong1;
        IF @XungDot IS NOT NULL
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Sau khi đổi, phòng tiết 1 sẽ trùng lịch với lớp ' + @XungDot AS Message;
            RETURN;
        END
    END

    IF @MaPhong2 IS NOT NULL
    BEGIN
        SELECT TOP 1 @XungDot = MaLop FROM tblTKB_KetQuaXep
        WHERE RunID = @RunID2 AND Thu = @Thu1 AND Buoi = @Buoi1 AND Tiet = @Tiet1 AND ID NOT IN (@ID1, @ID2) AND MaPhong = @MaPhong2;
        IF @XungDot IS NOT NULL
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Sau khi đổi, phòng tiết 2 sẽ trùng lịch với lớp ' + @XungDot AS Message;
            RETURN;
        END
    END

    UPDATE tblTKB_KetQuaXep SET Thu = @Thu2, Buoi = @Buoi2, Tiet = @Tiet2 WHERE ID = @ID1;
    UPDATE tblTKB_KetQuaXep SET Thu = @Thu1, Buoi = @Buoi1, Tiet = @Tiet1 WHERE ID = @ID2;

    -- Nguoi dung chu dong keo-tha doi tiet -> danh dau da khoa tay (2026-09-16, dong bo voi ChuyenTiet).
    IF NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID = @ID1)
        INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID, KhoaUser, KhoaTime) VALUES (@ID1, @sys_UserID, GETDATE());
    IF NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID = @ID2)
        INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID, KhoaUser, KhoaTime) VALUES (@ID2, @sys_UserID, GETDATE());

    SELECT CAST(1 AS BIT) AS Success, N'Đã đổi tiết' AS Message;
END
CREATE PROCEDURE spAPI_TkbGoiYApDung
    @RunID INT,
    @MaLop VARCHAR(10),
    @MaMon VARCHAR(10),
    @MaGV VARCHAR(10),
    @LoaiGoiY VARCHAR(20),
    @Thu INT,
    @Buoi VARCHAR(10),
    @Tiet INT,
    @OccupantLop VARCHAR(10) = NULL,
    @OccupantMon VARCHAR(10) = NULL,
    @Thu2 INT = NULL,
    @Buoi2 VARCHAR(10) = NULL,
    @Tiet2 INT = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Ap dung 1 dong ket qua tra ve tu spAPI_TkbGoiYChuoi (2026-08-30) — bien "goi y" thanh hanh dong
    -- thuc su, dong bo voi bang tblTKB_ChayAutoKhongXepDuoc (giam SoTiet / xoa khi het).
    -- LoaiGoiY = 'TRUC_TIEP': chi can INSERT 1 dong moi.
    -- LoaiGoiY = 'CHUOI_1_BUOC': truoc tien UPDATE doi (Thu,Buoi,Tiet) cua nguoi dang chiem
    -- (Occupant, xac dinh qua MaLop=@OccupantLop, MaMon=@OccupantMon, MaGV=@MaGV, dung slot @Thu/@Buoi/@Tiet)
    -- sang slot moi (@Thu2/@Buoi2/@Tiet2), roi moi INSERT dong can them vao cho vua trong ra.
    -- Kiem tra lai xung dot ngay truoc khi ghi (du lieu co the da doi ke tu luc goi y duoc tinh).

    IF EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @MaLop AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet)
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Khung giờ này đã bị chiếm mất — thử lại gợi ý mới' AS Message;
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaGV = @MaGV AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet)
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Giáo viên đã có lịch khác đúng khung giờ này — thử lại gợi ý mới' AS Message;
        RETURN;
    END

    IF @LoaiGoiY = 'CHUOI_1_BUOC'
    BEGIN
        DECLARE @OccupantID INT;
        SELECT TOP 1 @OccupantID = ID FROM tblTKB_KetQuaXep
        WHERE RunID = @RunID AND MaLop = @OccupantLop AND MaMon = @OccupantMon AND MaGV = @MaGV
          AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet;

        IF @OccupantID IS NULL
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Tiết đang chiếm chỗ không còn ở đúng vị trí — thử lại gợi ý mới' AS Message;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @OccupantLop AND Thu = @Thu2 AND Buoi = @Buoi2 AND Tiet = @Tiet2)
           OR EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaGV = @MaGV AND Thu = @Thu2 AND Buoi = @Buoi2 AND Tiet = @Tiet2)
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Khung giờ dự kiến chuyển tới đã bị chiếm — thử lại gợi ý mới' AS Message;
            RETURN;
        END

        UPDATE tblTKB_KetQuaXep SET Thu = @Thu2, Buoi = @Buoi2, Tiet = @Tiet2 WHERE ID = @OccupantID;

        -- Nguoi dung chu dong bam ap dung goi y chuoi -> danh dau da khoa tay cho ca tiet Occupant vua
        -- doi cho (2026-09-02, xem tblTKB_KetQuaXep_Khoa) de spAPI_TkbChayAutoPhanConLai khong xoa
        -- xep lai mat cong nguoi dung vua sap.
        IF NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID = @OccupantID)
            INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID, KhoaUser, KhoaTime) VALUES (@OccupantID, @sys_UserID, GETDATE());
    END

    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
    VALUES (@RunID, @MaLop, @Thu, @Buoi, @Tiet, @MaMon, @MaGV, NULL);

    -- Danh dau da khoa tay cho tiet vua them (2026-09-02) — day la hanh dong chu dong cua nguoi dung
    -- (chon goi y hoac keo-tha), khac voi tiet do 1 lan Auto tu sap.
    INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID, KhoaUser, KhoaTime) VALUES (SCOPE_IDENTITY(), @sys_UserID, GETDATE());

    -- Giam SoTiet con thieu, xoa khoi danh sach neu het
    UPDATE tblTKB_ChayAutoKhongXepDuoc SET SoTiet = SoTiet - 1
    WHERE RunID = @RunID AND MaLop = @MaLop AND MaMon = @MaMon AND MaGV = @MaGV AND SoTiet > 0;

    DELETE FROM tblTKB_ChayAutoKhongXepDuoc
    WHERE RunID = @RunID AND MaLop = @MaLop AND MaMon = @MaMon AND MaGV = @MaGV AND SoTiet <= 0;

    SELECT CAST(1 AS BIT) AS Success, N'Đã thêm vào lịch' AS Message;
END

CREATE PROCEDURE spAPI_TkbGoiYOCoApDung
    @RunID INT,
    @MaLop VARCHAR(10),
    @MaMon VARCHAR(20),
    @MaGV VARCHAR(15),
    @Thu INT,
    @Buoi VARCHAR(10),
    @Tiet INT,
    @IDChuyen INT,
    @Thu2 INT,
    @Buoi2 VARCHAR(10),
    @Tiet2 INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    -- 2026-10-06: ap dung 1 dong goi y cua spAPI_TkbGoiYOCo. @IDChuyen <> NULL (DOI_GV / DOI_LOP): chuyen tiet do
    -- sang (@Thu2,@Buoi2,@Tiet2) truoc, roi them tiet con thieu vao (@Thu,@Buoi,@Tiet). Kiem tra lai trung lich
    -- vat ly ngay truoc khi ghi (du lieu co the da doi tu luc goi y). PHA_LUAT ghi binh thuong (chi vi pham bao ban,
    -- nguoi xep da chu dong chon). Moi dong thay doi deu KHOA TAY de lan chay Auto sau khong xoa cong nguoi sap.
    -- UI gui 0 / '' thay cho NULL (tAPI khong ho tro tham so mac dinh / NULL tu JS).
    IF @IDChuyen = 0 SET @IDChuyen = NULL;
    IF @Thu2 = 0 SET @Thu2 = NULL;
    IF @Buoi2 = '' SET @Buoi2 = NULL;
    IF @Tiet2 = 0 SET @Tiet2 = NULL;
    BEGIN TRAN;

    -- THAY_THE: @IDChuyen co, @Thu2 NULL -> bo tiet do ra (xoa), tiet do tu quay ve danh sach con thieu.
    IF @IDChuyen IS NOT NULL AND @Thu2 IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE ID = @IDChuyen AND RunID = @RunID AND MaLop = @MaLop
                       AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet)
        BEGIN
            ROLLBACK;
            SELECT CAST(0 AS BIT) AS Success, N'Tiết cần thay không còn ở vị trí cũ — bấm gợi ý lại' AS Message;
            RETURN;
        END
        DELETE FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID = @IDChuyen;
        DELETE FROM tblTKB_KetQuaXep WHERE ID = @IDChuyen;
    END
    ELSE IF @IDChuyen IS NOT NULL
    BEGIN
        DECLARE @cLop VARCHAR(10), @cGV VARCHAR(15);
        SELECT @cLop = MaLop, @cGV = MaGV FROM tblTKB_KetQuaXep
        WHERE ID = @IDChuyen AND RunID = @RunID AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet;
        IF @cLop IS NULL
        BEGIN
            ROLLBACK;
            SELECT CAST(0 AS BIT) AS Success, N'Tiết cần chuyển không còn ở vị trí cũ — bấm gợi ý lại' AS Message;
            RETURN;
        END
        IF EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @cLop AND Thu = @Thu2 AND Buoi = @Buoi2 AND Tiet = @Tiet2)
           OR EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaGV = @cGV AND ID <> @IDChuyen AND Thu = @Thu2 AND Buoi = @Buoi2 AND Tiet = @Tiet2)
        BEGIN
            ROLLBACK;
            SELECT CAST(0 AS BIT) AS Success, N'Ô định chuyển tới đã bị chiếm — bấm gợi ý lại' AS Message;
            RETURN;
        END
        UPDATE tblTKB_KetQuaXep SET Thu = @Thu2, Buoi = @Buoi2, Tiet = @Tiet2 WHERE ID = @IDChuyen;
        IF NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID = @IDChuyen)
            INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID, KhoaUser, KhoaTime) VALUES (@IDChuyen, @sys_UserID, GETDATE());
    END

    IF EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @MaLop AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet)
    BEGIN
        ROLLBACK;
        SELECT CAST(0 AS BIT) AS Success, N'Lớp đã có tiết khác ở ô này — bấm gợi ý lại' AS Message;
        RETURN;
    END
    IF EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaGV = @MaGV AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet)
    BEGIN
        ROLLBACK;
        SELECT CAST(0 AS BIT) AS Success, N'Giáo viên đã có lịch khác ở ô này — bấm gợi ý lại' AS Message;
        RETURN;
    END

    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
    VALUES (@RunID, @MaLop, @Thu, @Buoi, @Tiet, @MaMon, @MaGV, NULL);
    INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID, KhoaUser, KhoaTime) VALUES (SCOPE_IDENTITY(), @sys_UserID, GETDATE());

    UPDATE tblTKB_ChayAutoKhongXepDuoc SET SoTiet = SoTiet - 1
    WHERE RunID = @RunID AND MaLop = @MaLop AND MaMon = @MaMon AND MaGV = @MaGV AND SoTiet > 0;
    DELETE FROM tblTKB_ChayAutoKhongXepDuoc
    WHERE RunID = @RunID AND MaLop = @MaLop AND MaMon = @MaMon AND MaGV = @MaGV AND SoTiet <= 0;

    COMMIT;
    SELECT CAST(1 AS BIT) AS Success, N'Đã xếp vào Thứ ' + CAST(@Thu AS NVARCHAR(2))
           + CASE @Buoi WHEN 'Sang' THEN N' sáng' ELSE N' chiều' END + N' tiết ' + CAST(@Tiet AS NVARCHAR(2)) AS Message;
END

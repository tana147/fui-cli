CREATE PROCEDURE spAPI_TkbChayAutoThongMinh
    @Khoi VARCHAR(50),
    @HocKy VARCHAR(4) = 'HK1',
    @MaxSecs INT = 300,
    @TuanHienTai INT = NULL,
    @SoRoundToiDa INT = 2,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- "Chay thong minh" (2026-08-30, thay the quy trinh nguoi dung phai tu tay lap qua chat nhieu
    -- lan trong 1 phien lam viec): tu dong (1) chay Auto nhieu vong, giu ban SoNhomKhongXepDuoc thap
    -- nhat, (2) neu van con thieu sau het cac vong thuong, tu dong xac dinh (cac) GV lien quan den
    -- nhung nhom con thieu, khoa cung TOAN BO lich THAT cua ho (tu tblTKB_ThucTe_ChiTiet, du lieu da
    -- crawl tu TKB dang dung thuc te) roi chay lai 1 lan nua voi @RunIDDangXay — dung ky thuat
    -- "warm-start" da chung minh hieu qua qua nhieu lan thu thu cong (VD Do Thi Duyen/Carreon o khoi
    -- 06-07 hom 2026-08-29/30). Ham nay CHAY DONG BO (co the mat vai phut, dung WAITFOR DELAY poll
    -- trang thai) — chi goi khi da san sang doi.

    IF @SoRoundToiDa IS NULL OR @SoRoundToiDa < 1 SET @SoRoundToiDa = 1;
    IF @SoRoundToiDa > 4 SET @SoRoundToiDa = 4; -- an toan, tranh phien SQL treo qua lau

    DECLARE @RunID INT, @TrangThai NVARCHAR(50), @WaitedSecs INT, @SoThieu INT;
    DECLARE @BestRunID INT = NULL, @BestSoThieu INT = 999999;
    DECLARE @Round INT = 1;
    DECLARE @NhatKy NVARCHAR(MAX) = N'';

    WHILE @Round <= @SoRoundToiDa AND ISNULL(@BestSoThieu, 1) > 0
    BEGIN
        EXEC spAPI_TkbChayAuto @Khoi = @Khoi, @HocKy = @HocKy, @MaxSecs = @MaxSecs, @TuanHienTai = @TuanHienTai, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
        SELECT TOP 1 @RunID = RunID FROM tblTKB_ChayAutoLog ORDER BY RunID DESC;

        SET @TrangThai = N'DangChay'; SET @WaitedSecs = 0;
        WHILE @TrangThai = N'DangChay' AND @WaitedSecs < (@MaxSecs + 60)
        BEGIN
            WAITFOR DELAY '00:00:08';
            SET @WaitedSecs = @WaitedSecs + 8;
            EXEC spAPI_TkbChayAutoTrangThai @RunID = @RunID, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
            SELECT @TrangThai = TrangThai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
        END

        SET @SoThieu = (SELECT COUNT(*) FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = @RunID);
        SET @NhatKy = @NhatKy + N'Round ' + CAST(@Round AS NVARCHAR(5)) + N': RunID=' + CAST(@RunID AS NVARCHAR(10))
            + N', TrangThai=' + ISNULL(@TrangThai, N'?') + N', ConThieu=' + CAST(@SoThieu AS NVARCHAR(5)) + CHAR(13);

        IF @TrangThai = N'Feasible' AND @SoThieu < @BestSoThieu
        BEGIN
            SET @BestSoThieu = @SoThieu;
            SET @BestRunID = @RunID;
        END

        SET @Round = @Round + 1;
    END

    -- Buoc leo thang: neu sau het cac vong thuong van con thieu, tu dong warm-start bang lich THAT
    -- cua chinh (cac) GV dang bi ket.
    IF ISNULL(@BestSoThieu, 1) > 0 AND @BestRunID IS NOT NULL
    BEGIN
        IF EXISTS (
            SELECT 1 FROM tblTKB_ThucTe_ChiTiet tt
            WHERE tt.MaGV IN (SELECT DISTINCT MaGV FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = @BestRunID)
        )
        BEGIN
            INSERT INTO tblTKB_ChayAutoLog (Khoi, MaxSecs, TrangThai, NguoiChay, SoNhuCau, TuanHienTai)
            VALUES (CASE WHEN CHARINDEX(',', @Khoi) > 0 THEN LEFT(@Khoi, 1) + '+' ELSE @Khoi END, @MaxSecs, N'DangXay', @sys_UserID, 0, @TuanHienTai);
            DECLARE @WarmRunID INT = SCOPE_IDENTITY();

            INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
            SELECT DISTINCT @WarmRunID, tt.MaLop, tt.Thu, tt.Buoi, tt.Tiet, tt.MaMon, tt.MaGV, NULL
            FROM tblTKB_ThucTe_ChiTiet tt
            INNER JOIN tblTKB_Lop l ON l.MaLop = tt.MaLop
            WHERE (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
              AND tt.MaGV IN (SELECT DISTINCT MaGV FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = @BestRunID);

            EXEC spAPI_TkbChayAuto @Khoi = @Khoi, @HocKy = @HocKy, @MaxSecs = @MaxSecs, @TuanHienTai = @TuanHienTai, @RunIDDangXay = @WarmRunID, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;

            SET @TrangThai = N'DangChay'; SET @WaitedSecs = 0;
            WHILE @TrangThai = N'DangChay' AND @WaitedSecs < (@MaxSecs + 60)
            BEGIN
                WAITFOR DELAY '00:00:08';
                SET @WaitedSecs = @WaitedSecs + 8;
                EXEC spAPI_TkbChayAutoTrangThai @RunID = @WarmRunID, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
                SELECT @TrangThai = TrangThai FROM tblTKB_ChayAutoLog WHERE RunID = @WarmRunID;
            END

            DECLARE @SoThieuWarm INT = (SELECT COUNT(*) FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = @WarmRunID);
            SET @NhatKy = @NhatKy + N'Warm-start (khoa lich that GV bi ket): RunID=' + CAST(@WarmRunID AS NVARCHAR(10))
                + N', TrangThai=' + ISNULL(@TrangThai, N'?') + N', ConThieu=' + CAST(@SoThieuWarm AS NVARCHAR(5)) + CHAR(13);

            IF @TrangThai = N'Feasible' AND @SoThieuWarm < @BestSoThieu
            BEGIN
                SET @BestSoThieu = @SoThieuWarm;
                SET @BestRunID = @WarmRunID;
            END
        END
        ELSE
        BEGIN
            SET @NhatKy = @NhatKy + N'Khong co du lieu TKB that cho (cac) GV bi ket trong tblTKB_ThucTe_ChiTiet — bo qua buoc warm-start.' + CHAR(13);
        END
    END

    SELECT @BestRunID AS RunIDTotNhat, ISNULL(@BestSoThieu, 0) AS SoNhomConThieu, @NhatKy AS NhatKy;
END

CREATE PROCEDURE spAPI_TkbGVBackupSlotTuanInsert
    @MaGV VARCHAR(9),
    @TuanTu INT,
    @TuanDen INT,
    @Thu INT,
    @Buoi VARCHAR(10),
    @Tiet INT = NULL,
    @Phat INT = 1500,
    @LyDo NVARCHAR(300),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-30: "vung du phong" GV — CHI dung khi nguoi nhap XAC NHAN that (vd GVCN/to truong bao GV nay
    -- van day duoc buoi nay neu bat buoc). Bat buoc @LyDo khac rong de co dau vet ai xac nhan, tranh nhap
    -- bua lam sai lich thuc te (xem ghi chu day du trong TkbCpSatSolver.cs _gvBackupSlot). Cung 1 (GV,Tuan,
    -- Thu,Buoi,Tiet) khong duoc trung voi chinh no lan 2 (kiem tra don gian truoc khi insert).
    IF @LyDo IS NULL OR LTRIM(RTRIM(@LyDo)) = ''
    BEGIN
        SELECT mess = N'Phải ghi rõ lý do/ai xác nhận buổi dự phòng này là thật trước khi lưu.', success = CAST(0 AS BIT);
        RETURN;
    END
    IF @Phat IS NULL OR @Phat < 800 SET @Phat = 800;
    IF @Phat > 4500 SET @Phat = 4500;
    IF @TuanDen IS NULL SET @TuanDen = @TuanTu;
    IF @TuanDen < @TuanTu SET @TuanDen = @TuanTu;

    ;WITH Tuans AS (
        SELECT @TuanTu AS Tuan
        UNION ALL
        SELECT Tuan + 1 FROM Tuans WHERE Tuan < @TuanDen
    ),
    -- Tiet NOT NULL trong bang (khac tblTKB_GVCamTuyetDoi_Tuan) vi solver doc tung (MaGV,Thu,Buoi,Tiet) cu the —
    -- @Tiet = NULL (UI "bo trong = ca buoi") duoc trai thanh moi tiet 1..5 cua buoi do.
    Tiets AS (SELECT @Tiet AS Tiet WHERE @Tiet IS NOT NULL UNION ALL SELECT v.Tiet FROM (VALUES(1),(2),(3),(4),(5)) v(Tiet) WHERE @Tiet IS NULL)
    INSERT INTO tblTKB_GVBackupSlot_Tuan (Tuan, MaGV, Thu, Buoi, Tiet, Phat, LyDo, CreateUser, CreateTime)
    SELECT t.Tuan, @MaGV, @Thu, @Buoi, ti.Tiet, @Phat, @LyDo, @sys_UserID, GETDATE()
    FROM Tuans t CROSS JOIN Tiets ti
    WHERE NOT EXISTS (
        SELECT 1 FROM tblTKB_GVBackupSlot_Tuan x
        WHERE x.Tuan = t.Tuan AND x.MaGV = @MaGV AND x.Thu = @Thu AND x.Buoi = @Buoi AND x.Tiet = ti.Tiet
    )
    OPTION (MAXRECURSION 100);

    SELECT mess = N'Đã thêm ' + CAST(@TuanDen - @TuanTu + 1 AS VARCHAR(10)) + N' tuần', success = CAST(1 AS BIT);
END

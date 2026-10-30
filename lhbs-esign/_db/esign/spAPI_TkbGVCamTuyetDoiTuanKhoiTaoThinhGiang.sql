CREATE PROCEDURE spAPI_TkbGVCamTuyetDoiTuanKhoiTaoThinhGiang
    @MaGV VARCHAR(9),
    @TuanTu INT,
    @TuanDen INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-12 (theo de xuat nguoi dung: "UI thinh giang la default BAN, chi set gio co the sap —
    -- lay du lieu thinh giang ra gan san data mau luon"): GV thinh giang thuong chi ranh vai slot/tuan,
    -- khai het cac slot BAN con lai bang tay rat de sot. Thay vi bat dau tu RONG (giong GV thuong), SP
    -- nay "gieo mau" san BAN CA TUAN (moi Thu 2-6, ca Sang lan Chieu, Tiet=NULL nghia la ca buoi — dung
    -- quy uoc co san trong spAPI_TkbChayAuto.sql doc bang nay) — nguoi dung SAU DO chi can XOA dung
    -- vai dong ung voi gio GV nay THAT SU day duoc (xoa = danh dau ranh), thay vi phai THEM tung dong
    -- BAN rieng le tu dau.
    IF @TuanDen IS NULL SET @TuanDen = @TuanTu;
    IF @TuanDen < @TuanTu SET @TuanDen = @TuanTu;

    ;WITH Tuans AS (
        SELECT @TuanTu AS Tuan
        UNION ALL
        SELECT Tuan + 1 FROM Tuans WHERE Tuan < @TuanDen
    ),
    Ngay AS (
        SELECT Thu FROM (VALUES (2),(3),(4),(5),(6)) d(Thu)
    ),
    Buoi AS (
        SELECT Buoi FROM (VALUES (N'Sang'),(N'Chieu')) b(Buoi)
    )
    INSERT INTO tblTKB_GVCamTuyetDoi_Tuan (Tuan, MaGV, Thu, Buoi, Tiet, LyDo, CreateUser, CreateTime)
    SELECT t.Tuan, @MaGV, n.Thu, b.Buoi, NULL, N'Bận (mặc định thỉnh giảng — xoá dòng nào GV rảnh)', @sys_UserID, GETDATE()
    FROM Tuans t
    CROSS JOIN Ngay n
    CROSS JOIN Buoi b
    WHERE NOT EXISTS (
        SELECT 1 FROM tblTKB_GVCamTuyetDoi_Tuan e
        WHERE e.Tuan = t.Tuan AND e.MaGV = @MaGV AND e.Thu = n.Thu AND e.Buoi = b.Buoi
    )
    OPTION (MAXRECURSION 100);

    SELECT mess = N'Đã khởi tạo lịch bận mặc định — vào xoá bớt đúng giờ GV rảnh'
END

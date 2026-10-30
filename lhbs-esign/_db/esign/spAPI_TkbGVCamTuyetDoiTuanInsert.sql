CREATE PROCEDURE spAPI_TkbGVCamTuyetDoiTuanInsert
    @MaGV VARCHAR(9),
    @TuanTu INT,
    @TuanDen INT,
    @Thu INT,
    @Buoi VARCHAR(10) = '',
    @Tiet INT = NULL,
    @LyDo NVARCHAR(200) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-12 (theo de xuat nguoi dung: "CSDL phai hieu theo tung GV - tung Tuan, default la
    -- nhan bang ra giong nhau"): 1 UI khai bao BAN/HOP/cong tac ap dung chung cho MOI GV (ke ca thinh
    -- giang, khong dao nguoc mo hinh — mac dinh RANH, chi gan gio BAN, dung dung tblTKB_GVCamTuyetDoi_Tuan
    -- da co san). Khi khai cho 1 khoang nhieu tuan lien tiep, sinh THUC nhieu dong giong nhau (1 dong/
    -- tuan) thay vi luu 1 dong voi khoang - dung dung cau truc bang hien co (chi co cot Tuan don, khong
    -- co TuanApDungTu/Den).
    IF @TuanDen IS NULL SET @TuanDen = @TuanTu;
    IF @TuanDen < @TuanTu SET @TuanDen = @TuanTu;

    ;WITH Tuans AS (
        SELECT @TuanTu AS Tuan
        UNION ALL
        SELECT Tuan + 1 FROM Tuans WHERE Tuan < @TuanDen
    )
    INSERT INTO tblTKB_GVCamTuyetDoi_Tuan (Tuan, MaGV, Thu, Buoi, Tiet, LyDo, CreateUser, CreateTime)
    SELECT Tuan, @MaGV, @Thu, @Buoi, @Tiet, @LyDo, @sys_UserID, GETDATE()
    FROM Tuans
    OPTION (MAXRECURSION 100);

    SELECT mess = N'Đã thêm ' + CAST(@TuanDen - @TuanTu + 1 AS VARCHAR(10)) + N' tuần'
END

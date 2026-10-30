CREATE PROCEDURE spAPI_TkbRunIDThongTin
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-12 (theo de xuat nguoi dung "refresh la mat het, phai chay lai tu dau"): cho phep UI
    -- "nap lai" 1 RunID da chay truoc do (vd sau khi F5 mat het state trong vueData) — tra ve du
    -- lieu can thiet (Khoi THAT tu chinh cac lop dang co trong RunID, TuanHienTai, TrangThai) de UI
    -- tu dong khoi phuc lai dung buoc dang o dau, khong bat nguoi dung chon lai Tuan/Khoi tu dau va
    -- chay lai toan bo tu Round 1.
    IF NOT EXISTS (SELECT 1 FROM tblTKB_ChayAutoLog WHERE RunID = @RunID)
    BEGIN
        SELECT @RunID AS RunID, N'KhongTonTai' AS TrangThai, CAST(0 AS BIT) AS TonTai,
               NULL AS Khoi, NULL AS TuanHienTai;
        RETURN;
    END

    DECLARE @Khoi VARCHAR(50), @TuanHienTai INT, @TrangThai NVARCHAR(50);
    SELECT @TuanHienTai = TuanHienTai, @TrangThai = TrangThai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;

    SELECT @Khoi = STRING_AGG(x.Khoi, ',') FROM (
        SELECT DISTINCT l.Khoi
        FROM tblTKB_KetQuaXep k
        INNER JOIN tblTKB_Lop l ON l.MaLop = k.MaLop
        WHERE k.RunID = @RunID
    ) x;

    SELECT @RunID AS RunID, @TrangThai AS TrangThai, CAST(1 AS BIT) AS TonTai,
           @Khoi AS Khoi, @TuanHienTai AS TuanHienTai;
END

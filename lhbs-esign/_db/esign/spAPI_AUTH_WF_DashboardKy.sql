CREATE PROCEDURE spAPI_AUTH_WF_DashboardKy
    @NguoiKy varchar(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- SELECT 1 (data[0]): các thẻ thống kê
    SELECT
        ChoKyHomNay = (
            SELECT COUNT(*) FROM tblWF_NguoiKy nk
            JOIN tblWF_GoiKy g ON g.GoiKyID = nk.GoiKyID
            WHERE nk.Enable = 1 AND g.Enable = 1 AND nk.TrangThai = 'CHO'
              AND (@NguoiKy IS NULL OR nk.GiaTriNguoiKy = @NguoiKy)
        ),
        DaKyTuanNay = (
            SELECT COUNT(*) FROM tblWF_NguoiKy nk
            JOIN tblWF_GoiKy g ON g.GoiKyID = nk.GoiKyID
            WHERE nk.Enable = 1 AND g.Enable = 1 AND nk.TrangThai = 'DA_KY'
              AND nk.NgayKy >= DATEADD(day, -7, GETDATE())
              AND (@NguoiKy IS NULL OR nk.GiaTriNguoiKy = @NguoiKy)
        ),
        KyNoiBo = (
            SELECT COUNT(*) FROM tblWF_NguoiKy nk
            JOIN tblWF_GoiKy g ON g.GoiKyID = nk.GoiKyID
            WHERE nk.Enable = 1 AND g.Enable = 1 AND nk.TrangThai = 'CHO'
              AND g.HinhThucKy = 'CA_NOIBO'
              AND (@NguoiKy IS NULL OR nk.GiaTriNguoiKy = @NguoiKy)
        ),
        KyPhapLy = (
            SELECT COUNT(*) FROM tblWF_NguoiKy nk
            JOIN tblWF_GoiKy g ON g.GoiKyID = nk.GoiKyID
            WHERE nk.Enable = 1 AND g.Enable = 1 AND nk.TrangThai = 'CHO'
              AND g.HinhThucKy IN ('SMARTCA','VNPT_ECONTRACT')
              AND (@NguoiKy IS NULL OR nk.GiaTriNguoiKy = @NguoiKy)
        );

    -- SELECT 2 (data[1]): danh sách văn bản đang chờ ký
    SELECT g.GoiKyID, g.TieuDe, g.HinhThucKy,
        HinhThucKyText = CASE g.HinhThucKy
            WHEN 'CA_NOIBO' THEN N'Ký nội bộ'
            WHEN 'SMARTCA' THEN N'VNPT SmartCA'
            WHEN 'VNPT_ECONTRACT' THEN N'HĐ điện tử VNPT'
            ELSE g.HinhThucKy END,
        NhomKy = CASE WHEN g.HinhThucKy = 'CA_NOIBO' THEN 'NOIBO' ELSE 'PHAPLY' END,
        nk.TenNguoiKy, nk.PhongBan, nk.ThuTuKy,
        g.CreateTime,
        SoNgayCho = DATEDIFF(day, g.CreateTime, GETDATE()),
        LoaiHoSo = CASE WHEN g.HoSoID IS NULL THEN N'Ký tự do' ELSE N'Trong quy trình' END
    FROM tblWF_NguoiKy nk
    JOIN tblWF_GoiKy g ON g.GoiKyID = nk.GoiKyID
    WHERE nk.Enable = 1 AND g.Enable = 1 AND nk.TrangThai = 'CHO'
      AND (@NguoiKy IS NULL OR nk.GiaTriNguoiKy = @NguoiKy)
    ORDER BY g.CreateTime ASC;
END
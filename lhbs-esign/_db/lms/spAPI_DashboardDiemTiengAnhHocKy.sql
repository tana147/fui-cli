
-- EXEC [spAPI_DashboardDiemTiengAnhHocKy]  12 ,'N251201', 19200057, 2025
CREATE PROCEDURE [dbo].[spAPI_DashboardDiemTiengAnhHocKy]
    @KhoiID INT,
    @LopID VARCHAR(20),
    @HocSinhID INT,
	@NienKhoa INT
AS
BEGIN
   -- Truy vấn dữ liệu
    SELECT 
        ths.Ho + ' ' + ths.Ten AS HoTen,
        tbdct.MaNhomCotDiem,
        tbdct.TenNhomCotDiem_EN,
        tbdct.MaCotDiem,
        tbdct.TenCotDiem_EN,
        tkqht.KetQuaDanhGia_VI,
        n.NhomID AS LopID,
        n.TenNhom AS TenLop,
        tbdct.Semester
    FROM dbo.tblKetQuaHocTap tkqht
        INNER JOIN dbo.tblHocSinh ths ON tkqht.HocSinhID = ths.HocSinhID and ths.TinhTrang= 0
        INNER JOIN dbo.tblNhom n ON tkqht.LopID = n.NhomID and n.NienKhoa =@NienKhoa 
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
        INNER JOIN dbo.tblMonHoc tmh ON tmhl.MonHocID = tmh.MonHocID
        INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
    WHERE 
        n.KhoiID = @KhoiID
        AND tmh.MonHocID = 76
        AND tkqht.LopID = @LopID
        AND ths.HocSinhID = @HocSinhID
		AND tkqht.NienKhoa = @NienKhoa
        AND tbdct.MaCotDiem like '%TA2%'
        AND tbdct.MaCotDiem not like '%Conv%'
        AND tkqht.Enable = 1
    ORDER BY ThuTuNhom, ThuTuCotDiem, MaNhomCotDiem, MaCotDiem;

    -- Truy vấn dữ liệu
    SELECT 
        ths.Ho + ' ' + ths.Ten AS HoTen,
        tbdct.MaNhomCotDiem,
        tbdct.TenNhomCotDiem_EN,
        tbdct.MaCotDiem,
        tbdct.TenCotDiem_EN,
        tkqht.KetQuaDanhGia_VI,
        n.NhomID AS LopID,
        n.TenNhom AS TenLop,
        tbdct.Semester
    FROM dbo.tblKetQuaHocTap tkqht
        INNER JOIN dbo.tblHocSinh ths ON tkqht.HocSinhID = ths.HocSinhID
        INNER JOIN dbo.tblNhom n ON tkqht.LopID = n.NhomID
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
        INNER JOIN dbo.tblMonHoc tmh ON tmhl.MonHocID = tmh.MonHocID
        INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
    WHERE 
        n.KhoiID = @KhoiID
        AND tmh.MonHocID = 76
        AND tkqht.LopID = @LopID
        AND ths.HocSinhID = @HocSinhID
		AND tkqht.NienKhoa = @NienKhoa
        AND tbdct.MaCotDiem like '%IELTS%'
         AND tbdct.MaCotDiem like '%_Conv%'
        AND tkqht.Enable = 1
    ORDER BY ThuTuNhom, ThuTuCotDiem, MaNhomCotDiem, MaCotDiem;

END;
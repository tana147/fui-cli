CREATE PROCEDURE [dbo].[spAPI_BangDiemHocKyHocSinh_Get]
    @HocSinhID NVARCHAR(50),
    @Semester NVARCHAR(10),
    @NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        tkqht.HocSinhID,
        tbdct.TenCotDiem_VI,
        tbdct.TenNhomCotDiem_VI,
        ths.Ho,
        ths.Ten,
        ths.Ho + ' ' + ths.Ten AS HoTen,
        tmh.MonHocID,
        tmh.TenMonDuLieuNganh,
        tkqht.KetQuaDanhGia_VI,
        tbdct.CotDiemID,
        tbdct.MaNhomCotDiem,
     	tbdct.ThuTuNhom,
		tbdct.ThuTuCotDiem
    FROM dbo.tblKetQuaHocTap tkqht
    INNER JOIN dbo.tblMonHocLop tmhl ON tkqht.MonHocLopID = tmhl.MonHocLopID
    INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
    INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
    INNER JOIN dbo.tblHocSinh ths ON ths.HocSinhID = tkqht.HocSinhID
    WHERE tkqht.HocSinhID = @HocSinhID
      AND tbdct.Semester = @Semester
      AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR tmhl.NienKhoa = @NienKhoa)
    ORDER BY 
    tbdct.ThuTuNhom,
    tbdct.ThuTuCotDiem
END;
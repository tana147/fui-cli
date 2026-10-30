CREATE PROC [dbo].[spAPI_gv_TA_MaNhomDiem_Get_By_HocSinhID] --'21000224',2025
    @HocSinhID INT,
	@NienKhoa INT
AS
BEGIN
    SELECT kqht.MonHocLopID
         , kqht.HocSinhID
         , tbdct.ThuTuNhom
         , tbdct.MaNhomCotDiem
         , tbdct.TenNhomCotDiem_VI
         , tbdct.TenNhomCotDiem_EN
         , kqht.NienKhoa
         --, ltt.Lop_TinhTrangID
    FROM dbo.tblKetQuaHocTap AS kqht

        INNER JOIN dbo.TemplateBangDiemChiTiet AS tbdct
            ON  tbdct.CotDiemID = kqht.CotDiemID
            AND tbdct.Enable    = 1

        INNER JOIN dbo.tblMonHocLop AS mhl
            ON  mhl.MonHocLopID = kqht.MonHocLopID
            AND mhl.MonHocID    IN (5, 46, 76)
            AND mhl.Enable      = 1

        -- ✅ Chỉ hiển thị khi cột điểm của lớp học sinh đã bị KHÓA
        INNER JOIN dbo.tblKhoaCotDiem AS kcd
            ON  kcd.KhoaCotDiemID = kqht.KhoaCotDiemID
            AND kcd.LopID         = kqht.LopID   -- đúng lớp của học sinh
            AND kcd.Enable        = 1
    WHERE kqht.HocSinhID = @HocSinhID
      AND kqht.Enable    = 1
      AND kqht.NienKhoa  = @NienKhoa

    GROUP BY kqht.MonHocLopID
           , kqht.HocSinhID
           , tbdct.ThuTuNhom
           , tbdct.MaNhomCotDiem
           , tbdct.TenNhomCotDiem_VI
           , tbdct.TenNhomCotDiem_EN
           , kqht.NienKhoa

    ORDER BY tbdct.ThuTuNhom;
END;
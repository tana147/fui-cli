CREATE PROC [dbo].[spAPI_PH_TA_CotDiem_Get_By_HocSinhID_MaNhomCotDiem]
    @NienKhoa INT,
    @HocSinhID INT,
    @MaNhomCotDiem NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ trả điểm khi đúng lớp/môn/nhóm đã từng duyệt/công bố PH (TinhTrang = 8), kể cả mở URL trực tiếp.
    -- MonHocLopID được ràng buộc niên khóa; đọc lịch sử thay vì trạng thái hiện tại/Enable
    -- để nhóm đã công bố vẫn hiển thị điểm hiện tại sau khi giáo viên lưu chỉnh sửa.
    SELECT kqht.HocSinhID,
           tbdct.ThuTuNhom,
           tbdct.MaNhomCotDiem,
           tbdct.TenNhomCotDiem_EN,
           tbdct.TenNhomCotDiem_VI,
           tbdct.ThuTuCotDiem,
           tbdct.MaCotDiem,
           tbdct.TenCotDiem_VI,
           tbdct.TenCotDiem_EN,
           kqht.KetQuaDanhGia_VI,
           kqht.KetQuaDanhGia_EN,
           tbdct.DiemMin,
           tbdct.DiemMax,
           tbdct.LamTronBaoNhieuSo,
           tbdct.LoaiCotDiem,
           tbdct.GiaTriCotDiem,
           tbdct.HexBackground,
           tbdct.CssClass
    FROM dbo.tblKetQuaHocTap AS kqht
    INNER JOIN dbo.TemplateBangDiemChiTiet AS tbdct
        ON tbdct.CotDiemID = kqht.CotDiemID
       AND tbdct.MaNhomCotDiem = @MaNhomCotDiem
       AND tbdct.IsVisibleToParents = 1
       AND tbdct.Enable = 1
       AND tbdct.MaCotDiem NOT IN
       (
           'DanhHieu_HK1',
           'DiemTBCK_HK1',
           'DanhHieu_HK2',
           'DiemTBCK_HK2'
       )
    INNER JOIN dbo.tblLop AS l
        ON l.LopID = kqht.LopID
       AND l.NienKhoa = @NienKhoa
       AND l.Enable = 1
    INNER JOIN dbo.tblMonHocLop AS mhl
        ON mhl.MonHocLopID = kqht.MonHocLopID
       AND mhl.LopNhomID = kqht.LopID
       AND mhl.Enable = 1
       AND mhl.NienKhoa = @NienKhoa
       AND mhl.MonHocID IN (5, 46, 76)
    INNER JOIN dbo.tblMonHoc AS mh
        ON mh.MonHocID = mhl.MonHocID
       AND mh.CapID = 1
    WHERE kqht.HocSinhID = @HocSinhID
      AND kqht.NienKhoa = @NienKhoa
      AND kqht.Enable = 1
      AND (kqht.KetQuaDanhGia_VI IS NOT NULL OR kqht.KetQuaDanhGia_EN IS NOT NULL)
      AND EXISTS
      (
          SELECT 1
          FROM dbo.tblLop_TinhTrang AS published
          WHERE published.LopID = kqht.LopID
            AND published.MonHocLopID = kqht.MonHocLopID
            AND published.MaNhomCotDiem = tbdct.MaNhomCotDiem
            AND published.TinhTrang = 8
      )
    ORDER BY tbdct.ThuTuNhom,
             tbdct.ThuTuCotDiem;
END;

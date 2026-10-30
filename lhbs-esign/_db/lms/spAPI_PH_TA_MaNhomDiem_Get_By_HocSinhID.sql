CREATE PROC [dbo].[spAPI_PH_TA_MaNhomDiem_Get_By_HocSinhID]
    @HocSinhID INT,
    @NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Cấp 1: chỉ hiện nhóm đã từng duyệt/công bố PH (TinhTrang = 8).
    -- Tra lịch sử theo đúng lớp/môn/nhóm; MonHocLopID được ràng buộc niên khóa bên dưới.
    -- Không dựa vào trạng thái hiện tại hay Enable của lịch sử vì lưu điểm lại có thể chuyển về nháp.
    SELECT kqht.MonHocLopID,
           kqht.HocSinhID,
           tbdct.ThuTuNhom,
           tbdct.MaNhomCotDiem,
           tbdct.TenNhomCotDiem_VI,
           tbdct.TenNhomCotDiem_EN,
           kqht.NienKhoa
    FROM dbo.tblKetQuaHocTap AS kqht
    INNER JOIN dbo.TemplateBangDiemChiTiet AS tbdct
        ON tbdct.CotDiemID = kqht.CotDiemID
       AND tbdct.Enable = 1
    INNER JOIN dbo.tblLop AS l
        ON l.LopID = kqht.LopID
       AND l.NienKhoa = @NienKhoa
       AND l.Enable = 1
    INNER JOIN dbo.tblMonHocLop AS mhl
        ON mhl.MonHocLopID = kqht.MonHocLopID
       AND mhl.LopNhomID = kqht.LopID
       AND mhl.MonHocID IN (5, 46, 76)
       AND mhl.NienKhoa = @NienKhoa
       AND mhl.Enable = 1
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
    GROUP BY kqht.MonHocLopID,
             kqht.HocSinhID,
             tbdct.ThuTuNhom,
             tbdct.MaNhomCotDiem,
             tbdct.TenNhomCotDiem_VI,
             tbdct.TenNhomCotDiem_EN,
             kqht.NienKhoa

    UNION

    -- Cấp 2–3 giữ nguyên quy tắc phụ huynh chỉ thấy nhóm đã khóa cột điểm.
    SELECT kqht.MonHocLopID,
           kqht.HocSinhID,
           tbdct.ThuTuNhom,
           tbdct.MaNhomCotDiem,
           tbdct.TenNhomCotDiem_VI,
           tbdct.TenNhomCotDiem_EN,
           kqht.NienKhoa
    FROM dbo.tblKetQuaHocTap AS kqht
    INNER JOIN dbo.TemplateBangDiemChiTiet AS tbdct
        ON tbdct.CotDiemID = kqht.CotDiemID
       AND tbdct.Enable = 1
    INNER JOIN dbo.tblLop AS l
        ON l.LopID = kqht.LopID
       AND l.NienKhoa = @NienKhoa
       AND l.Enable = 1
    INNER JOIN dbo.tblMonHocLop AS mhl
        ON mhl.MonHocLopID = kqht.MonHocLopID
       AND mhl.MonHocID IN (5, 46, 76)
       AND mhl.NienKhoa = @NienKhoa
       AND mhl.Enable = 1
    INNER JOIN dbo.tblMonHoc AS mh
        ON mh.MonHocID = mhl.MonHocID
       AND mh.CapID IN (2, 3)
    WHERE kqht.HocSinhID = @HocSinhID
      AND kqht.Enable = 1
      AND kqht.NienKhoa = @NienKhoa
      AND EXISTS
      (
          SELECT 1
          FROM dbo.tblKhoaCotDiem AS kcd
          WHERE kcd.KhoaCotDiemID = kqht.KhoaCotDiemID
            AND kcd.LopID = kqht.LopID
            AND kcd.Enable = 1
            AND kcd.TinhTrang = 1
      )
    GROUP BY kqht.MonHocLopID,
             kqht.HocSinhID,
             tbdct.ThuTuNhom,
             tbdct.MaNhomCotDiem,
             tbdct.TenNhomCotDiem_VI,
             tbdct.TenNhomCotDiem_EN,
             kqht.NienKhoa
    ORDER BY ThuTuNhom;
END;

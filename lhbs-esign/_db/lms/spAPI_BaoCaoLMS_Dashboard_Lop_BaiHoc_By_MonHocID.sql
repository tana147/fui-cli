-- [dbo].[spAPI_BaoCaoLMS_Dashboard_Lop_BaiHoc_By_MonHocID] 56, 2025
CREATE PROC [dbo].[spAPI_BaoCaoLMS_Dashboard_Lop_BaiHoc_By_MonHocID]
    @MonHocID INT,
    @NienKhoa INT
AS
BEGIN
SELECT 
      ls.KhoiID
    , ls.LessonID
    , ls.Title
    , l.TenLop
    , l.LopID
	, atc.AssignToClassID
    -- Tổng học sinh của lớp
    , SoLuongHocSinh = (
        SELECT COUNT(*) 
        FROM dbo.tblHocSinhLop 
        WHERE LopID = l.LopID AND Enable = 1 AND NienKhoa = @NienKhoa
      )

    , atc.CreateUser AS NguoiGiao

    -- Hoàn thành
    , SoHocSinh_HoanThanh = COUNT(DISTINCT CASE WHEN lp.IsCompleted = 1 THEN lp.HocSinhID END)

    -- Chưa hoàn thành
    , SoHocSinh_ChuaHoanThanh = COUNT(DISTINCT CASE WHEN lp.IsCompleted = 0 THEN lp.HocSinhID END)

    -- Chưa học
    , SoHocSinh_ChuaHoc = (
          SELECT COUNT(*) 
          FROM dbo.tblHocSinhLop h2
          WHERE h2.LopID = l.LopID
                AND h2.Enable = 1
                AND h2.NienKhoa = @NienKhoa
                AND h2.HocSinhID NOT IN (
                        SELECT lp2.HocSinhID
                        FROM dbo.tblEL_Learning_Progress lp2
                        WHERE lp2.LessonID = ls.LessonID
                              AND lp2.IsDeleted = 0
                )
      )

    , gv.HoGV + ' ' + gv.TenGV AS HoTenNguoiGiao

    , N'Tuần ' + CAST(th.Tuan AS VARCHAR(2)) 
        + N' - Tháng ' + CAST(th.ThangHoc as varchar(2))
        + N' - (' + FORMAT(th.NgayBatDau ,'dd/MM/yyyy')
        + N' - ' + FORMAT(th.NgayKetThuc,'dd/MM/yyyy') + ')'  AS Tuan_HienThi

FROM dbo.tblEL_Learning_Progress lp

JOIN dbo.tblEL_Lessons ls 
        ON ls.LessonID = lp.LessonID
       AND ls.IsDeleted = 0
       AND ls.NienKhoa = @NienKhoa
       AND ls.MonHocID = @MonHocID

-- Mapping Môn – Lớp
JOIN dbo.tblHocSinhLop hsl 
        ON hsl.HocSinhID = lp.HocSinhID
       AND hsl.NienKhoa  = @NienKhoa
       AND hsl.Enable    = 1

JOIN dbo.tblLop l 
        ON l.LopID     = hsl.LopID
       AND l.NienKhoa  = @NienKhoa 
       AND l.Enable    = 1

JOIN dbo.tblMonHocLop mhl
        ON mhl.LopNhomID = l.LopID
       AND mhl.MonHocID = ls.MonHocID
       AND mhl.NienKhoa = @NienKhoa
       AND mhl.Enable = 1

-- JOIN ĐÚNG: theo MonHocLopID → mỗi lớp chỉ 1 dòng AssignToClass
JOIN dbo.tblEL_AssignToClass atc 
        ON atc.ResourceType = 'LESSON'
       AND atc.ResourceID = ls.LessonID
       AND atc.MonHocLopID = mhl.MonHocLopID
       AND atc.IsDeleted = 0

LEFT JOIN dbo.tblGiaoVien gv 
        ON gv.GiaoVienID = atc.CreateUser

JOIN dbo.tblTuanHocTap th 
        ON th.TuanHocID = ls.TuanHocID

WHERE lp.IsDeleted = 0

GROUP BY 
      ls.KhoiID
    , ls.LessonID
    , ls.Title
    , l.TenLop
    , l.LopID
	, atc.AssignToClassID
    , atc.CreateUser
    , gv.HoGV + ' ' + gv.TenGV
    , N'Tuần ' + CAST(th.Tuan AS VARCHAR(2)) 
        + N' - Tháng ' + CAST(th.ThangHoc as varchar(2))
        + N' - (' + FORMAT(th.NgayBatDau ,'dd/MM/yyyy')
        + N' - ' + FORMAT(th.NgayKetThuc,'dd/MM/yyyy') + ')'

ORDER BY ls.KhoiID;


END; 
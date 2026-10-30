
CREATE PROCEDURE [dbo].[spAPI_TienDo_GiaoBai] 
	@NienKhoa INT = NULL,
	@KhoiID INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	SELECT 
    GiaoVienID,
    HoTen,
    TenMonHoc_HienThi,
    MonHocID,
    SUM(SoLuongBaiTap) AS SoLuongBaiTap,
    SUM(SoLuongBaiHoc) AS SoLuongBaiHoc
FROM (
    -- Bài tập
    SELECT 
        gv.GiaoVienID,
        CONCAT(gv.HoGV,' ', gv.TenGV) AS HoTen,
        mh.TenMonHoc_HienThi,
         mh.MonHocID,
        COUNT(asm.AssignmentID) AS SoLuongBaiTap,
        0 AS SoLuongBaiHoc
    FROM tblEL_Assignments asm
    INNER JOIN tblMonHoc mh ON mh.MonHocID = asm.MonHocID
    INNER JOIN tblGiaoVien gv ON gv.GiaoVienID = asm.CreateUser
    WHERE asm.KhoiID = @KhoiID 
      AND asm.NienKhoa = @NienKhoa
      AND asm.IsDeleted = 0
      AND asm.IsDev is null
    GROUP BY 
        gv.GiaoVienID,
        gv.HoGV,
        gv.TenGV,
        mh.TenMonHoc_HienThi,
        mh.MonHocID

    UNION ALL

    -- Bài học
    SELECT 
        gv.GiaoVienID,
        CONCAT(gv.HoGV,' ', gv.TenGV) AS HoTen,
        mh.TenMonHoc_HienThi,
         mh.MonHocID,
        0 AS SoLuongBaiTap,
        COUNT(l.LessonID) AS SoLuongBaiHoc
    FROM tblEL_Lessons l
    INNER JOIN tblMonHoc mh ON mh.MonHocID = l.MonHocID
    INNER JOIN tblGiaoVien gv ON gv.GiaoVienID = l.CreateUser
    WHERE l.KhoiID = @KhoiID 
      AND l.NienKhoa = @NienKhoa
        AND l.IsDeleted = 0
        AND l.IsDev is null
    GROUP BY 
        gv.GiaoVienID,
        gv.HoGV,
        gv.TenGV,
        mh.TenMonHoc_HienThi,
        mh.MonHocID
) t
GROUP BY 
    GiaoVienID,
    HoTen,
    TenMonHoc_HienThi,
    MonHocID;
END

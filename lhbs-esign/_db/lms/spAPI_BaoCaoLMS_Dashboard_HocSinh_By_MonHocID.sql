--spAPI_BaoCaoLMS_Dashboard_HocSinh_By_MonHocID 46, 2025

CREATE PROC spAPI_BaoCaoLMS_Dashboard_HocSinh_By_MonHocID
    @MonHocID INT
  , @NienKhoa INT
AS
BEGIN
    SELECT asm.KhoiID
         , ats.HocSinhID
         , asm.MonHocID
         , asm.Title
         , ats.AssignToStudentID
         , ats.CreateUser                                                                                                                                                                                AS NguoiGiao
         , gv.HoGV + ' ' + gv.TenGV                                                                                                                                                                      AS HoTenNguoiGiao
         , ats.CreateTime                                                                                                                                                                                AS ThoiGianTao
         , N'Tuần ' + CAST(th.Tuan AS VARCHAR(2)) + N' - Tháng ' + CAST(th.ThangHoc AS VARCHAR(2)) + N' - (' + FORMAT(th.NgayBatDau, 'dd/MM/yyyy') + N' - ' + FORMAT(th.NgayKetThuc, 'dd/MM/yyyy') + ')' AS Tuan_HienThi
         , ats.MaxScore
    FROM
           dbo.tblEL_AssignToStudent        ats
           INNER JOIN dbo.tblEL_Assignments asm ON asm.AssignmentID = ats.AssignmentID
                                               --AND ISNULL(asm.IsDev, 0) <> 1
                                               AND asm.MonHocID     = @MonHocID
           INNER JOIN dbo.tblTuanHocTap     th ON th.TuanHocID      = asm.TuanHocID
           INNER JOIN dbo.tblHocSinh        hs ON hs.HocSinhID      = ats.HocSinhID
                                              AND hs.TinhTrang      = 0
           INNER JOIN dbo.tblGiaoVien       gv ON gv.GiaoVienID     = ats.CreateUser
    WHERE
           ats.IsDeleted = 0;
END;
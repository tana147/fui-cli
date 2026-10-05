CREATE PROC [dbo].[spAPI_Student_Export_ThongTinUngVien_TS]
@NienKhoa VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ROW_NUMBER() OVER (ORDER BY si.LopID, si.StudentID) AS Stt,
        si.StudentID,
        si.MaHoSo,
        si.HoSV AS Ho,
        si.TenSV AS Ten,
        si.GioiTinh AS Phai,
        si.NgaySinh,
        si.NoiSinh,
        si.DanToc,
        si.QuocTich,
        si.TenNganh AS ChuyenNganh,
        si.Truong_DaiHoc,
        si.Nganh_DaiHoc,
        si.ThoiGianTotNghiep_DaiHoc AS NamTotNghiep_DH,
        si.XepLoai AS LoaiTotNghiep_DH,
        si.HeDaoTao_DaiHoc AS HeDaoTao_DH,
        si.Truong_ThacSi,
        si.Nganh_ThacSi,
        si.HeDaoTao_ThacSi AS HeDaoTao_ThS,
        si.ThoiGianTotNghiep_ThacSi AS NamTotNghiep_ThS,
        si.NgheNghiep,
        si.NoiLamViec,
        si.DiaChi,
        si.Email,
        si.SoDienThoai,
        si.CCCD,
        CASE 
            WHEN fd_ksk.File_URL IS NOT NULL OR fd_ksk.Text_Content IS NOT NULL OR fd_ksk.Flow_Detail_Status = 'C' THEN N'Có'
            ELSE N'Không'
        END AS GiayKhamSucKhoe,
        COALESCE(NULLIF(fd_gt2.Text_Content, ''), NULLIF(fd_gt1.Text_Content, ''), NULLIF(fd_gt2.File_Name, ''), NULLIF(fd_gt1.File_Name, ''), '') AS NguoiGioiThieu,
        COALESCE(NULLIF(fd_prof1.Text_Content, ''), '') AS DeXuatGVHD,
        COALESCE(NULLIF(fd_thesis.Text_Content, ''), NULLIF(fd_bl.Text_Content, ''), NULLIF(fd_bl.File_Name, ''), '') AS TenBaiLuan,
        COALESCE(NULLIF(fd_bb.Text_Content, ''), NULLIF(fd_bb.File_Name, ''), '') AS BaiBaoKhoaHoc_1,
        '' AS BaiBaoKhoaHoc_2,
        si.NgoaiNgu_DauVao,
        si.BoSungKienThuc
    FROM StudentInfo si
    LEFT JOIN Flow f40 ON f40.Student_ID = si.StudentID AND f40.Task_ID = 40 AND f40.use_yn = 1
    LEFT JOIN Flow_Detail fd_ksk ON fd_ksk.Flow_ID = f40.Flow_ID AND fd_ksk.Task_Detail_ID = 264 AND fd_ksk.use_yn = 1
    LEFT JOIN Flow_Detail fd_gt1 ON fd_gt1.Flow_ID = f40.Flow_ID AND fd_gt1.Task_Detail_ID = 262 AND fd_gt1.use_yn = 1
    LEFT JOIN Flow_Detail fd_gt2 ON fd_gt2.Flow_ID = f40.Flow_ID AND fd_gt2.Task_Detail_ID = 265 AND fd_gt2.use_yn = 1
    LEFT JOIN Flow_Detail fd_bl ON fd_bl.Flow_ID = f40.Flow_ID AND fd_bl.Task_Detail_ID = 270 AND fd_bl.use_yn = 1
    LEFT JOIN Flow_Detail fd_bb ON fd_bb.Flow_ID = f40.Flow_ID AND fd_bb.Task_Detail_ID = 271 AND fd_bb.use_yn = 1
    LEFT JOIN Flow f41 ON f41.Student_ID = si.StudentID AND f41.Task_ID = 41 AND f41.use_yn = 1
    LEFT JOIN Flow_Detail fd_thesis ON fd_thesis.Flow_ID = f41.Flow_ID AND fd_thesis.Task_Detail_ID = 279 AND fd_thesis.use_yn = 1
    LEFT JOIN Flow_Detail fd_prof1 ON fd_prof1.Flow_ID = f41.Flow_ID AND fd_prof1.Task_Detail_ID = 280 AND fd_prof1.use_yn = 1
    WHERE (@NienKhoa = '0' OR @NienKhoa IS NULL OR si.NienKhoa = @NienKhoa)
      AND (si.HeDaoTao = 'Phd' OR SUBSTRING(si.LopID, 3, 1) = 'N' OR si.NganhID IN ('43', '44'))
    ORDER BY si.LopID, si.StudentID;
END

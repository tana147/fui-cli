--  [dbo].[spAPI_HocSinhBangDiem_Get_ByMonHocID_MaNhom] 2376, 46, 48, 'DiemCK_HK1', '',0

-- [spAPI_HocSinhBangDiem_Get_By_KhoiID_MonHocID] 6, 0, 46,  '',0
CREATE PROC [dbo].[spAPI_HocSinhBangDiem_Get_By_KhoiID_MonHocID]
    --@LopID              VARCHAR(10)
    @KhoiID             INT
  , @TemplateBangDiemID INT
  , @NienKhoa           INT
  , @Semester           NVARCHAR(10)
  , @IncludeGroups      BIT
  , @SYS_USERID         VARCHAR(9)
  , @Sys_GroupID        INT
AS
BEGIN
    SELECT HS.[HocSinhID]
         , HSL.SoDanhBo
         , l.TenLop
         , NhomMonHoc.TenNhom AS TenLopNhom
         , HS.[Ho]
         , HS.[Ten]
         , HS.Ho + ' ' + HS.Ten    AS HoTen
         , HS.[NgaySinh]
         , HS.[Nu]
         , BD.CotDiemID            AS CotDiemID
         , BD.MaCotDiem
         , BD.LoaiCotDiem
         , BD.GiaTriCotDiem        AS GiaTriCotDiem
         , BD.KieuDanhGiaID
         , BD.TenCotDiem_VI
         , BD.TenCotDiem_EN
         , BD.ThuTuCotDiem
         , BD.MaNhomCotDiem
         , BD.TenNhomCotDiem_VI
         , BD.TenNhomCotDiem_EN
         , KQ.KetQuaDanhGia_VI
         , KQ.KetQuaDanhGia_EN
         , BD.HexBackground
         , BD.Formula
         , BD.DiemMin
         , BD.DiemMax
         , BD.QuyenNhapDiem
         , BD.WidthCSS
         , ISNULL(KQ.TinhTrang, 0) AS TinhTrang
		 , CAST(ISNULL(KCD.TinhTrang, 0) AS BIT) AS KhoaDiemTinhTrang
		 , TenHienThi_VI
		 , TenHienThi_EN
    FROM
           dbo.tblHocSinh                         HS
           INNER JOIN dbo.tblLop                  AS l ON l.KhoiID              = @KhoiID
                                                      AND l.NienKhoa            = @NienKhoa
           INNER JOIN dbo.tblHocSinhLop           HSL ON HS.HocSinhID           = HSL.HocSinhID
                                                     AND HSL.LopID              = CAST(l.LopID AS VARCHAR(20))
           INNER JOIN dbo.tblMonHocLop            MHL ON MHL.TemplateBangDiemID = @TemplateBangDiemID
                                                     AND MHL.NienKhoa           = @NienKhoa
                                                     AND MHL.Enable             = 1
                                                     AND
                                                     (
                                                         MHL.LopNhomID = HSL.LopID
                                                         OR
                                                         (
                                                             @IncludeGroups = 1
                                                             AND EXISTS
                                                             (
                                                                 -- Nhóm môn học phải mở rộng về đúng học sinh; l.TenLop/HSL.SoDanhBo vẫn là lớp gốc.
                                                                 SELECT 1
                                                                 FROM dbo.tblNhom AS N
                                                                 INNER JOIN dbo.tblHocSinhNhom AS HSN
                                                                     ON HSN.HocSinhID = HS.HocSinhID
                                                                    AND HSN.Enable = 1
                                                                    AND
                                                                    (
                                                                        (@Semester LIKE '%HK1%' AND (HSN.NhomID_HK1 = N.NhomID OR (HSN.NhomID_HK1 IS NULL AND HSN.NhomID = N.NhomID)))
                                                                        OR (@Semester LIKE '%HK2%' AND HSN.NhomID = N.NhomID)
                                                                        OR (@Semester = 'CaNam' AND (HSN.NhomID = N.NhomID OR HSN.NhomID_HK1 = N.NhomID))
                                                                    )
                                                                 WHERE N.NhomID = MHL.LopNhomID
                                                                   AND N.KhoiID = @KhoiID
                                                                   AND N.NienKhoa = @NienKhoa
                                                                   AND N.Enable = 1
                                                                   AND N.IsNhomLMS_GiaoBai = 0
                                                             )
                                                         )
                                                     )
           -- Lớp nhóm lấy từ MHL; học sinh vẫn được lọc theo phân lớp nhóm của học kỳ đã chọn.
           LEFT JOIN dbo.tblNhom AS NhomMonHoc
               ON NhomMonHoc.NhomID = MHL.LopNhomID
              AND NhomMonHoc.KhoiID = @KhoiID
              AND NhomMonHoc.NienKhoa = @NienKhoa
              AND NhomMonHoc.Enable = 1
              AND NhomMonHoc.IsNhomLMS_GiaoBai = 0
           -- Template ngoại ngữ có nhiều cột kỹ năng; nếu có mapping điểm chuẩn thì chỉ trả điểm tổng hợp đã khai báo trong IDHeThong.
           OUTER APPLY (
               SELECT TOP (1) 1 AS HasCanonicalMarks
               FROM dbo.TemplateBangDiemChiTiet MapBD
               WHERE MapBD.TemplateBangDiemID = MHL.TemplateBangDiemID
                 AND MapBD.Enable = 1
                 AND (
                     MapBD.Semester = @Semester
                     OR (
                         @Semester IN ('GK_HK1', 'CK_HK1', 'GK_HK2', 'CK_HK2')
                         AND MapBD.MaCotDiem LIKE '%' + @Semester
                     )
                     OR (
                         NULLIF(LTRIM(RTRIM(MapBD.Semester)), '') IS NULL
                         AND MapBD.MaCotDiem LIKE '%' + @Semester
                     )
                 )
                 AND (
                     MapBD.IDHeThong LIKE 'TX[_]L[1-4][_]%'
                     OR MapBD.IDHeThong LIKE 'DiemGK[_]%'
                     OR MapBD.IDHeThong LIKE 'DiemCK[_]%'
                     OR MapBD.IDHeThong LIKE 'DiemTB[_]%'
                 )
           ) CanonicalMarks
           INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID   = MHL.TemplateBangDiemID
                                                    AND BD.Enable               = 1
                                                    AND
                                                    (
                                                        (
                                                            CanonicalMarks.HasCanonicalMarks = 1
                                                            AND (
                                                                BD.IDHeThong LIKE 'TX[_]L[1-4][_]%'
                                                                OR BD.IDHeThong LIKE 'DiemGK[_]%'
                                                                OR BD.IDHeThong LIKE 'DiemCK[_]%'
                                                                OR BD.IDHeThong LIKE 'DiemTB[_]%'
                                                            )
                                                            AND (
                                                                BD.Semester = @Semester
                                                                OR (
                                                                    @Semester IN ('GK_HK1', 'CK_HK1', 'GK_HK2', 'CK_HK2')
                                                                    AND BD.MaCotDiem LIKE '%' + @Semester
                                                                )
                                                                OR (
                                                                    NULLIF(LTRIM(RTRIM(BD.Semester)), '') IS NULL
                                                                    AND BD.MaCotDiem LIKE '%' + @Semester
                                                                )
                                                            )
                                                        )
                                                        OR (
                                                            CanonicalMarks.HasCanonicalMarks IS NULL
                                                            AND (
                                                                -- Template thường không có mapping hệ thống nên giữ toàn bộ cột thuộc học kỳ đã chọn.
                                                                BD.Semester = @Semester
                                                                OR (
                                                                    @Semester IN ('GK_HK1', 'CK_HK1', 'GK_HK2', 'CK_HK2')
                                                                    AND BD.MaCotDiem LIKE '%' + @Semester
                                                                )
                                                                OR (
                                                                    NULLIF(LTRIM(RTRIM(BD.Semester)), '') IS NULL
                                                                    AND BD.MaCotDiem LIKE '%' + @Semester
                                                                )
                                                            )
                                                        )
                                                    )
           LEFT JOIN dbo.tblKetQuaHocTap          KQ ON KQ.HocSinhID            = HS.HocSinhID
                                                    AND KQ.CotDiemID            = BD.CotDiemID
                                                    AND KQ.MonHocLopID          = MHL.MonHocLopID
                                                    AND KQ.Enable               = 1
           -- Trạng thái khóa áp dụng theo đúng lớp, môn học và cột điểm của từng học sinh.
           OUTER APPLY (
               SELECT TOP 1 k.TinhTrang
               FROM dbo.tblKhoaCotDiem k
               WHERE k.MaCotDiem = BD.MaCotDiem
                 AND k.MonHocLopID = MHL.MonHocLopID
                 AND k.LopID = MHL.LopNhomID
                 AND k.Enable = 1
               ORDER BY ISNULL(k.UpdateTime, k.CreateTime) DESC, k.KhoaCotDiemID DESC
           ) KCD
    WHERE
           HS.TinhTrang = 0
      AND  HSL.Enable    = 1
    ORDER BY
           l.TenLop
         , HSL.SoDanhBo
         , BD.ThuTuNhom
         , BD.ThuTuCotDiem;
END;

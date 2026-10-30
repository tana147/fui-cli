--  [dbo].[spAPI_HocSinhBangDiem_Get_ByMonHocID_MaNhom] 2362, 46, 48, 'DiemCK_HK1', '',0

-- [spAPI_HocSinhBangDiem_TT_BGH_Get] 2362, 'HK1', 'NA0000022',9
CREATE PROC [dbo].[spAPI_HocSinhBangDiem_TT_BGH_Get_xLUAN]
    @LopID       VARCHAR(10)
  , @Semester    VARCHAR(3)
  , @SYS_USERID  VARCHAR(9)
  , @Sys_GroupID INT
AS
BEGIN

    DECLARE @LopNhomID VARCHAR(10);
    SET @LopNhomID = @LopID;
    -- Truy vấn tối ưu sử dụng LEFT JOIN
    -- Truy vấn khi LopID là số
    -- Kiểm tra loại LopID (số hay chuỗi)
    DECLARE @IsNumber BIT = CASE WHEN ISNUMERIC(@LopID) = 1 THEN 1 ELSE 0 END;
    IF @IsNumber = 1
    BEGIN
        SELECT 
				HS.[HocSinhID]
             , HSL.SoDanhBo
             , HS.[Ho]
             , HS.[Ten]
             , HS.[NgaySinh]
             , HS.[Nu]
             , HS.Ho + ' ' + HS.Ten                                                       AS HoTen
             , BD.CotDiemID                                                               AS CotDiemID
             , BD.MaCotDiem
             , BD.LoaiCotDiem
             , BD.GiaTriCotDiem                                                           AS GiaTriCotDiem
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
             , l_tt.Lop_TinhTrangID
             , ISNULL(l_tt.TinhTrang, 0)                                                  AS TinhTrang
             , l_tt.NoiDungNhanXet
             , dbo.RenderTinhTrang(l_tt.TinhTrang)                                        AS TenTinhTrang
             , dbo.RenderColorTinhTrang(l_tt.TinhTrang)                                   AS MauTinhTrang
             , l_tt.Is_GVCN_DaDuyet
             , CASE
                    WHEN KQ.NhapDiemUser = @SYS_USERID THEN CAST(1 AS BIT)
                    ELSE CAST(0 AS BIT)
               END                                                                        AS Is_Comment
             , KQ.NhapDiemUser
             , KQ.MonHocLopID
             , mh.TenMonDuLieuNganh
             , mh.TenMonHoc_HienThi
             , MHL.MonHocID
             , MHL.MonHocLopID
             , mh.Is_MonHoc_BoTro
             , BD.GiaTriCotDiem
             , KQ.NhapDiemUser
             , FORMAT(KQ.NhapDiemTime, 'dd/MM/yyyy HH:mm:ss')                             AS NhapDiemTime
             , dbo.Count_Log_Diem(@LopID, KQ.MonHocLopID, BD.MaNhomCotDiem, KQ.HocSinhID) AS Count_Log_Diem
        FROM
               dbo.tblHocSinh                         HS
               INNER JOIN dbo.tblHocSinhLop           HSL ON HS.HocSinhID             = HSL.HocSinhID
                                                         AND HSL.LopID                = CAST(@LopID AS INT)
               LEFT JOIN dbo.tblMonHocLop             MHL ON MHL.LopNhomID            = HSL.LopID
               LEFT JOIN dbo.tblMonHoc                mh ON mh.MonHocID               = MHL.MonHocID
               INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID     = MHL.TemplateBangDiemID
                                                        AND BD.Semester               = @Semester
                                                        AND BD.Enable                 = 1
               LEFT JOIN dbo.tblKetQuaHocTap          KQ ON KQ.HocSinhID              = HS.HocSinhID
                                                        AND KQ.CotDiemID              = BD.CotDiemID
                                                        AND KQ.MonHocLopID            = MHL.MonHocLopID
                                                        AND KQ.Enable                 = 1
               LEFT JOIN dbo.tblLop_TinhTrang        AS l_tt ON l_tt.Lop_TinhTrangID = KQ.Lop_TinhTrangID
                                                             AND l_tt.Enable          = 1
        WHERE
               HS.TinhTrang = 0
          AND  HSL.Enable    = 1
        ORDER BY
               HSL.SoDanhBo
             , mh.Sort
             , BD.ThuTuNhom
             , BD.ThuTuCotDiem;
    END;
    ELSE
    BEGIN
        -- Truy vấn khi LopID là chuỗi
        SELECT HS.[HocSinhID]
             , HSN.SoTT                                          AS SoDanhBo
             , HS.[Ho]
             , HS.[Ten]
             , HS.[NgaySinh]
             , HS.[Nu]
             , HS.Ho + ' ' + HS.Ten                              AS HoTen
             , BD.CotDiemID                                      AS CotDiemID
             , BD.MaCotDiem
             , BD.LoaiCotDiem
             , BD.GiaTriCotDiem                                  AS GiaTriCotDiem
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
             , ISNULL(KQ.TinhTrang, 0)                           AS TinhTrang
             , dbo.RenderColorTinhTrang(ISNULL(KQ.TinhTrang, 0)) AS MauTinhTrang
             , dbo.RenderTinhTrang(ISNULL(KQ.TinhTrang, 0))      AS TenTinhTrang
             , KQ.GVCN_LyDo_TuChoi_ID
             , KQ.BGH_LyDo_TuChoi_ID
             , KQ.TT_LyDo_TuChoi_ID
             , tc_gvbm.LyDoTuChoi                                AS GVCN_LyDoTuChoi
             , tc_tt.LyDoTuChoi                                  AS TT_LyDoTuChoi
             , tc_bgh.LyDoTuChoi                                 AS BGH_LyDoTuChoi
             , KQ.TuChoi_GuiDiemUser
             , KQ.TuChoi_GuiDiemTime
             , KQ.GuiDiem_BGHUser
             , KQ.GuiDiem_BGHTime
             , KQ.TuChoi_DuyetDiemUser
             , KQ.TuChoi_DuyetDiemTime
             , KQ.DuyetDiemUser
             , KQ.DuyetDiemTime
             , CASE
                    WHEN KQ.NhapDiemUser = @SYS_USERID THEN CAST(1 AS BIT)
                    ELSE CAST(0 AS BIT)
               END                                               AS Is_Comment
             , KQ.NhapDiemUser
             , mh.TenMonDuLieuNganh
             , mh.TenMonHoc_HienThi
             , MHL.MonHocID
             , MHL.MonHocLopID
             , mh.Is_MonHoc_BoTro
        FROM
               dbo.tblHocSinh                         HS
               INNER JOIN dbo.tblHocSinhNhom          HSN ON HS.HocSinhID              = HSN.HocSinhID
                                                         AND HSN.NhomID                = @LopNhomID
               INNER JOIN dbo.tblMonHocLop            MHL ON MHL.LopNhomID             = HSN.NhomID
               INNER JOIN dbo.tblMonHoc               mh ON mh.MonHocID                = MHL.MonHocID
               INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID      = MHL.TemplateBangDiemID
                                                        AND BD.Semester                = @Semester
                                                        AND BD.Enable                  = 1
               LEFT JOIN dbo.tblKetQuaHocTap          KQ ON KQ.HocSinhID               = HS.HocSinhID
                                                        AND KQ.CotDiemID               = BD.CotDiemID
                                                        AND KQ.MonHocLopID             = MHL.MonHocLopID
                                                        AND KQ.Enable                  = 1
               LEFT JOIN dbo.tblTuChoi                tc_gvbm ON tc_gvbm.LyDo_TuChoiID = KQ.GVCN_LyDo_TuChoi_ID
               LEFT JOIN dbo.tblTuChoi                tc_tt ON tc_tt.LyDo_TuChoiID     = KQ.TT_LyDo_TuChoi_ID
               LEFT JOIN dbo.tblTuChoi                tc_bgh ON tc_bgh.LyDo_TuChoiID   = KQ.BGH_LyDo_TuChoi_ID
        WHERE
               HS.TinhTrang = 0
        ORDER BY
               HSN.SoTT
             , BD.ThuTuNhom
             , BD.ThuTuCotDiem;
    END;
END;
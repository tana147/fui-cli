-- [spAPI_HocSinhBangDiem_Get_ByThuTuNhom] '2535', 5, 564, 'HK1',6, 'NA0000022',9
CREATE PROC [dbo].[spAPI_HocSinhBangDiem_Get_ByThuTuNhom] 
    @LopID              VARCHAR(10)
  , @MonHocID           INT
  , @TemplateBangDiemID INT
  , @Semester			VARCHAR(20)
  , @ThuTuNhom			INT
  , @SYS_USERID         VARCHAR(9)
  , @Sys_GroupID        INT
  , @NienKhoa           INT
AS
BEGIN
	
    DECLARE @LopNhomID VARCHAR(10);
    SET @LopNhomID = @LopID;
    -- Thứ tự nhóm thay đổi giữa các niên khóa; xác định loại nhóm từ template đang chọn.
    DECLARE @SelectedMaNhomCotDiem NVARCHAR(50);
    SET @SelectedMaNhomCotDiem = (
        SELECT TOP (1) MaNhomCotDiem
        FROM dbo.TemplateBangDiemChiTiet
        WHERE TemplateBangDiemID = @TemplateBangDiemID
          AND Semester = @Semester
          AND ThuTuNhom = @ThuTuNhom
          AND Enable = 1
        ORDER BY CotDiemID
    );
    -- Truy vấn tối ưu sử dụng LEFT JOIN
    -- Truy vấn khi LopID là số
    -- Kiểm tra loại LopID (số hay chuỗi)
    DECLARE @IsNumber BIT = CASE WHEN ISNUMERIC(@LopID) = 1 THEN 1 ELSE 0 END;
    IF @IsNumber = 1
    BEGIN
        DECLARE @List_MonHoc_NLPC_ID NVARCHAR(200) = N'';
        SELECT @List_MonHoc_NLPC_ID = List_MonHoc_NLPC_ID
        FROM
               dbo.tblMonHoc
        WHERE
               MonHocID = @MonHocID;
        SELECT T.HocSinhID
             , T.SoDanhBo
             , T.Ho
             , T.Ten
             , T.NgaySinh
             , T.Nu
             , T.HoTen
             , T.CotDiemID
             , T.MaCotDiem
             , T.LoaiCotDiem
             , T.GiaTriCotDiem
             , T.KieuDanhGiaID
             , T.TenCotDiem_VI
             , T.TenCotDiem_EN
             , T.ThuTuCotDiem
             , T.ThuTuNhom
             , T.MaNhomCotDiem
             , T.TenNhomCotDiem_VI
             , T.TenNhomCotDiem_EN
             , T.KetQuaDanhGia_VI
             , T.KetQuaDanhGia_EN
             , T.HexBackground
             , T.Formula
             , T.DiemMin
             , T.DiemMax
             , T.QuyenNhapDiem
             , T.TinhTrang
             , T.TenTinhTrang
             , T.MauTinhTrang
             , T.Is_GVCN_DaDuyet
             , T.WidthCSS
             , T.Lop_TinhTrangID
             , T.NoiDungNhanXet
             , T.Is_Comment
             , T.NhapDiemUser
             , T.Is_Edit
             , T.KQHTID
             , T.EnglishName
             , T.MonHocID
			 , t.TenHienThi_VI
			 , t.TenHienThi_EN
        FROM
               (
                   SELECT HS.[HocSinhID]
                        , HSL.SoDanhBo
                        , HS.[Ho]
                        , HS.[Ten]
                        , HS.[NgaySinh]
                        , HS.[Nu]
                        , HS.Ho + ' ' + HS.Ten      AS HoTen
                        , BD.CotDiemID              AS CotDiemID
                        , BD.MaCotDiem
                        , BD.LoaiCotDiem
                        , BD.GiaTriCotDiem          AS GiaTriCotDiem
                        , BD.KieuDanhGiaID
                        , BD.TenCotDiem_VI
                        , BD.TenCotDiem_EN
                        , BD.ThuTuCotDiem
                        , BD.ThuTuNhom
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
                        --, ISNULL(KQ.TinhTrang, 0)                                                  AS TinhTrang
                        , BD.WidthCSS
                        , l_tt.Lop_TinhTrangID
                        , ISNULL(l_tt.TinhTrang, 0) AS TinhTrang
                        , CASE
                               WHEN mh.CapID = 1 THEN dbo.RenderTinhTrang(l_tt.TinhTrang)
                               WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
                          END                       AS TenTinhTrang
                        , CASE
                               WHEN mh.CapID = 1 THEN dbo.RenderColorTinhTrang(l_tt.TinhTrang)
                               WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
                          END                       AS MauTinhTrang
                        , l_tt.Is_GVCN_DaDuyet
                        , l_tt.NoiDungNhanXet
                        , CASE
                               WHEN KQ.NhapDiemUser <> @SYS_USERID THEN CAST(1 AS BIT)
                               ELSE NULL
                          END                       AS Is_Comment
                        , KQ.NhapDiemUser
                        , ISNULL(KQ.Is_Edit, 0)     AS Is_Edit
                        , ISNULL(KQ.KQHTID, 0)      AS KQHTID
                        , HS.EnglishName
                        , mh.MonHocID
                        , mh.Sort
						, BD.TenHienThi_VI
						, BD.TenHienThi_EN
                   FROM
                          dbo.tblHocSinh                         HS
                           INNER JOIN dbo.tblHocSinhLop           HSL ON HS.HocSinhID             = HSL.HocSinhID
                                                                     AND HSL.LopID                = @LopID
                                                                     AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR HSL.NienKhoa = @NienKhoa)
                           INNER JOIN dbo.tblMonHocLop            MHL ON MHL.LopNhomID            = HSL.LopID
                                                                     AND MHL.TemplateBangDiemID   = @TemplateBangDiemID
                                                                     AND MHL.Enable               = 1
                                                                     AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR MHL.NienKhoa = @NienKhoa)
                          INNER JOIN dbo.tblMonHoc               mh ON mh.MonHocID               = MHL.MonHocID
                                                                   AND mh.Enable                 = 1
                          INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID     = MHL.TemplateBangDiemID
                                                                   AND (
																		 (@SelectedMaNhomCotDiem IN (N'DiemGK_HK1', N'DiemGK_HK2') AND BD.Semester = @Semester AND BD.ThuTuNhom <= @ThuTuNhom AND (BD.MaCotDiem like '%GK_HK%' OR BD.MaCotDiem like '%Result'))
																		 OR (@SelectedMaNhomCotDiem IN (N'DiemCK_HK1', N'DiemCK_HK2') AND BD.Semester = @Semester AND BD.ThuTuNhom <= @ThuTuNhom AND (BD.MaCotDiem like '%CK_HK%' OR BD.MaCotDiem like '%Result'))
																		 OR
																		 BD.ThuTuNhom = @ThuTuNhom
																		)
                                                                   AND BD.Enable                 = 1
                          LEFT JOIN dbo.tblKetQuaHocTap          KQ ON KQ.HocSinhID              = HS.HocSinhID
                                                                   AND KQ.CotDiemID              = BD.CotDiemID
                                                                   AND KQ.MonHocLopID            = MHL.MonHocLopID
                                                                   AND KQ.Enable                 = 1
                          LEFT JOIN dbo.tblLop_TinhTrang         AS l_tt ON l_tt.Lop_TinhTrangID = KQ.Lop_TinhTrangID
                                                                        --   AND l_tt.TinhTrang       = 1
                                                                        AND l_tt.Enable          = 1
                   WHERE
                          HS.TinhTrang = 0
                     AND  HSL.Enable    = 1
                   UNION
                   SELECT HS.[HocSinhID]
                        , HSL.SoDanhBo
                        , HS.[Ho]
                        , HS.[Ten]
                        , HS.[NgaySinh]
                        , HS.[Nu]
                        , HS.Ho + ' ' + HS.Ten                                                     AS HoTen
                        , BD.CotDiemID                                                             AS CotDiemID
                        , CAST(BD.CotDiemID AS NVARCHAR(100)) + '_' + BD.MaCotDiem                 AS MaCotDiem
                        , BD.LoaiCotDiem
                        , BD.GiaTriCotDiem                                                         AS GiaTriCotDiem
                        , BD.KieuDanhGiaID
                        , mh.TenMonHoc_HienThi + ' - ' + BD.TenCotDiem_VI                          AS TenCotDiem_VI
                        , BD.TenCotDiem_EN
                        , BD.ThuTuCotDiem
                        , BD.ThuTuNhom
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
                        --, ISNULL(KQ.TinhTrang, 0)                                                  AS TinhTrang
                        , BD.WidthCSS
                        , l_tt.Lop_TinhTrangID
                        , ISNULL(l_tt.TinhTrang, 0)                                                AS TinhTrang
                        , CASE
                               WHEN mh.CapID = 1 THEN dbo.RenderTinhTrang(l_tt.TinhTrang)
                               WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
                          END                                                                      AS TenTinhTrang
                        , CASE
                               WHEN mh.CapID = 1 THEN dbo.RenderColorTinhTrang(l_tt.TinhTrang)
                               WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
                          END                                                                      AS MauTinhTrang
                        , l_tt.Is_GVCN_DaDuyet
                        , l_tt.NoiDungNhanXet
                        , CASE WHEN KQ.NhapDiemUser = @SYS_USERID THEN CAST(1 AS BIT)ELSE NULL END AS Is_Comment
                        , KQ.NhapDiemUser
                        , ISNULL(KQ.Is_Edit, 0)                                                    AS Is_Edit
                        , ISNULL(KQ.KQHTID, 0)                                                     AS KQHTID
                        , HS.EnglishName
                        , mh.MonHocID
                        , mh.Sort
						, BD.TenHienThi_VI
						, BD.TenHienThi_EN
                   FROM
                          dbo.tblHocSinh                         HS
                          INNER JOIN dbo.tblHocSinhLop           HSL ON HS.HocSinhID             = HSL.HocSinhID
                                                                    AND HSL.LopID                = @LopID
                          INNER JOIN dbo.tblMonHocLop            MHL ON MHL.LopNhomID            = HSL.LopID
                                                                    AND MHL.MonHocID IN
                                                                        (
                                                                            SELECT value
                                                                            FROM
                                                                                   STRING_SPLIT(@List_MonHoc_NLPC_ID, ',')
                                                                        )
                                                                    AND MHL.LopNhomID            = @LopID
                                                                    AND MHL.Enable               = 1
                          --AND MHL.TemplateBangDiemID    = @TemplateBangDiemID
                          INNER JOIN dbo.tblMonHoc               mh ON mh.MonHocID               = MHL.MonHocID
                                                                   --AND mh.List_MonHoc_NLPC_ID     = @List_MonHoc_NLPC_ID
                                                                   AND mh.Enable                 = 1
                          INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID     = MHL.TemplateBangDiemID
																		AND (
																		 (@SelectedMaNhomCotDiem IN (N'DiemGK_HK1', N'DiemGK_HK2') AND BD.Semester = @Semester AND BD.ThuTuNhom <= @ThuTuNhom AND (BD.MaCotDiem like '%GK_HK%' OR BD.MaCotDiem like '%Result'))
																		 OR (@SelectedMaNhomCotDiem IN (N'DiemCK_HK1', N'DiemCK_HK2') AND BD.Semester = @Semester AND BD.ThuTuNhom <= @ThuTuNhom AND (BD.MaCotDiem like '%CK_HK%' OR BD.MaCotDiem like '%Result'))
																		 OR
																		 BD.ThuTuNhom = @ThuTuNhom
																		) 
																		AND BD.Enable                 = 1
																   
                          LEFT JOIN dbo.tblKetQuaHocTap          KQ ON KQ.HocSinhID              = HS.HocSinhID
                                                                   AND KQ.CotDiemID              = BD.CotDiemID
                                                                   AND KQ.MonHocLopID            = MHL.MonHocLopID
                                                                   AND KQ.Enable                 = 1
                          LEFT JOIN dbo.tblLop_TinhTrang         AS l_tt ON l_tt.Lop_TinhTrangID = KQ.Lop_TinhTrangID
                                                                        -- AND l_tt.TinhTrang       = 1
                                                                        AND l_tt.Enable          = 1
                   WHERE
                          HS.TinhTrang = 0
                     AND  HSL.Enable    = 1
               ) AS T
        ORDER BY
               T.SoDanhBo
			 , HocSinhID
             , T.Sort
             , T.MonHocID
             , T.ThuTuNhom
             , T.ThuTuCotDiem
    END;
    ELSE
    BEGIN
        -- Truy vấn khi LopID là chuỗi
        SELECT HS.[HocSinhID]
             , HSN.SoTT                                                                 AS SoDanhBo
             , HS.[Ho]
             , HS.[Ten]
             , HS.[NgaySinh]
             , HS.[Nu]
             , HS.Ho + ' ' + HS.Ten                                                     AS HoTen
             , BD.CotDiemID                                                             AS CotDiemID
             , BD.MaCotDiem
             , BD.LoaiCotDiem
             , BD.GiaTriCotDiem                                                         AS GiaTriCotDiem
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
             , ISNULL(KQ.TinhTrang, 0)                                                  AS TinhTrang
             , BD.WidthCSS
             , CASE WHEN KQ.NhapDiemUser = @SYS_USERID THEN CAST(1 AS BIT)ELSE NULL END AS Is_Comment
             , KQ.NhapDiemUser
             , ISNULL(KQ.Is_Edit, 0)                                                    AS Is_Edit
             , ISNULL(KQ.KQHTID, 0)                                                     AS KQHTID
             , HS.EnglishName
             , CASE
                    WHEN mh.CapID = 1 THEN dbo.RenderTinhTrang(l_tt.TinhTrang)
                    WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
               END                                                                      AS TenTinhTrang
             , CASE
                    WHEN mh.CapID = 1 THEN dbo.RenderColorTinhTrang(l_tt.TinhTrang)
                    WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
               END                                                                      AS MauTinhTrang
			   , BD.TenHienThi_VI
				, BD.TenHienThi_EN
        FROM
               dbo.tblHocSinh                         HS
               INNER JOIN dbo.tblHocSinhNhom          HSN ON HS.HocSinhID             = HSN.HocSinhID
                                                         AND HSN.NhomID               = @LopNhomID
														 and hsn.Enable = 1
               INNER JOIN dbo.tblMonHocLop            MHL ON MHL.LopNhomID            = HSN.NhomID
                                                                     AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR MHL.NienKhoa = @NienKhoa)
               INNER JOIN dbo.tblMonHoc               mh ON mh.MonHocID               = MHL.MonHocID
                                                        --AND mh.List_MonHoc_NLPC_ID     = @List_MonHoc_NLPC_ID
                                                        AND mh.Enable                 = 1
                                                        AND MHL.TemplateBangDiemID    = @TemplateBangDiemID
                                                        AND MHL.Enable                = 1
               INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID     = MHL.TemplateBangDiemID
																	AND (
																		 (@SelectedMaNhomCotDiem IN (N'DiemGK_HK1', N'DiemGK_HK2') AND BD.Semester = @Semester AND BD.ThuTuNhom <= @ThuTuNhom AND (BD.MaCotDiem like '%GK_HK%' OR BD.MaCotDiem like '%Result'))
																		 OR (@SelectedMaNhomCotDiem IN (N'DiemCK_HK1', N'DiemCK_HK2') AND BD.Semester = @Semester AND BD.ThuTuNhom <= @ThuTuNhom AND (BD.MaCotDiem like '%CK_HK%' OR BD.MaCotDiem like '%Result'))
																		 
																		 OR
																		 BD.ThuTuNhom = @ThuTuNhom
																		)	
                                                        AND BD.Enable                 = 1
               LEFT JOIN dbo.tblKetQuaHocTap          KQ ON KQ.HocSinhID              = HS.HocSinhID
                                                        AND KQ.CotDiemID              = BD.CotDiemID
                                                        AND KQ.MonHocLopID            = MHL.MonHocLopID
                                                        AND KQ.Enable                 = 1
               LEFT JOIN dbo.tblLop_TinhTrang         AS l_tt ON l_tt.Lop_TinhTrangID = KQ.Lop_TinhTrangID
                                                             -- AND l_tt.TinhTrang       = 1
                                                             AND l_tt.Enable          = 1
        WHERE
               HS.TinhTrang = 0
        ORDER BY
               HSN.SoTT
             , BD.ThuTuNhom
             , BD.ThuTuCotDiem;
    END;
END;

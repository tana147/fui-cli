CREATE PROC [dbo].[spAPI_HocSinhBangDiem_Get_ByMonHocID_MaNhom]
    @LopID              VARCHAR(10)
  , @MonHocID           INT
  , @TemplateBangDiemID INT
  , @MaNhomCotDiem      NVARCHAR(100)
  , @SYS_USERID         VARCHAR(9)
  , @Sys_GroupID        INT
  , @NienKhoa           INT
AS
BEGIN
    -- Điều kiện để lấy học kì tính điểm tbhk 1,2
    DECLARE @Semester VARCHAR(10);
    IF(@MaNhomCotDiem = 'DiemTBCK_HK1')
        SET @Semester = 'HK1'
    ELSE IF(@MaNhomCotDiem = 'DiemTBCK_HK2')
        SET @Semester = 'HK2'
    ELSE
        SET @Semester = ''

    DECLARE @LopNhomID VARCHAR(10) = @LopID;
    DECLARE @IsNumber BIT = CASE WHEN ISNUMERIC(@LopID) = 1 THEN 1 ELSE 0 END;

    IF @IsNumber = 1
    BEGIN
        DECLARE @List_MonHoc_NLPC_ID NVARCHAR(200) = N'';
        SELECT @List_MonHoc_NLPC_ID = List_MonHoc_NLPC_ID
        FROM dbo.tblMonHoc
        WHERE MonHocID = @MonHocID;

        -- Kiểm tra có học sinh nào không có SoDanhBo không
        DECLARE @HasSoDanhBoNull BIT = 0;
        IF EXISTS (
            SELECT TOP 1 1
            FROM dbo.tblHocSinhLop hsl
                 INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID
                                             AND hs.TinhTrang = 0
            WHERE hsl.SoDanhBo IS NULL
              AND hsl.LopID = @LopID
              AND hsl.Enable = 1
              AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR hsl.NienKhoa = @NienKhoa)
        )
        BEGIN
            SET @HasSoDanhBoNull = 1;
        END

        -- Tạo bảng tạm để lưu kết quả
        IF OBJECT_ID('tempdb..#TempResult') IS NOT NULL DROP TABLE #TempResult;
        
        CREATE TABLE #TempResult (
            HocSinhID INT,
            SoDanhBo NVARCHAR(50),
            Ho NVARCHAR(100),
            Ten NVARCHAR(100),
            NgaySinh NVARCHAR(10),
            Nu BIT,
            HoTen NVARCHAR(200),
            CotDiemID INT,
            MaCotDiem NVARCHAR(500),
            LoaiCotDiem NVARCHAR(50),
            GiaTriCotDiem NVARCHAR(500),
            KieuDanhGiaID INT,
            TenCotDiem_VI NVARCHAR(200),
            TenCotDiem_EN NVARCHAR(200),
            ThuTuCotDiem INT,
            ThuTuNhom INT,
            MaNhomCotDiem NVARCHAR(100),
            TenNhomCotDiem_VI NVARCHAR(200),
            TenNhomCotDiem_EN NVARCHAR(200),
            KetQuaDanhGia_VI NVARCHAR(MAX),
            KetQuaDanhGia_EN NVARCHAR(MAX),
            HexBackground NVARCHAR(50),
            Formula NVARCHAR(MAX),
            DiemMin DECIMAL(18,2),
            DiemMax DECIMAL(18,2),
            QuyenNhapDiem BIT,
            TinhTrang INT,
            TenTinhTrang NVARCHAR(100),
            MauTinhTrang NVARCHAR(50),
            Is_GVCN_DaDuyet BIT,
            WidthCSS NVARCHAR(50),
            Lop_TinhTrangID INT,
            LatestPublishedStatusID INT,
            AdjustmentCountAfterPublish INT,
            NoiDungNhanXet NVARCHAR(MAX),
            Is_Comment BIT,
            NhapDiemUser VARCHAR(9),
            Is_Edit BIT,
            KQHTID INT,
            EnglishName NVARCHAR(200),
            MonHocID INT,
            Sort INT,
            HeSo DECIMAL(18,2),
            TenLop NVARCHAR(200)
			, TenHienThi_VI NVARCHAR(200)
			, TenHienThi_EN NVARCHAR(200)
			, KhoaCotDiemID INT
        );

        -- Đọc lần công bố gần nhất và đếm các lần chuyển trạng thái sau công bố cho đúng lớp, môn, nhóm và niên khóa.
        ;WITH StatusBySchoolYear AS
        (
            SELECT ltt.Lop_TinhTrangID,
                   ltt.LopID,
                   ltt.MonHocLopID,
                   ltt.MaNhomCotDiem,
                   ltt.TinhTrang,
                   ltt.CreateTime,
                   mhl.NienKhoa
            FROM dbo.tblLop_TinhTrang AS ltt
            INNER JOIN dbo.tblMonHocLop AS mhl
                ON mhl.MonHocLopID = ltt.MonHocLopID
               AND mhl.LopNhomID = ltt.LopID
               AND mhl.Enable = 1
               AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR mhl.NienKhoa = @NienKhoa)
            INNER JOIN dbo.tblLop AS l
                ON l.LopID = ltt.LopID
               AND l.NienKhoa = mhl.NienKhoa
               AND l.Enable = 1
        ),
        RankedPublishedStatus AS
        (
            SELECT statusRow.*,
                   ROW_NUMBER() OVER
                   (
                       PARTITION BY statusRow.NienKhoa,
                                    statusRow.LopID,
                                    statusRow.MonHocLopID,
                                    statusRow.MaNhomCotDiem
                       ORDER BY statusRow.CreateTime DESC,
                                statusRow.Lop_TinhTrangID DESC
                   ) AS VersionNumber
            FROM StatusBySchoolYear AS statusRow
            WHERE statusRow.TinhTrang = 8
        ),
        LatestPublishedStatus AS
        (
            SELECT NienKhoa,
                   LopID,
                   MonHocLopID,
                   MaNhomCotDiem,
                   Lop_TinhTrangID,
                   CreateTime
            FROM RankedPublishedStatus
            WHERE VersionNumber = 1
        ),
        PublicationSummary AS
        (
            SELECT published.NienKhoa,
                   published.LopID,
                   published.MonHocLopID,
                   published.MaNhomCotDiem,
                   published.Lop_TinhTrangID AS LatestPublishedStatusID,
                   COUNT(revision.Lop_TinhTrangID) AS AdjustmentCountAfterPublish
            FROM LatestPublishedStatus AS published
            LEFT JOIN StatusBySchoolYear AS revision
                ON revision.NienKhoa = published.NienKhoa
               AND revision.LopID = published.LopID
               AND revision.MonHocLopID = published.MonHocLopID
               AND revision.MaNhomCotDiem = published.MaNhomCotDiem
               AND revision.TinhTrang <> 8
               AND
               (
                   revision.CreateTime > published.CreateTime
                   OR (revision.CreateTime = published.CreateTime
                       AND revision.Lop_TinhTrangID > published.Lop_TinhTrangID)
               )
            GROUP BY published.NienKhoa,
                     published.LopID,
                     published.MonHocLopID,
                     published.MaNhomCotDiem,
                     published.Lop_TinhTrangID
        )
        -- TinhTrang hiện tại có thể là lưu tạm; thông tin công bố được đọc riêng từ lịch sử trạng thái.
        INSERT INTO #TempResult
        SELECT HS.[HocSinhID], HSL.SoDanhBo, HS.[Ho], HS.[Ten]
             , HS.[NgaySinh], HS.[Nu], HS.Ho + ' ' + HS.Ten AS HoTen
             , BD.CotDiemID, BD.MaCotDiem, BD.LoaiCotDiem, BD.GiaTriCotDiem, BD.KieuDanhGiaID
             , BD.TenCotDiem_VI, BD.TenCotDiem_EN, BD.ThuTuCotDiem, BD.ThuTuNhom
             , BD.MaNhomCotDiem, BD.TenNhomCotDiem_VI, BD.TenNhomCotDiem_EN
             , KQ.KetQuaDanhGia_VI, KQ.KetQuaDanhGia_EN
             , BD.HexBackground, BD.Formula, BD.DiemMin, BD.DiemMax, BD.QuyenNhapDiem
             , ISNULL(l_tt.TinhTrang, 0) AS TinhTrang
             , CASE
                   WHEN mh.CapID = 1 THEN dbo.RenderTinhTrang(l_tt.TinhTrang)
                   WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
               END AS TenTinhTrang
             , CASE
                   WHEN mh.CapID = 1 THEN dbo.RenderColorTinhTrang(l_tt.TinhTrang)
                   WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
               END AS MauTinhTrang
             , l_tt.Is_GVCN_DaDuyet
             , BD.WidthCSS  
             , l_tt.Lop_TinhTrangID
             , publicationSummary.LatestPublishedStatusID
             , ISNULL(publicationSummary.AdjustmentCountAfterPublish, 0) AS AdjustmentCountAfterPublish
             , l_tt.NoiDungNhanXet
             , CASE WHEN KQ.NhapDiemUser <> @SYS_USERID THEN CAST(1 AS BIT) ELSE NULL END AS Is_Comment
             , KQ.NhapDiemUser, ISNULL(KQ.Is_Edit, 0) AS Is_Edit, ISNULL(KQ.KQHTID, 0) AS KQHTID
             , HS.EnglishName, mh.MonHocID, mh.Sort, BD.HeSo, l.TenLop, BD.TenHienThi_VI,BD.TenHienThi_EN
			 , KQ.KhoaCotDiemID
        FROM dbo.tblHocSinh HS
              INNER JOIN dbo.tblHocSinhLop HSL ON HS.HocSinhID = HSL.HocSinhID AND HSL.LopID = @LopID AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR HSL.NienKhoa = @NienKhoa)
              INNER JOIN dbo.tblMonHocLop MHL ON MHL.LopNhomID = HSL.LopID
                                             AND MHL.TemplateBangDiemID = @TemplateBangDiemID
                                             AND MHL.Enable = 1
                                             AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR MHL.NienKhoa = @NienKhoa)
              INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = MHL.MonHocID AND mh.Enable = 1
              INNER JOIN dbo.tblLop l ON l.LopID = HSL.LopID AND l.LopID = MHL.LopNhomID AND l.Enable = 1 AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR l.NienKhoa = @NienKhoa)
             AND HSL.NienKhoa = l.NienKhoa
        AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID = MHL.TemplateBangDiemID
                                                      AND (@MaNhomCotDiem IS NULL 
                                                           OR @MaNhomCotDiem = 'TATCA_CD_THEME_TA'
                                                           OR @MaNhomCotDiem LIKE 'DiemTBCK%' 
                                                           OR BD.MaNhomCotDiem = @MaNhomCotDiem)
                                                      AND (@Semester = '' 
                                                           OR (BD.Semester = @Semester 
                                                               AND (BD.MaCotDiem LIKE '%_Result' 
                                                                    OR BD.MaCotDiem LIKE 'DiemTBCK%' 
                                                                    OR BD.MaCotDiem LIKE 'DanhHieu%'
																	--OR (BD.MaCotDiem LIKE '%Total%' AND BD.MaCotDiem NOT LIKE '%_Conv%')
																	)))
                                                      AND BD.Enable = 1
             LEFT JOIN dbo.tblKetQuaHocTap KQ ON KQ.HocSinhID = HS.HocSinhID
                                             AND KQ.CotDiemID = BD.CotDiemID
                                             AND KQ.MonHocLopID = MHL.MonHocLopID
                                             AND KQ.Enable = 1
             LEFT JOIN dbo.tblLop_TinhTrang AS l_tt ON l_tt.Lop_TinhTrangID = KQ.Lop_TinhTrangID
                                                   AND l_tt.Enable = 1
             LEFT JOIN PublicationSummary AS publicationSummary
                ON publicationSummary.NienKhoa = MHL.NienKhoa
               AND publicationSummary.LopID = HSL.LopID
               AND publicationSummary.MonHocLopID = MHL.MonHocLopID
               AND publicationSummary.MaNhomCotDiem = BD.MaNhomCotDiem
        WHERE HS.TinhTrang = 0 AND HSL.Enable = 1

        UNION

        SELECT HS.[HocSinhID], HSL.SoDanhBo, HS.[Ho], HS.[Ten]
             , HS.[NgaySinh], HS.[Nu], HS.Ho + ' ' + HS.Ten AS HoTen
             , BD.CotDiemID, CAST(BD.CotDiemID AS NVARCHAR(100)) + '_' + BD.MaCotDiem AS MaCotDiem
             , BD.LoaiCotDiem, BD.GiaTriCotDiem, BD.KieuDanhGiaID
             , mh.TenMonHoc_HienThi + ' - ' + BD.TenCotDiem_VI AS TenCotDiem_VI
             , BD.TenCotDiem_EN, BD.ThuTuCotDiem, BD.ThuTuNhom
             , BD.MaNhomCotDiem, BD.TenNhomCotDiem_VI, BD.TenNhomCotDiem_EN
             , KQ.KetQuaDanhGia_VI, KQ.KetQuaDanhGia_EN
             , BD.HexBackground, BD.Formula, BD.DiemMin, BD.DiemMax, BD.QuyenNhapDiem
             , ISNULL(l_tt.TinhTrang, 0) AS TinhTrang
             , CASE
                   WHEN mh.CapID = 1 THEN dbo.RenderTinhTrang(l_tt.TinhTrang)
                   WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
               END AS TenTinhTrang
             , CASE
                   WHEN mh.CapID = 1 THEN dbo.RenderColorTinhTrang(l_tt.TinhTrang)
                   WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
               END AS MauTinhTrang
             , l_tt.Is_GVCN_DaDuyet
             , BD.WidthCSS 
             , l_tt.Lop_TinhTrangID
             , publicationSummary.LatestPublishedStatusID
             , ISNULL(publicationSummary.AdjustmentCountAfterPublish, 0) AS AdjustmentCountAfterPublish
             , l_tt.NoiDungNhanXet
             , CASE WHEN KQ.NhapDiemUser <> @SYS_USERID THEN CAST(1 AS BIT) ELSE NULL END AS Is_Comment
             , KQ.NhapDiemUser, ISNULL(KQ.Is_Edit, 0) AS Is_Edit, ISNULL(KQ.KQHTID, 0) AS KQHTID
             , HS.EnglishName, mh.MonHocID, mh.Sort, BD.HeSo, l.TenLop , mh.TenMonHoc_HienThi + ' - ' + BD.TenCotDiem_VI as TenHienThi_VI,BD.TenHienThi_EN
			  , KQ.KhoaCotDiemID
        FROM dbo.tblHocSinh HS
              INNER JOIN dbo.tblHocSinhLop HSL ON HS.HocSinhID = HSL.HocSinhID AND HSL.LopID = @LopID AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR HSL.NienKhoa = @NienKhoa)
              INNER JOIN dbo.tblMonHocLop MHL ON MHL.LopNhomID = HSL.LopID
                                             AND MHL.MonHocID IN (SELECT value FROM STRING_SPLIT(@List_MonHoc_NLPC_ID, ','))
                                             AND MHL.LopNhomID = @LopID
                                             AND MHL.Enable = 1
                                             AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR MHL.NienKhoa = @NienKhoa)
              INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = MHL.MonHocID AND mh.Enable = 1
              INNER JOIN dbo.tblLop l ON l.LopID = HSL.LopID AND l.LopID = MHL.LopNhomID AND l.Enable = 1 AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR l.NienKhoa = @NienKhoa)
             AND HSL.NienKhoa = l.NienKhoa
        AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID = MHL.TemplateBangDiemID
                                                      AND (@MaNhomCotDiem IS NULL 
                                                           OR @MaNhomCotDiem = 'TATCA_CD_THEME_TA'
                                                           OR @MaNhomCotDiem LIKE 'DiemTBCK%' 
                                                           OR BD.MaNhomCotDiem = @MaNhomCotDiem)
                                                      AND (@Semester = '' 
                                                           OR (BD.Semester = @Semester 
                                                               AND (BD.MaCotDiem LIKE '%_Result' 
                                                                    OR BD.MaCotDiem LIKE 'DiemTBCK%' 
                                                                    OR BD.MaCotDiem LIKE 'DanhHieu%'
																	--OR (BD.MaCotDiem LIKE '%Total%' AND BD.MaCotDiem NOT LIKE '%_Conv%')
																	)))
                                                      AND BD.Enable = 1
             LEFT JOIN dbo.tblKetQuaHocTap KQ ON KQ.HocSinhID = HS.HocSinhID
                                             AND KQ.CotDiemID = BD.CotDiemID
                                             AND KQ.MonHocLopID = MHL.MonHocLopID
                                             AND KQ.Enable = 1
             LEFT JOIN dbo.tblLop_TinhTrang AS l_tt ON l_tt.Lop_TinhTrangID = KQ.Lop_TinhTrangID
                                                   AND l_tt.Enable = 1
             LEFT JOIN PublicationSummary AS publicationSummary
                ON publicationSummary.NienKhoa = MHL.NienKhoa
               AND publicationSummary.LopID = HSL.LopID
               AND publicationSummary.MonHocLopID = MHL.MonHocLopID
               AND publicationSummary.MaNhomCotDiem = BD.MaNhomCotDiem
        WHERE HS.TinhTrang = 0 AND HSL.Enable = 1;

        -- Trả về kết quả với ORDER BY phù hợp
        IF (@HasSoDanhBoNull = 1)
        BEGIN
            -- Nếu có học sinh không có SoDanhBo thì sort theo Tên
            SELECT * FROM #TempResult
            ORDER BY Ten, Ho, Sort, MonHocID, ThuTuNhom, ThuTuCotDiem;
        END
        ELSE
        BEGIN
            -- Nếu tất cả đều có SoDanhBo thì sort theo SoDanhBo
            SELECT * FROM #TempResult
            ORDER BY SoDanhBo, Ten, Ho, Sort, MonHocID, ThuTuNhom, ThuTuCotDiem;
        END

        -- Xóa bảng tạm
        DROP TABLE #TempResult;
    END
    ELSE
    BEGIN
        -- Truy vấn khi LopID là chuỗi
        DECLARE @HasSoTTNull BIT = 0;
        IF EXISTS (
            SELECT 1
            FROM dbo.tblHocSinhNhom HSN
                 INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = HSN.HocSinhID
                                             AND hs.TinhTrang = 0
            WHERE HSN.NhomID = @LopNhomID 
              AND HSN.SoTT IS NULL
			  and hsn.Enable = 1
        )
        BEGIN
            SET @HasSoTTNull = 1;
        END

        IF (@HasSoTTNull = 1)
        BEGIN
            -- Sort theo Tên
            SELECT HS.[HocSinhID], HSN.SoTT AS SoDanhBo, HS.[Ho], HS.[Ten]
                 , HS.[NgaySinh], HS.[Nu], HS.Ho + ' ' + HS.Ten AS HoTen
                 , BD.CotDiemID, BD.MaCotDiem, BD.LoaiCotDiem, BD.GiaTriCotDiem, BD.KieuDanhGiaID
                 , BD.TenCotDiem_VI, BD.TenCotDiem_EN, BD.ThuTuCotDiem, BD.ThuTuNhom
                 , BD.MaNhomCotDiem, BD.TenNhomCotDiem_VI, BD.TenNhomCotDiem_EN
                 , KQ.KetQuaDanhGia_VI, KQ.KetQuaDanhGia_EN
                 , BD.HexBackground, BD.Formula, BD.DiemMin, BD.DiemMax, BD.QuyenNhapDiem
                 , ISNULL(l_tt.TinhTrang, 0) AS TinhTrang
                 , BD.WidthCSS
                 , CASE WHEN KQ.NhapDiemUser <> @SYS_USERID THEN CAST(1 AS BIT) ELSE NULL END AS Is_Comment
                 , KQ.NhapDiemUser, ISNULL(KQ.Is_Edit, 0) AS Is_Edit, ISNULL(KQ.KQHTID, 0) AS KQHTID
                 , HS.EnglishName, l.LopID AS LopID, l.TenLop, mh.Sort
                 , CASE
                        WHEN mh.CapID = 1 THEN dbo.RenderTinhTrang(l_tt.TinhTrang)
                        WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
                   END AS TenTinhTrang
                 , CASE
                        WHEN mh.CapID = 1 THEN dbo.RenderColorTinhTrang(l_tt.TinhTrang)
                        WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
                   END AS MauTinhTrang
                 , BD.HeSo , BD.TenHienThi_VI,BD.TenHienThi_EN
				 , KQ.KhoaCotDiemID
            FROM dbo.tblHocSinh HS
                 INNER JOIN dbo.tblHocSinhNhom HSN ON HS.HocSinhID = HSN.HocSinhID AND HSN.NhomID = @LopNhomID and hsn.Enable = 1
                 INNER JOIN dbo.tblMonHocLop MHL ON MHL.LopNhomID = HSN.NhomID AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR MHL.NienKhoa = @NienKhoa)
                 INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = MHL.MonHocID
                                            AND mh.Enable = 1
                                            AND MHL.TemplateBangDiemID = @TemplateBangDiemID
                                            AND MHL.Enable = 1
                 INNER JOIN dbo.tblLop l ON l.LopID = HSN.LopID AND l.NienKhoa = MHL.NienKhoa
                 INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID = MHL.TemplateBangDiemID
                                                          AND (@MaNhomCotDiem IS NULL OR @MaNhomCotDiem = ''
                                                               OR @MaNhomCotDiem = 'TATCA_CD_THEME_TA'
                                                               OR @MaNhomCotDiem LIKE 'DiemTBCK%'
                                                               OR BD.MaNhomCotDiem = @MaNhomCotDiem)
                                                          AND (@Semester = '' 
                                                               OR (BD.Semester = @Semester 
                                                                   AND (BD.MaCotDiem LIKE '%_Result' 
                                                                        OR BD.MaCotDiem LIKE 'DiemTBCK%' 
                                                                        OR BD.MaCotDiem LIKE 'DanhHieu%')))
                                                          AND BD.Enable = 1
                 LEFT JOIN dbo.tblKetQuaHocTap KQ ON KQ.HocSinhID = HS.HocSinhID
                                                 AND KQ.CotDiemID = BD.CotDiemID
                                                 AND KQ.MonHocLopID = MHL.MonHocLopID
                                                 AND KQ.Enable = 1
                 LEFT JOIN dbo.tblLop_TinhTrang AS l_tt ON l_tt.Lop_TinhTrangID = KQ.Lop_TinhTrangID
                                                       AND l_tt.Enable = 1
            WHERE HS.TinhTrang = 0
            ORDER BY HS.Ten, HS.Ho, BD.ThuTuNhom, BD.ThuTuCotDiem;
        END
        ELSE
        BEGIN
            -- Sort theo SoTT
            SELECT HS.[HocSinhID], HSN.SoTT AS SoDanhBo, HS.[Ho], HS.[Ten]
                 , HS.[NgaySinh], HS.[Nu], HS.Ho + ' ' + HS.Ten AS HoTen
                 , BD.CotDiemID, BD.MaCotDiem, BD.LoaiCotDiem, BD.GiaTriCotDiem, BD.KieuDanhGiaID
                 , BD.TenCotDiem_VI, BD.TenCotDiem_EN, BD.ThuTuCotDiem, BD.ThuTuNhom
                 , BD.MaNhomCotDiem, BD.TenNhomCotDiem_VI, BD.TenNhomCotDiem_EN
                 , KQ.KetQuaDanhGia_VI, KQ.KetQuaDanhGia_EN
                 , BD.HexBackground, BD.Formula, BD.DiemMin, BD.DiemMax, BD.QuyenNhapDiem
                 , ISNULL(l_tt.TinhTrang, 0) AS TinhTrang
                 , BD.WidthCSS 
                 , CASE WHEN KQ.NhapDiemUser <> @SYS_USERID THEN CAST(1 AS BIT) ELSE NULL END AS Is_Comment
                 , KQ.NhapDiemUser, ISNULL(KQ.Is_Edit, 0) AS Is_Edit, ISNULL(KQ.KQHTID, 0) AS KQHTID
                 , HS.EnglishName, l.LopID AS LopID, l.TenLop, mh.Sort
                 , CASE
                        WHEN mh.CapID = 1 THEN dbo.RenderTinhTrang(l_tt.TinhTrang)
                        WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
                   END AS TenTinhTrang
                 , CASE
                        WHEN mh.CapID = 1 THEN dbo.RenderColorTinhTrang(l_tt.TinhTrang)
                        WHEN mh.CapID IN (2, 3) THEN dbo.RenderTinhTrang_C2_C3(l_tt.TinhTrang)
                   END AS MauTinhTrang
                 , BD.HeSo , BD.TenHienThi_VI,BD.TenHienThi_EN
				  , KQ.KhoaCotDiemID
            FROM dbo.tblHocSinh HS
                 INNER JOIN dbo.tblHocSinhNhom HSN ON HS.HocSinhID = HSN.HocSinhID AND HSN.NhomID = @LopNhomID and hsn.Enable = 1
                 INNER JOIN dbo.tblMonHocLop MHL ON MHL.LopNhomID = HSN.NhomID AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR MHL.NienKhoa = @NienKhoa)
                 INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = MHL.MonHocID
                                            AND mh.Enable = 1
                                            AND MHL.TemplateBangDiemID = @TemplateBangDiemID
                                            AND MHL.Enable = 1
                 INNER JOIN dbo.tblLop l ON l.LopID = HSN.LopID AND l.NienKhoa = MHL.NienKhoa
                 INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID = MHL.TemplateBangDiemID
                                                          AND (@MaNhomCotDiem IS NULL OR @MaNhomCotDiem = ''
                                                               OR @MaNhomCotDiem = 'TATCA_CD_THEME_TA'
                                                               OR @MaNhomCotDiem LIKE 'DiemTBCK%'
                                                               OR BD.MaNhomCotDiem = @MaNhomCotDiem)
                                                          AND (@Semester = '' 
                                                               OR (BD.Semester = @Semester 
                                                                   AND (BD.MaCotDiem LIKE '%_Result' 
                                                                        OR BD.MaCotDiem LIKE 'DiemTBCK%' 
                                                                        OR BD.MaCotDiem LIKE 'DanhHieu%')))
                                                          AND BD.Enable = 1
                 LEFT JOIN dbo.tblKetQuaHocTap KQ ON KQ.HocSinhID = HS.HocSinhID
                                                 AND KQ.CotDiemID = BD.CotDiemID
                                                 AND KQ.MonHocLopID = MHL.MonHocLopID
                                                 AND KQ.Enable = 1
                 LEFT JOIN dbo.tblLop_TinhTrang AS l_tt ON l_tt.Lop_TinhTrangID = KQ.Lop_TinhTrangID
                                                       AND l_tt.Enable = 1
            WHERE HS.TinhTrang = 0
            ORDER BY HSN.SoTT, HS.Ten, HS.Ho, BD.ThuTuNhom, BD.ThuTuCotDiem;
        END
    END
	

END;

-- EXEC [spAPI_TienDo_NhapDiem] 2025,3,12,''
CREATE PROCEDURE [dbo].[spAPI_TienDo_NhapDiem]
    @NienKhoa   INT
	, @HocKi INT
  , @CapID      INT
  , @KhoiID     INT
  , @Sys_USERID VARCHAR(9)
AS
BEGIN
    IF(@CapID = 3)
    BEGIN 
        -- Khai báo Table Variable để quản lý dữ liệu tblNhom
        DECLARE @TblTinhTrangDiem TABLE
        (
            TenNhom                NVARCHAR(255),
            Sort                   INT,
            MonHocCode             NVARCHAR(50),
            TenMonHoc_HienThi      NVARCHAR(255),
            MaNhomCotDiem          NVARCHAR(50),
            Lop_TinhTrangID        INT,
            TinhTrang              INT,
            TenTinhTrang           NVARCHAR(100),
            MauTinhTrang           NVARCHAR(50),
            GiaoVienID             NVARCHAR(200),
            MonHocLopID            INT,
            NhomID                 NVARCHAR(200)
        )

        -- Insert dữ liệu tblNhom vào Table Variable
        INSERT INTO @TblTinhTrangDiem
        SELECT n.TenNhom
             , mh.Sort
             , mh.MonHocCode
             , mh.TenMonHoc_HienThi
             , ltt.MaNhomCotDiem
             , ltt.Lop_TinhTrangID
             , ltt.TinhTrang
             , CASE
                    WHEN n.CapID = 1 THEN dbo.RenderTinhTrang(ltt.TinhTrang)
                    WHEN n.CapID = 2 OR n.CapID = 3 THEN dbo.RenderTinhTrang_C2_C3(ltt.TinhTrang)
                    ELSE 'UNKNOWN'
               END AS TenTinhTrang
             , CASE
                    WHEN n.CapID = 1 THEN dbo.RenderColorTinhTrang(ltt.TinhTrang)
                    WHEN n.CapID = 2 OR n.CapID = 3 THEN dbo.RenderColorTinhTrang_C2_C3(ltt.TinhTrang)
                    ELSE ''
               END AS MauTinhTrang
             , gvl.GiaoVienID
             , mhl.MonHocLopID
             , n.NhomID
        FROM dbo.tblNhom n
             LEFT JOIN dbo.tblLop_TinhTrang ltt ON n.NhomID = ltt.LopID
                                               AND ltt.Enable = 1
                                               AND ltt.TinhTrang > 0
                                               AND EXISTS (
                                                   SELECT TOP 1 *
                                                   FROM dbo.tblKetQuaHocTap
                                                   WHERE ltt.MonHocLopID = MonHocLopID
                                                     AND Enable = 1
                                                     AND NienKhoa = @NienKhoa
                                               )
             LEFT JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = ltt.MonHocLopID
                                           AND mhl.Enable = 1
             LEFT JOIN dbo.tblMonHoc mh ON mh.MonHocID = mhl.MonHocID
                                       AND mh.Enable = 1
                                       AND mh.CapID = @CapID
             LEFT JOIN dbo.tblGiaoVienLop gvl ON gvl.LopID = n.NhomID
                                             AND gvl.MonHocID = mh.MonHocID
                                             AND gvl.NienKhoa = @NienKhoa
                                             AND gvl.Enable = 1
											 AND gvl.HocKy = @HocKi
        WHERE n.Enable = 1
          AND n.NienKhoa = @NienKhoa
          AND n.CapID = @CapID
          AND n.KhoiID = @KhoiID
          AND n.IsNhomLMS_GiaoBai = 0

        -- Lấy dữ liệu của lớp đã nhập điểm (tblLop)
        SELECT l.TenLop
             , mh.Sort
             , mh.MonHocCode
             , mh.TenMonHoc_HienThi
             , ct.MaNhomCotDiem
             , ltt.Lop_TinhTrangID
             , ltt.TinhTrang
             , CASE
                    WHEN l.CapID = 1 THEN dbo.RenderTinhTrang(ltt.TinhTrang)
                    WHEN l.CapID = 2 OR l.CapID = 3 THEN dbo.RenderTinhTrang_C2_C3(ltt.TinhTrang)
                    ELSE 'UNKNOWN'
               END AS TenTinhTrang
             , CASE
                    WHEN l.CapID = 1 THEN dbo.RenderColorTinhTrang(ltt.TinhTrang)
                    WHEN l.CapID = 2 OR l.CapID = 3 THEN dbo.RenderColorTinhTrang_C2_C3(ltt.TinhTrang)
                    ELSE ''
               END AS MauTinhTrang
             , gvl.GiaoVienID
             , mhl.MonHocLopID
             , l.LopID
             , ct.ThuTuNhom
        FROM dbo.tblLop l
             LEFT JOIN dbo.tblLop_TinhTrang ltt ON l.LopID = ltt.LopID
                                               AND ltt.Enable = 1
                                               AND ltt.TinhTrang > 0
                                               AND EXISTS (
                                                   SELECT TOP 1 *
                                                   FROM dbo.tblKetQuaHocTap
                                                   WHERE ltt.MonHocLopID = MonHocLopID
                                                     AND Enable = 1
                                                     AND NienKhoa = @NienKhoa
                                               )
             LEFT JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = ltt.MonHocLopID
                                           AND mhl.Enable = 1
             LEFT JOIN dbo.tblMonHoc mh ON mh.MonHocID = mhl.MonHocID
                                       AND mh.Enable = 1
                                       AND mh.CapID = @CapID
             LEFT JOIN dbo.tblGiaoVienLop gvl ON gvl.LopID = l.LopID
                                             AND gvl.MonHocID = mh.MonHocID
                                             AND gvl.NienKhoa = @NienKhoa
                                             AND gvl.Enable = 1
											  AND gvl.HocKy = @HocKi
             LEFT JOIN dbo.TemplateBangDiemChiTiet ct ON ct.MaNhomCotDiem = ltt.MaNhomCotDiem 
                                                      AND ct.TemplateBangDiemID = mhl.TemplateBangDiemID
        WHERE l.Enable = 1
          AND l.NienKhoa = @NienKhoa
          AND l.CapID = @CapID
          AND l.KhoiID = @KhoiID
        
        UNION ALL

        -- Lấy dữ liệu từ Table Variable đã join với ThuTuNhom
        SELECT TenNhom
             , Sort
             , MonHocCode
             , TenMonHoc_HienThi
             , ISNULL(ct.MaNhomCotDiem, ttd.MaNhomCotDiem) AS MaNhomCotDiem
             , Lop_TinhTrangID
             , TinhTrang
             , TenTinhTrang
             , MauTinhTrang
             , GiaoVienID
             , ttd.MonHocLopID
             , NhomID
             , ct.ThuTuNhom
        FROM @TblTinhTrangDiem ttd
             LEFT JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = ttd.MonHocLopID 
             LEFT JOIN dbo.TemplateBangDiemChiTiet ct ON ct.MaNhomCotDiem = ttd.MaNhomCotDiem 
                                                      AND ct.TemplateBangDiemID = mhl.TemplateBangDiemID
        
        ORDER BY TenLop, Sort, ThuTuNhom, TinhTrang
    END
    ELSE
    BEGIN 
        -- Lấy dữ liệu của lớp đã nhập điểm (Cấp 1 và 2)
        SELECT l.TenLop
             , mh.Sort
             , mh.MonHocCode
             , mh.TenMonHoc_HienThi
             , ltt.MaNhomCotDiem
             , ltt.Lop_TinhTrangID
             , ltt.TinhTrang
             , CASE
                    WHEN l.CapID = 1 THEN dbo.RenderTinhTrang(ltt.TinhTrang)
                    WHEN l.CapID = 2 OR l.CapID = 3 THEN dbo.RenderTinhTrang_C2_C3(ltt.TinhTrang)
                    ELSE 'UNKNOWN'
               END AS TenTinhTrang
             , CASE
                    WHEN l.CapID = 1 THEN dbo.RenderColorTinhTrang(ltt.TinhTrang)
                    WHEN l.CapID = 2 OR l.CapID = 3 THEN dbo.RenderColorTinhTrang_C2_C3(ltt.TinhTrang)
                    ELSE ''
               END AS MauTinhTrang
             , gvl.GiaoVienID
             , mhl.MonHocLopID
             , l.LopID
        FROM dbo.tblLop l
             LEFT JOIN dbo.tblLop_TinhTrang ltt ON l.LopID = ltt.LopID
                                               AND ltt.Enable = 1
                                               AND ltt.TinhTrang > 0
                                               AND EXISTS (
                                                   SELECT TOP 1 *
                                                   FROM dbo.tblKetQuaHocTap
                                                   WHERE ltt.MonHocLopID = MonHocLopID
                                                     AND Enable = 1
                                                     AND NienKhoa = @NienKhoa
                                               )
             LEFT JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = ltt.MonHocLopID
                                           AND mhl.Enable = 1
             LEFT JOIN dbo.tblMonHoc mh ON mh.MonHocID = mhl.MonHocID
                                       AND mh.Enable = 1
                                       AND mh.CapID = @CapID
             LEFT JOIN dbo.tblGiaoVienLop gvl ON gvl.LopID = l.LopID
                                             AND gvl.MonHocID = mh.MonHocID
                                             AND gvl.NienKhoa = @NienKhoa
                                             AND gvl.Enable = 1
											  AND gvl.HocKy = @HocKi
        WHERE l.Enable = 1
          AND l.NienKhoa = @NienKhoa
          AND l.CapID = @CapID
          AND l.KhoiID = @KhoiID
    END

    -- Lấy danh sách nhóm điểm môn học
    --SELECT l.TenLop
    --     , mhl.LopNhomID
    --     , mh.TenMonHoc_HienThi
    --     , mh.Sort
    --     , mh.MonHocCode
    --     , bd.TemplateBangDiemID
    --     , bdct.CotDiemID
    --     , bdct.MaNhomCotDiem
    --     , bdct.TenCotDiem_VI
    --     , bdct.ThuTuNhom
    --     , bdct.ThuTuCotDiem
    --FROM tblMonHoc mh
    --     LEFT JOIN tblMonHocLop mhl ON mhl.MonHocID = mh.MonHocID
    --                               AND mhl.Enable = 1
    --                               AND mhl.NienKhoa = @NienKhoa
    --     LEFT JOIN TemplateBangDiem bd ON bd.TemplateBangDiemID = mhl.TemplateBangDiemID
    --                                  AND bd.Enable = 1
    --                                  AND bd.NienKhoa = @NienKhoa
    --     LEFT JOIN TemplateBangDiemChiTiet bdct ON bdct.TemplateBangDiemID = bd.TemplateBangDiemID
    --                                           AND bdct.Enable = 1
    --     LEFT JOIN tblLop l ON l.LopID = mhl.LopNhomID
    --                       AND l.Enable = 1
    --                       AND l.NienKhoa = @NienKhoa
    --                       AND l.CapID = @CapID
    --                       AND l.KhoiID = @KhoiID
    --WHERE mh.CapID = @CapID
    --  AND mh.Enable = 1
    --ORDER BY l.TenLop, mh.Sort, bdct.ThuTuNhom, bdct.ThuTuCotDiem
	SELECT		ISNULL(l.TenLop, n.TenNhom) AS TenLop
         , mhl.LopNhomID
         , mh.TenMonHoc_HienThi
         , mh.Sort
         , mh.MonHocCode
         , bd.TemplateBangDiemID
         , bdct.CotDiemID
         , bdct.MaNhomCotDiem
         , bdct.TenCotDiem_VI
         , bdct.ThuTuNhom
         , bdct.ThuTuCotDiem
    FROM tblMonHoc mh
         inner JOIN tblMonHocLop mhl ON mhl.MonHocID = mh.MonHocID
                                   AND mhl.Enable = 1
                                   AND mhl.NienKhoa = @NienKhoa
         inner JOIN TemplateBangDiem bd ON bd.TemplateBangDiemID = mhl.TemplateBangDiemID
                                      AND bd.Enable = 1
                                      AND bd.NienKhoa = @NienKhoa
         inner JOIN TemplateBangDiemChiTiet bdct ON bdct.TemplateBangDiemID = bd.TemplateBangDiemID
                                               AND bdct.Enable = 1
         LEFT JOIN tblLop l ON l.LopID = mhl.LopNhomID
                           AND l.Enable = 1
                           AND l.NienKhoa = @NienKhoa
                           AND l.CapID = @CapID
                           AND l.KhoiID = @KhoiID
		LEFT JOIN dbo.tblNhom n ON n.NhomID = mhl.LopNhomID
							   AND n.Enable = 1
							   AND n.NienKhoa = @NienKhoa
							   AND n.CapID = @CapID
							   AND n.KhoiID = @KhoiID
    WHERE mh.CapID = @CapID
      AND mh.Enable = 1
	  AND ISNULL(l.TenLop, n.TenNhom) IS NOT NULL
    ORDER BY ISNULL(l.TenLop, n.TenNhom), mh.Sort, bdct.ThuTuNhom, bdct.ThuTuCotDiem

    --- Lấy dữ liệu giáo viên dạy lớp,môn
    SELECT gvl.GiaoVienID
         , CONCAT(gv.HoGV, ' ', gv.TenGV) AS HoTenGV
         , l.TenLop
         , mh.MonHocID
         , mh.MonHocCode
         , mh.TenMonHoc_HienThi
    FROM tblGiaoVienLop gvl
         INNER JOIN tblLop l ON l.LopID = gvl.LopID
                            AND l.KhoiID = @KhoiID
                            AND l.Enable = 1
                            AND l.NienKhoa = @NienKhoa
         INNER JOIN tblMonHoc mh ON mh.MonHocID = gvl.MonHocID
                                AND mh.Enable = 1
         INNER JOIN tblGiaoVien gv ON gv.GiaoVienID = gvl.GiaoVienID
                                  AND gv.Enable = 1
    WHERE gvl.NienKhoa = @NienKhoa
      AND gvl.Enable = 1
	   AND gvl.HocKy = @HocKi
    UNION
    SELECT gvl.GiaoVienID
         , CONCAT(gv.HoGV, ' ', gv.TenGV) AS HoTenGV
         , l.TenNhom
         , mh.MonHocID
         , mh.MonHocCode
         , mh.TenMonHoc_HienThi
    FROM tblGiaoVienLop gvl
         INNER JOIN tblNhom l ON l.NhomID = gvl.LopID
                             AND l.KhoiID = @KhoiID
                             AND l.Enable = 1
                             AND l.NienKhoa = @NienKhoa
                             AND l.IsNhomLMS_GiaoBai = 0
         INNER JOIN tblMonHoc mh ON mh.MonHocID = gvl.MonHocID
                                AND mh.Enable = 1
         INNER JOIN tblGiaoVien gv ON gv.GiaoVienID = gvl.GiaoVienID
                                  AND gv.Enable = 1
    WHERE gvl.NienKhoa = @NienKhoa
      AND gvl.Enable = 1
	   AND gvl.HocKy = @HocKi

    --Lấy danh sách môn học
    SELECT MonHocID
         , MonHocCode
         , TenMonHoc_HienThi
    FROM tblMonHoc
    WHERE CapID = @CapID
      AND Enable = 1
    ORDER BY Sort

    --Lấy danh sách lớp học
    SELECT LopID
         , TenLop
    FROM tblLop
    WHERE NienKhoa = @NienKhoa
      AND Enable = 1
      AND KhoiID = @KhoiID
	UNION
    SELECT NhomID, TenNhom FROM dbo.tblNhom
	WHERE KhoiID = @KhoiID AND Enable  = 1 AND NienKhoa = @NienKhoa
	AND IsNhomLMS_GiaoBai = 0
END
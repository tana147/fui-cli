-- spAPI_ThongKe_KQRL_Get_All_Khoi_C1 'GK_HK2'
CREATE PROC spAPI_ThongKe_KQRL_Get_All_Khoi_C2_C3 @HocKi VARCHAR(10)
AS
BEGIN

    --Lấy khối 1 -> 4 => Phẩm Chất
    SELECT REPLACE(mh.TenMonHoc_HienThi, N'Phẩm chất-', '')                                                                                AS TenMonHoc_HienThi
		, CASE 
			WHEN mh.TenMonHoc_HienThi LIKE N'Phẩm chất' THEN CAST(1 AS BIT )
			ELSE CAST(0 AS BIT )
		END AS Is_PhamChat
         , COUNT(kqht.HocSinhID)                                                                                                           AS TongSoHS
         , SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'T' THEN 1 ELSE 0 END)                                                                   AS Tot
         , CAST(100.0 * SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'T' THEN 1 ELSE 0 END) / NULLIF(COUNT(kqht.HocSinhID), 0) AS DECIMAL(5, 2)) AS TiLe_Tot
         , SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'Đ' THEN 1 ELSE 0 END)                                                                   AS Dat
         , CAST(100.0 * SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'Đ' THEN 1 ELSE 0 END) / NULLIF(COUNT(kqht.HocSinhID), 0) AS DECIMAL(5, 2)) AS TiLe_Dat
         , SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'C' THEN 1 ELSE 0 END)                                                                   AS C
         , CAST(100.0 * SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'C' THEN 1 ELSE 0 END) / NULLIF(COUNT(kqht.HocSinhID), 0) AS DECIMAL(5, 2)) AS TiLe_C
    FROM
           dbo.tblKetQuaHocTap                    kqht
           INNER JOIN dbo.TemplateBangDiemChiTiet AS tbdct ON tbdct.CotDiemID   = kqht.CotDiemID
                                                          AND tbdct.Enable      = 1
                                                          AND tbdct.MaCotDiem LIKE '%MucDoDanhGia%' + @HocKi
           INNER JOIN dbo.tblMonHocLop            mhl ON mhl.MonHocLopID        = kqht.MonHocLopID
                                                     AND mhl.TemplateBangDiemID = tbdct.TemplateBangDiemID
                                                     AND mhl.Enable             = 1
           INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID          = mhl.MonHocID
                                                       AND mh.Enable            = 1
           INNER JOIN dbo.tblLop                  l ON l.LopID                  = mhl.LopNhomID AND l.NienKhoa = mhl.NienKhoa
                                                   AND l.Enable                 = 1
                                                   AND l.CapID                  = 1
                                                   AND l.KhoiID IN (1, 2, 3, 4)
           INNER JOIN dbo.tblHocSinh              AS hs ON hs.HocSinhID         = kqht.HocSinhID
                                                       AND hs.TinhTrang         = 0
    WHERE
           kqht.Enable = 1
      AND  mh.MonHocID IN (   23 --	Phẩm chất-Yêu nước
                            , 24 --	Phẩm chất-Nhân ái
                            , 25 --	Phẩm chất-Chăm chỉ
                            , 26 --	Phẩm chất-Trung thực
                            , 27 --	Phẩm chất-Trách nhiệm
                          )
    GROUP BY
           mh.TenMonHoc_HienThi;

    --Lấy khối 1 -> 4 => Năng lực
    SELECT REPLACE(mh.TenMonHoc_HienThi, N'Năng lực-', '')                                                                                 AS TenMonHoc_HienThi
         , COUNT(kqht.HocSinhID)                                                                                                           AS TongSoHS
         , SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'T' THEN 1 ELSE 0 END)                                                                   AS Tot
         , CAST(100.0 * SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'T' THEN 1 ELSE 0 END) / NULLIF(COUNT(kqht.HocSinhID), 0) AS DECIMAL(5, 2)) AS TiLe_Tot
         , SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'Đ' THEN 1 ELSE 0 END)                                                                   AS Dat
         , CAST(100.0 * SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'Đ' THEN 1 ELSE 0 END) / NULLIF(COUNT(kqht.HocSinhID), 0) AS DECIMAL(5, 2)) AS TiLe_Dat
         , SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'C' THEN 1 ELSE 0 END)                                                                   AS C
         , CAST(100.0 * SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'C' THEN 1 ELSE 0 END) / NULLIF(COUNT(kqht.HocSinhID), 0) AS DECIMAL(5, 2)) AS TiLe_C
    FROM
           dbo.tblKetQuaHocTap                    kqht
           INNER JOIN dbo.TemplateBangDiemChiTiet AS tbdct ON tbdct.CotDiemID   = kqht.CotDiemID
                                                          AND tbdct.Enable      = 1
                                                          AND tbdct.MaCotDiem LIKE '%MucDoDanhGia%' + @HocKi
           INNER JOIN dbo.tblMonHocLop            mhl ON mhl.MonHocLopID        = kqht.MonHocLopID
                                                     AND mhl.TemplateBangDiemID = tbdct.TemplateBangDiemID
                                                     AND mhl.Enable             = 1
           INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID          = mhl.MonHocID
                                                       AND mh.Enable            = 1
           INNER JOIN dbo.tblLop                  l ON l.LopID                  = mhl.LopNhomID AND l.NienKhoa = mhl.NienKhoa
                                                   AND l.Enable                 = 1
                                                   AND l.CapID                  = 1
                                                   AND l.KhoiID IN (1, 2, 3, 4)
           INNER JOIN dbo.tblHocSinh              AS hs ON hs.HocSinhID         = kqht.HocSinhID
                                                       AND hs.TinhTrang         = 0
    WHERE
           kqht.Enable = 1
      AND  mh.MonHocID IN (   20 --Năng lực-Tự chủ và tự học
                            , 21 --Năng lực-Giao tiếp và hợp tác
                            , 22 --Năng lực-Giải quyết vấn đề và sáng tạo
                            , 28 --Năng lực-Ngôn ngữ
                            , 29 --Năng lực-Tính toán
                            , 30 --Năng lực-Khoa học
                            , 31 --Năng lực-Công nghệ
                            , 32 --Năng lực-Tin học
                            , 33 --Năng lực-Thẩm mĩ
                            , 34 --Năng lực-Thể chất
                          )
    GROUP BY
           mh.TenMonHoc_HienThi;

    --Lấy khối 5 => PC - NL
    SELECT REPLACE(REPLACE(mh.TenMonHoc_HienThi, N'Phẩm chất-', ''), N'Năng lực-', '')                                                     AS TenMonHoc_HienThi
         , COUNT(kqht.HocSinhID)                                                                                                           AS TongSoHS
         , SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'T' THEN 1 ELSE 0 END)                                                                   AS Tot
         , CAST(100.0 * SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'T' THEN 1 ELSE 0 END) / NULLIF(COUNT(kqht.HocSinhID), 0) AS DECIMAL(5, 2)) AS TiLe_Tot
         , SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'Đ' THEN 1 ELSE 0 END)                                                                   AS Dat
         , CAST(100.0 * SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'Đ' THEN 1 ELSE 0 END) / NULLIF(COUNT(kqht.HocSinhID), 0) AS DECIMAL(5, 2)) AS TiLe_Dat
         , SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'C' THEN 1 ELSE 0 END)                                                                   AS C
         , CAST(100.0 * SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'C' THEN 1 ELSE 0 END) / NULLIF(COUNT(kqht.HocSinhID), 0) AS DECIMAL(5, 2)) AS TiLe_C
    FROM
           dbo.tblKetQuaHocTap                    kqht
           INNER JOIN dbo.TemplateBangDiemChiTiet AS tbdct ON tbdct.CotDiemID   = kqht.CotDiemID
                                                          AND tbdct.Enable      = 1
                                                          AND tbdct.MaCotDiem LIKE '%MucDoDanhGia%' + @HocKi
           INNER JOIN dbo.tblMonHocLop            mhl ON mhl.MonHocLopID        = kqht.MonHocLopID
                                                     AND mhl.TemplateBangDiemID = tbdct.TemplateBangDiemID
                                                     AND mhl.Enable             = 1
           INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID          = mhl.MonHocID
                                                       AND mh.Enable            = 1
           INNER JOIN dbo.tblLop                  l ON l.LopID                  = mhl.LopNhomID AND l.NienKhoa = mhl.NienKhoa
                                                   AND l.Enable                 = 1
                                                   AND l.CapID                  = 1
                                                   AND l.KhoiID IN (5)
           INNER JOIN dbo.tblHocSinh              AS hs ON hs.HocSinhID         = kqht.HocSinhID
                                                       AND hs.TinhTrang         = 0
    WHERE
           kqht.Enable = 1
      AND  mh.MonHocID IN (   23 --	Phẩm chất-Yêu nước
                            , 24 --	Phẩm chất-Nhân ái
                            , 25 --	Phẩm chất-Chăm chỉ
                            , 26 --	Phẩm chất-Trung thực
                            , 27 --	Phẩm chất-Trách nhiệm
                            , 20 --Năng lực-Tự chủ và tự học
                            , 21 --Năng lực-Giao tiếp và hợp tác
                            , 22 --Năng lực-Giải quyết vấn đề và sáng tạo
                            , 28 --Năng lực-Ngôn ngữ
                            , 29 --Năng lực-Tính toán
                            , 30 --Năng lực-Khoa học
                            , 31 --Năng lực-Công nghệ
                            , 32 --Năng lực-Tin học
                            , 33 --Năng lực-Thẩm mĩ
                            , 34 --Năng lực-Thể chất
                          )
    GROUP BY
           mh.TenMonHoc_HienThi;

    --Lấy các môn học từ Khối 1 -> 5 (Ngoại trừ PC - NL)
    SELECT mh.TenMonHoc_HienThi
         , COUNT(kqht.HocSinhID)                                                                                                           AS TongSoHS
         , SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'T' THEN 1 ELSE 0 END)                                                                   AS Tot
         , CAST(100.0 * SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'T' THEN 1 ELSE 0 END) / NULLIF(COUNT(kqht.HocSinhID), 0) AS DECIMAL(5, 2)) AS TiLe_Tot
         , SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'Đ' THEN 1 ELSE 0 END)                                                                   AS Dat
         , CAST(100.0 * SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'Đ' THEN 1 ELSE 0 END) / NULLIF(COUNT(kqht.HocSinhID), 0) AS DECIMAL(5, 2)) AS TiLe_Dat
         , SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'C' THEN 1 ELSE 0 END)                                                                   AS C
         , CAST(100.0 * SUM(CASE WHEN kqht.KetQuaDanhGia_VI = N'C' THEN 1 ELSE 0 END) / NULLIF(COUNT(kqht.HocSinhID), 0) AS DECIMAL(5, 2)) AS TiLe_C
    FROM
           dbo.tblKetQuaHocTap                    kqht
           INNER JOIN dbo.TemplateBangDiemChiTiet AS tbdct ON tbdct.CotDiemID   = kqht.CotDiemID
                                                          AND tbdct.Enable      = 1
                                                          AND tbdct.MaCotDiem LIKE '%MucDoDanhGia%' + @HocKi
           INNER JOIN dbo.tblMonHocLop            mhl ON mhl.MonHocLopID        = kqht.MonHocLopID
                                                     AND mhl.TemplateBangDiemID = tbdct.TemplateBangDiemID
                                                     AND mhl.Enable             = 1
           INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID          = mhl.MonHocID
                                                       AND mh.Enable            = 1
           INNER JOIN dbo.tblLop                  l ON l.LopID                  = mhl.LopNhomID AND l.NienKhoa = mhl.NienKhoa
                                                   AND l.Enable                 = 1
                                                   AND l.CapID                  = 1
                                                   AND l.KhoiID IN (1, 2, 3, 4, 5)
           INNER JOIN dbo.tblHocSinh              AS hs ON hs.HocSinhID         = kqht.HocSinhID
                                                       AND hs.TinhTrang         = 0
    WHERE
           kqht.Enable = 1
      AND  mh.MonHocID NOT IN (   23 --	Phẩm chất-Yêu nước
                                , 24 --	Phẩm chất-Nhân ái
                                , 25 --	Phẩm chất-Chăm chỉ
                                , 26 --	Phẩm chất-Trung thực
                                , 27 --	Phẩm chất-Trách nhiệm
                                , 20 --Năng lực-Tự chủ và tự học
                                , 21 --Năng lực-Giao tiếp và hợp tác
                                , 22 --Năng lực-Giải quyết vấn đề và sáng tạo
                                , 28 --Năng lực-Ngôn ngữ
                                , 29 --Năng lực-Tính toán
                                , 30 --Năng lực-Khoa học
                                , 31 --Năng lực-Công nghệ
                                , 32 --Năng lực-Tin học
                                , 33 --Năng lực-Thẩm mĩ
                                , 34 --Năng lực-Thể chất
                              )
    GROUP BY
           mh.TenMonHoc_HienThi;

    -- Lấy danh hiệu khối từ 1 -> 4  => Cuối năm
    WITH TongSoHS AS
    (
        SELECT COUNT(HSLopID) AS Tong
        FROM
               dbo.tblKhenThuong
        WHERE
               KhoiID IN (1, 2, 3, 4, 5)
    )
    SELECT DanhHieu
         , COUNT(HSLopID)                                                AS SoHocSinh
         , CAST(COUNT(HSLopID) * 100.0 / TongSoHS.Tong AS DECIMAL(5, 2)) AS TiLe
    FROM
           dbo.tblKhenThuong
         , TongSoHS
    WHERE
           KhoiID IN (1, 2, 3, 4, 5)
      AND  DanhHieu <> ''
    GROUP BY
           DanhHieu
         , TongSoHS.Tong
    UNION
    SELECT N'Thư Khen'
         , COUNT(HSLopID)
         , CAST(COUNT(HSLopID) * 100.0 / TongSoHS.Tong AS DECIMAL(5, 2))
    FROM
           dbo.tblKhenThuong
         , TongSoHS
    WHERE
           ISNULL(NoiDungThuKhen, '') <> ''
      AND  KhoiID IN (1, 2, 3, 4, 5)
    GROUP BY
           TongSoHS.Tong;

    -- Lấy danh hiệu khối từ 5  => Cuối năm
    WITH TongSoHS AS
    (
        SELECT COUNT(HSLopID) AS Tong
        FROM
               dbo.tblKhenThuong
        WHERE
               KhoiID IN (5)
    )
    SELECT DanhHieu
         , COUNT(HSLopID)                                                AS SoHocSinh
         , CAST(COUNT(HSLopID) * 100.0 / TongSoHS.Tong AS DECIMAL(5, 2)) AS TiLe
    FROM
           dbo.tblKhenThuong
         , TongSoHS
    WHERE
           KhoiID IN (5)
      AND  DanhHieu <> ''
    GROUP BY
           DanhHieu
         , TongSoHS.Tong
    UNION
    SELECT N'Thư Khen'
         , COUNT(HSLopID)
         , CAST(COUNT(HSLopID) * 100.0 / TongSoHS.Tong AS DECIMAL(5, 2))
    FROM
           dbo.tblKhenThuong
         , TongSoHS
    WHERE
           ISNULL(NoiDungThuKhen, '') <> ''
      AND  KhoiID IN (5)
    GROUP BY
           TongSoHS.Tong;
END;



CREATE PROC [dbo].[spAPI_AnPham_Get_ByTrangThai]
    @TrangThai VARCHAR(10), -- MẢNG TRẠNG THÁI VÍ DỤ 1,2
    @SYS_UserID VARCHAR(9),
    @sys_SystemRight INT
AS
BEGIN

    DECLARE @MsgError NVARCHAR(500);

    IF (@sys_SystemRight NOT IN (1, 2, 9))
    BEGIN
        SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này ';
        RAISERROR(@MsgError, 16, 1);
        RETURN 0;
    END;


    DECLARE @tt AS TABLE
    (
        TrangThai VARCHAR(2)
    );

    INSERT INTO @tt(TrangThai)
    SELECT data
    FROM dbo.FN_STRING_SPLIT(@TrangThai, ',');


    DECLARE @tbl AS TABLE
    (
        AnPhamID INT,
        SoTienKhenThuong NUMERIC(18, 0),
        SoTienHoanPhiDangBai NUMERIC(18, 0),
        AnPhamTacGiaID INT,
        NguoiDaiDienQuyetToan BIT
    );

    INSERT INTO @tbl
    (
        AnPhamID,
        SoTienKhenThuong,
        SoTienHoanPhiDangBai,
        AnPhamTacGiaID,
        NguoiDaiDienQuyetToan
    )
    SELECT
        A.AnPhamID,
        SUM(ISNULL(A.SoTienKhenThuong, 0)) AS SoTienKhenThuong,
        SUM(ISNULL(A.SoTienHoanPhiDangBai, 0)) AS SoTienHoanPhiDangBai,
        A.AnPhamTacGiaID,
        A.NguoiDaiDienQuyetToan
    FROM dbo.AnPham_TacGia A
    INNER JOIN dbo.AnPham B
        ON A.AnPhamID = B.AnPhamID
    WHERE
        B.Is_Xoa = 0
        AND A.Is_Xoa = 0
        AND
        (
            B.TrangThai IN
            (
                SELECT CONVERT(TINYINT, TrangThai)
                FROM @tt
            )
            OR @TrangThai = '0'
        )
        AND B.Is_LocalStore = 0
    GROUP BY
        A.AnPhamID,
        A.AnPhamTacGiaID,
        A.NguoiDaiDienQuyetToan;


    SELECT DISTINCT

        ROW_NUMBER() OVER
        (
            ORDER BY
                A.TrangThai ASC,
                A.ThoiGianCapNhat,
                A.AnPhamID DESC
        ) AS STT,

        A.AnPhamID,
        A.DanhMucLoaiTapChiID,
        A.TenLoaiDanhMucTapChi,

        C.LoaiAnPhamID,
        C.TenLoaiAnPham,

        A.LoaiSubAnPhamID,
        A.TenLoaiSubAnPham,

        A.TenTapChi,
        A.TenAnPham,

        A.MaNhanVienDaiDien,


        /* =====================================================
           NGƯỜI ĐẠI DIỆN + TÀI KHOẢN

           Chỉ xét:
               IsNhanVien = 1

           Có đúng 1 nhân viên:
               NguoiDaiDienQuyetToan = 1
               => lấy người đó

           Ngược lại:
               => lấy tất cả tác giả là nhân viên
           ===================================================== */
        CASE
            WHEN
            (
                SELECT COUNT(*)
                FROM dbo.AnPham_TacGia TG_Count
                WHERE TG_Count.AnPhamID = A.AnPhamID
                    AND TG_Count.Is_Xoa = 0
                    AND TG_Count.Is_NhanVien = 1
                    AND TG_Count.NguoiDaiDienQuyetToan = 1
            ) = 1
            THEN
            (
                SELECT TOP 1
                    LTRIM(
                        RTRIM(
                            ISNULL(TG.HoTacGia, '')
                            + ' '
                            + ISNULL(TG.TenTacGia, '')
                        )
                    )
                    +
                    CASE
                        WHEN ISNULL(CONVERT(VARCHAR(100), TK.TaiKhoan), '') <> ''
                        THEN
                            ' - ' + CONVERT(VARCHAR(100), TK.TaiKhoan)
                        ELSE
                            ''
                    END
                FROM dbo.AnPham_TacGia TG
                LEFT JOIN dbo.TaiKhoan TK
                    ON TK.MaNV = TG.MaNhanVien
                WHERE TG.AnPhamID = A.AnPhamID
                    AND TG.Is_Xoa = 0
                    AND TG.Is_NhanVien = 1
                    AND TG.NguoiDaiDienQuyetToan = 1
            )

            ELSE

            (
                STUFF
                (
                    (
                        SELECT
                            ', '
                            +
                            LTRIM(
                                RTRIM(
                                    ISNULL(TG.HoTacGia, '')
                                    + ' '
                                    + ISNULL(TG.TenTacGia, '')
                                )
                            )
                            +
                            CASE
                                WHEN ISNULL(CONVERT(VARCHAR(100), TK.TaiKhoan), '') <> ''
                                THEN
                                    ' - ' + CONVERT(VARCHAR(100), TK.TaiKhoan)
                                ELSE
                                    ''
                            END

                        FROM dbo.AnPham_TacGia TG

                        LEFT JOIN dbo.TaiKhoan TK
                            ON TK.MaNV = TG.MaNhanVien

                        WHERE TG.AnPhamID = A.AnPhamID
                            AND TG.Is_Xoa = 0
                            AND TG.Is_NhanVien = 1

                        FOR XML PATH(''), TYPE
                    ).value('.', 'NVARCHAR(MAX)'),
                    1,
                    2,
                    ''
                )
            )
        END AS TenNhanVienDaiDien,


        A.DonViDaiDien,
        A.SoTacGia_LHU,
        A.DuongDanBaiBao,
        A.NamDangBai,
        A.NoiDangBai,
        A.DiemHoiDong,
        A.HeSo_IF,
        A.TenHeSoChatLuong,
        A.DiemHeSoChatLuong,
        A.PhiThongBao,

        E.SoTienKhenThuong,
        E.SoTienHoanPhiDangBai,

        E.SoTienKhenThuong
            + E.SoTienHoanPhiDangBai AS TongTienKhenThuong,

        A.ISSN,
        A.Dieu,
        A.Khoan,
        A.Muc,

        A.GhiChu,
        A.NhanVienCapNhat,


        /* =====================================================
           DANH SÁCH TẤT CẢ TÁC GIẢ
           Giữ nguyên logic cũ
           ===================================================== */
        STUFF
        (
            (
                SELECT
                    ', ' + B2.HoTacGia + ' ' + B2.TenTacGia
                FROM dbo.AnPham_TacGia B2
                WHERE B2.AnPhamID = A.AnPhamID
                    AND B2.Is_Xoa = 0
                FOR XML PATH('')
            ),
            1,
            2,
            ''
        ) AS TacGia,


        CASE
            WHEN A.TrangThai = 1 THEN N'Lưu tạm'
            WHEN A.TrangThai = 2 THEN N'Chờ duyệt'
            WHEN A.TrangThai = 3 THEN N'Đã duyệt'
            WHEN A.TrangThai = 4 THEN N'Đã ra quyết định khen thưởng'
            WHEN A.TrangThai = 5 THEN N'Bị từ chối'
            WHEN A.TrangThai = 6 THEN N'Phục hồi'
        END AS TrangThai,

        A.TrangThai AS TrangThaiID,

        CASE
            WHEN D.AnPhamID IS NULL THEN 0
            ELSE 1
        END AS DaGuiDashboard,

        A.NhomAnPham,

        CONVERT(VARCHAR(10), A.ThoiGianSubmit, 103) AS ThoiGianGui,

        A.ThoiGianCapNhat,
        A.AnPham_DotID,
        A.DotDuyet


    FROM dbo.AnPham A

    INNER JOIN dbo.AnPham_TacGia B
        ON B.AnPhamID = A.AnPhamID

    INNER JOIN dbo.AnPham_Loai C
        ON C.LoaiAnPhamID = A.LoaiAnPhamID

    INNER JOIN @tbl E
        ON A.AnPhamID = E.AnPhamID

    INNER JOIN dbo.AnPham_Dot F
        ON F.AnPham_DotID = A.AnPham_DotID
        AND F.AnPham_DotTinhTrang = 1

    LEFT JOIN dbo.BaiBaoKhoaHoc D
        ON D.AnPhamID = A.AnPhamID


    WHERE
        B.Is_Xoa = 0
        AND A.Is_Xoa = 0
        AND
        (
            A.TrangThai IN
            (
                SELECT CONVERT(TINYINT, TrangThai)
                FROM @tt
            )
            OR @TrangThai = '0'
        )
        AND A.Is_LocalStore = 0


    GROUP BY

        A.AnPhamID,
        A.DanhMucLoaiTapChiID,
        A.TenLoaiDanhMucTapChi,

        C.LoaiAnPhamID,
        C.TenLoaiAnPham,

        A.LoaiSubAnPhamID,
        A.TenLoaiSubAnPham,

        A.TenTapChi,
        A.TenAnPham,

        A.MaNhanVienDaiDien,

        A.DonViDaiDien,
        A.SoTacGia_LHU,
        A.DuongDanBaiBao,
        A.NamDangBai,
        A.NoiDangBai,
        A.DiemHoiDong,
        A.HeSo_IF,
        A.TenHeSoChatLuong,
        A.DiemHeSoChatLuong,
        A.PhiThongBao,
        A.PhiDangBai,

        A.ISSN,
        A.Dieu,
        A.Khoan,
        A.Muc,

        A.GhiChu,
        A.TrangThai,

        D.AnPhamID,

        A.NhomAnPham,
        A.ThoiGianSubmit,

        E.SoTienKhenThuong,
        E.SoTienHoanPhiDangBai,

        A.ThoiGianCapNhat,
        A.AnPham_DotID,
        A.DotDuyet,
        A.NhanVienCapNhat


    ORDER BY
        A.TrangThai ASC,
        A.ThoiGianCapNhat DESC,
        A.AnPhamID DESC;

END

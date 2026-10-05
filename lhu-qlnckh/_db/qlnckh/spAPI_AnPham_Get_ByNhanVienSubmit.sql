CREATE PROC [dbo].[spAPI_AnPham_Get_ByNhanVienSubmit] --  'NV0000666'
    @SYS_UserID VARCHAR(9)
AS
BEGIN
    IF @SYS_UserID = 'GV0000611'
        SET @SYS_UserID = 'NV0000742';
    SELECT DISTINCT
           ROW_NUMBER() OVER (ORDER BY A.TrangThai ASC, A.AnPhamID DESC) AS 'STT',
           A.AnPhamID,
           A.DanhMucLoaiTapChiID,
           A.TenLoaiDanhMucTapChi,
           C.LoaiAnPhamID,
           C.TenLoaiAnPham,
           A.LoaiSubAnPhamID,
           A.TenLoaiSubAnPham,
           A.[TenTapChi],
           A.[TenAnPham],
           A.[MaNhanVienDaiDien],
           A.[TenNhanVienDaiDien],
           A.[DonViDaiDien],
           A.[SoTacGia_LHU],
           A.[DuongDanBaiBao],
           A.[NamDangBai],
           A.[NoiDangBai],
           A.[DiemHoiDong],
           A.[HeSo_IF],
           A.[TenHeSoChatLuong],
           A.[DiemHeSoChatLuong],
           A.[PhiThongBao],
           A.[PhiDangBai],
           A.[HoanPhiDangBai],
           A.[ISSN],
           A.[Dieu],
           A.[Khoan],
           A.[Muc],
           A.[TongSoTienThuong],
           A.[GhiChu],
           STUFF(
           (
               SELECT ', ' + B.HoTacGia + ' ' + B.TenTacGia
               FROM [dbo].[AnPham_TacGia] B
               WHERE B.AnPhamID = A.AnPhamID
                     AND B.Is_Xoa = 0
               FOR XML PATH('')
           ),
           1,
           2,
           ''
                ) AS TacGia,
           --1: Lưu tạm; 2: Chờ Duyệt ; 3: Đã Duyệt; 4: Đã Ra quyết định khen thưởng
           CASE
               WHEN A.TrangThai = 1 THEN
                   N'Lưu tạm'
               WHEN A.TrangThai = 2 THEN
                   N'Chờ duyệt'
               WHEN A.TrangThai = 3 THEN
                   N'Đã duyệt'
               WHEN A.TrangThai = 4 THEN
                   N'Đã ra quyết định khen thưởng'
               WHEN A.TrangThai = 5 THEN
                   N'Bị từ chối'
           END TrangThai,
           A.TrangThai AS TrangThaiID,
           A.LyDoReject,
           A.NhomAnPham
    FROM AnPham A
        INNER JOIN [dbo].[AnPham_TacGia] B
            ON B.AnPhamID = A.AnPhamID
        INNER JOIN [dbo].[AnPham_Loai] C
            ON C.LoaiAnPhamID = A.LoaiAnPhamID
    WHERE B.Is_Xoa = 0
          AND A.Is_Xoa = 0
          --AND (A.NhanVienSubmit = @SYS_UserID OR @SYS_UserID = 'GV0000611')
          AND A.NhanVienSubmit = @SYS_UserID
          AND A.TrangThai <> 6 --(B.MaNhanVien = @SYS_UserID)
    GROUP BY A.AnPhamID,
             A.DanhMucLoaiTapChiID,
             A.TenLoaiDanhMucTapChi,
             C.LoaiAnPhamID,
             C.TenLoaiAnPham,
             A.LoaiSubAnPhamID,
             A.TenLoaiSubAnPham,
             A.[TenTapChi],
             A.[TenAnPham],
             A.[MaNhanVienDaiDien],
             A.[TenNhanVienDaiDien],
             A.[DonViDaiDien],
             A.[SoTacGia_LHU],
             A.[DuongDanBaiBao],
             A.[NamDangBai],
             A.[NoiDangBai],
             A.[DiemHoiDong],
             A.[HeSo_IF],
             A.[TenHeSoChatLuong],
             A.[DiemHeSoChatLuong],
             A.[PhiThongBao],
             A.[PhiDangBai],
             A.[HoanPhiDangBai],
             A.[ISSN],
             A.[Dieu],
             A.[Khoan],
             A.[Muc],
             A.[TongSoTienThuong],
             A.[GhiChu],
             A.[TrangThai],
             A.LyDoReject,
             A.NhomAnPham
    ORDER BY A.TrangThai ASC,
             A.AnPhamID DESC;
END;

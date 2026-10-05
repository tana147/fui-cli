-- [dbo].[spAPI_AnPham_KhenThuong_Get_ByTrangThai] '2,3','gv0000611',9
CREATE PROC [dbo].[spAPI_AnPham_KhenThuong_Get_ByTrangThai] -- '2,3','gv0000611',9
    @TrangThai       VARCHAR(10) -- MẢNG TRẠNG THÁI VÍ DỤ 1,2
  , @SYS_UserID      VARCHAR(9)
  , @sys_SystemRight INT
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
    INSERT @tt
    (
        TrangThai
    )
    SELECT Data
    FROM
           [dbo].[FN_STRING_SPLIT](@TrangThai, ',');

    --DECLARE @tbl AS TABLE(AnPhamID INT, SoTienKhenThuong NUMERIC(18,0), SoTienHoanPhiDangBai NUMERIC(18,0))
    --INSERT INTO @tbl(AnPhamID, SoTienKhenThuong, SoTienHoanPhiDangBai)
    --SELECT A.AnPhamID 
    --	,SUM(ISNULL(A.SoTienKhenThuong,0)) AS SoTienKhenThuong
    --	, SUM(ISNULL(A.SoTienHoanPhiDangBai,0)) AS SoTienHoanPhiDangBai 
    --FROM AnPham_TacGia A INNER JOIN AnPham B ON A.AnPhamID = B.AnPhamID
    --WHERE  B.Is_Xoa = 0 AND A.Is_Xoa = 0 AND (B.TrangThai IN (SELECT CONVERT(TINYINT, TrangThai) FROM @tt)  OR @TrangThai = '0')
    --GROUP BY A.AnPhamID

    SELECT DISTINCT
           ROW_NUMBER() OVER (ORDER BY
                                  A.TrangThai ASC
                                , A.AnPhamID DESC
                             )                                                 AS 'STT'
         , A.AnPhamID
         , A.DanhMucLoaiTapChiID
         , A.TenLoaiDanhMucTapChi
         , C.LoaiAnPhamID
         , C.TenLoaiAnPham
         , A.LoaiSubAnPhamID
         , A.TenLoaiSubAnPham
         , A.[TenTapChi]
         , A.[TenAnPham]
         , B.MaNhanVien
         , B.HoTacGia + ' ' + B.TenTacGia                                      AS HoTenTacGia
         , B.EmailTacGia
         , B.SoTaiKhoan
         , B.NganHang
         , CASE WHEN K.TenDonVi IS NULL THEN B.TenPhongBan ELSE K.TenDonVi END TenKhoa
         --, A.[DonViDaiDien]
         , A.[SoTacGia_LHU]
         , A.TongSoTacGia
         , A.[DuongDanBaiBao]
         , A.[NamDangBai]
         , A.[NoiDangBai]
         , A.[DiemHoiDong]
         , A.[HeSo_IF]
         , A.[TenHeSoChatLuong]
         , A.[DiemHeSoChatLuong]
         , A.[PhiThongBao]
         --, A.[PhiDangBai]
         --, A.[HoanPhiDangBai]
         , B.SoTienKhenThuong
         , B.SoTienHoanPhiDangBai
         , ISNULL(B.SoTienKhenThuong, 0) + ISNULL(B.SoTienHoanPhiDangBai, 0)   AS TongTienKhenThuong
         , A.[ISSN]
         , A.[Dieu]
         , A.[Khoan]
         , A.[Muc]
         --, A.[TongSoTienThuong]
         , A.[GhiChu]
         , STUFF((
                     SELECT ', ' + B.HoTacGia + ' ' + B.TenTacGia
                     FROM
                            [dbo].[AnPham_TacGia] B
                     WHERE
                            B.AnPhamID = A.AnPhamID
                       AND  B.Is_Xoa    = 0
                     FOR XML PATH('')
                 ), 1, 2, ''
                )                                                              AS TacGia
         --1: Lưu tạm; 2: Chờ Duyệt ; 3: Đã Duyệt; 4: Đã Ra quyết định khen thưởng
         , CASE
                WHEN A.TrangThai = 1 THEN N'Lưu tạm'
                WHEN A.TrangThai = 2 THEN N'Chờ duyệt'
                WHEN A.TrangThai = 3 THEN N'Đã duyệt'
                WHEN A.TrangThai = 4 THEN N'Đã ra quyết định khen thưởng'
                WHEN A.TrangThai = 5 THEN N'Bị từ chối'
                WHEN A.TrangThai = 6 THEN N'Phục hồi'
           END                                                                 TrangThai
         , A.TrangThai                                                         AS TrangThaiID
         , CASE WHEN D.AnPhamID IS NULL THEN 0 ELSE 1 END                      DaGuiDashboard
         , A.NhomAnPham
         , CONVERT(VARCHAR(10), A.ThoiGianSubmit, 103)                         AS ThoiGianGui
         , E.TenNhomHienThiExcel
    FROM
           dbo.AnPham                        A
           INNER JOIN [dbo].[AnPham_TacGia]  B ON B.AnPhamID				= A.AnPhamID
           INNER JOIN [dbo].[AnPham_Loai]    C ON C.LoaiAnPhamID			= A.LoaiAnPhamID
           INNER JOIN [dbo].[AnPham_Dot]     F ON F.[AnPham_DotID]			= A.[AnPham_DotID]
																		--AND F.[AnPham_DotTinhTrang] = 1
           LEFT JOIN [dbo].[AnPham_Loai_Sub] E ON E.LoaiSubAnPhamID       = A.LoaiSubAnPhamID
           LEFT JOIN [dbo].[BaiBaoKhoaHoc]   D ON D.AnPhamID              = A.AnPhamID
           LEFT JOIN dbo.DonVi               K ON B.TenPhongBan           = K.MaDonVi
    WHERE
           B.Is_Xoa                                                         = 0
      AND  A.Is_Xoa                                                          = 0
      AND
           (
               A.TrangThai IN
               (
                   SELECT CONVERT(TINYINT, TrangThai)
                   FROM
                       @tt
               )
          OR   @TrangThai                                                        = '0'
           )
      AND  ISNULL(B.SoTienKhenThuong, 0) + ISNULL(B.SoTienHoanPhiDangBai, 0) > 0
    GROUP BY
           A.AnPhamID
         , A.DanhMucLoaiTapChiID
         , A.TenLoaiDanhMucTapChi
         , C.LoaiAnPhamID
         , C.TenLoaiAnPham
         , A.LoaiSubAnPhamID
         , A.TenLoaiSubAnPham
         , A.[TenTapChi]
         , A.[TenAnPham]
         , B.MaNhanVien
         , B.HoTacGia
         , B.TenTacGia
         , B.EmailTacGia
         , B.SoTaiKhoan
         , B.NganHang
         , B.TenPhongBan
         , K.TenDonVi
         , A.[SoTacGia_LHU]
         , A.TongSoTacGia
         , A.[DuongDanBaiBao]
         , A.[NamDangBai]
         , A.[NoiDangBai]
         , A.[DiemHoiDong]
         , A.[HeSo_IF]
         , A.[TenHeSoChatLuong]
         , A.[DiemHeSoChatLuong]
         , A.[PhiThongBao]
         , A.[PhiDangBai]
         --, A.[HoanPhiDangBai]
         , A.[ISSN]
         , A.[Dieu]
         , A.[Khoan]
         , A.[Muc]
         --	, A.[TongSoTienThuong]
         , A.[GhiChu]
         , A.[TrangThai]
         , D.[AnPhamID]
         , A.NhomAnPham
         , A.ThoiGianSubmit
         , B.SoTienKhenThuong
         , B.SoTienHoanPhiDangBai
         , E.TenNhomHienThiExcel
    ORDER BY
           A.[TrangThai] ASC
         , A.AnPhamID DESC;

END;


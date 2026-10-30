CREATE PROC [dbo].[spAPI_BaoCao_2_ThongKe_GiaoVienThaoTacHocLieuSo_ByCapID]
    @CapID       INT
  , @KhoiID      INT
  , @NgayBatDau  DATE
  , @NgayKetThuc DATE
  , @NienKhoa    INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Niên khóa là mốc mặc định; ngày truyền riêng vẫn được ưu tiên để xem lại năm cũ hoặc một giai đoạn nhỏ.
    IF @NgayBatDau IS NULL AND @NienKhoa IS NOT NULL
        SET @NgayBatDau = DATEFROMPARTS(@NienKhoa, 8, 1);
    IF @NgayKetThuc IS NULL AND @NienKhoa IS NOT NULL
        SET @NgayKetThuc = DATEFROMPARTS(@NienKhoa + 1, 5, 31);

    -- Mỗi node tạo/cập nhật là một lần thao tác; không tính tài khoản kỹ thuật và không đếm cập nhật trùng người tạo.
    ;WITH Activity AS (
        SELECT
              hl.KhoiID
            , LTRIM(RTRIM(nd.CreateUser)) AS MaGV
            , nd.LoaiNoiDung
            , 'create' AS LoaiThaoTac
        FROM dbo.tblNoiDungHocLieu_FP nd
        INNER JOIN dbo.tblHocLieu_FP hl
            ON  hl.HocLieuID = nd.HocLieuID
            AND hl.Is_Xoa = 0
            AND hl.Loai = 'HOC_LIEU'
        INNER JOIN dbo.tblKhoi kh
            ON  kh.KhoiID = hl.KhoiID
            AND kh.CapID = @CapID
            AND kh.Enable = 1
        INNER JOIN dbo.tblMonHoc mh
            ON  mh.MonHocID = hl.MonHocID
            AND mh.CapID = @CapID
            AND mh.Enable = 1
        WHERE nd.Is_Xoa = 0
          AND NULLIF(LTRIM(RTRIM(nd.CreateUser)), '') IS NOT NULL
          AND UPPER(LTRIM(RTRIM(nd.CreateUser))) NOT IN ('NA0000022', 'LUAN')
          AND (@KhoiID = 0 OR hl.KhoiID = @KhoiID)
          AND (@NgayBatDau IS NULL OR CAST(nd.CreateTime AS DATE) >= @NgayBatDau)
          AND (@NgayKetThuc IS NULL OR CAST(nd.CreateTime AS DATE) <= @NgayKetThuc)

        UNION ALL

        SELECT
              hl.KhoiID
            , LTRIM(RTRIM(nd.UpdateUser)) AS MaGV
            , nd.LoaiNoiDung
            , 'update' AS LoaiThaoTac
        FROM dbo.tblNoiDungHocLieu_FP nd
        INNER JOIN dbo.tblHocLieu_FP hl
            ON  hl.HocLieuID = nd.HocLieuID
            AND hl.Is_Xoa = 0
            AND hl.Loai = 'HOC_LIEU'
        INNER JOIN dbo.tblKhoi kh
            ON  kh.KhoiID = hl.KhoiID
            AND kh.CapID = @CapID
            AND kh.Enable = 1
        INNER JOIN dbo.tblMonHoc mh
            ON  mh.MonHocID = hl.MonHocID
            AND mh.CapID = @CapID
            AND mh.Enable = 1
        WHERE nd.Is_Xoa = 0
          AND NULLIF(LTRIM(RTRIM(nd.UpdateUser)), '') IS NOT NULL
          AND UPPER(LTRIM(RTRIM(nd.UpdateUser))) NOT IN ('NA0000022', 'LUAN')
          AND UPPER(LTRIM(RTRIM(nd.UpdateUser))) <> UPPER(LTRIM(RTRIM(ISNULL(nd.CreateUser, ''))))
          AND (@KhoiID = 0 OR hl.KhoiID = @KhoiID)
          AND (@NgayBatDau IS NULL OR CAST(nd.UpdateTime AS DATE) >= @NgayBatDau)
          AND (@NgayKetThuc IS NULL OR CAST(nd.UpdateTime AS DATE) <= @NgayKetThuc)
    )
    SELECT
          a.KhoiID
        , a.MaGV
        , COALESCE(NULLIF(LTRIM(RTRIM(CONCAT(gv.HoGV, N' ', gv.TenGV))), N''), a.MaGV) AS TenGiaoVien
        , COUNT(*) AS TongThaoTac
        , SUM(CASE WHEN a.LoaiThaoTac = 'create' THEN 1 ELSE 0 END) AS SoMucThem
        , SUM(CASE WHEN a.LoaiThaoTac = 'update' THEN 1 ELSE 0 END) AS SoMucCapNhat
        , SUM(CASE WHEN UPPER(a.LoaiNoiDung) IN ('CHUONG', 'BAI', 'NHOM_KY_NANG') THEN 1 ELSE 0 END) AS SoCauTruc
        , SUM(CASE WHEN UPPER(a.LoaiNoiDung) LIKE 'QUIZ%' THEN 1 ELSE 0 END) AS SoCauHoi
        , SUM(CASE WHEN UPPER(a.LoaiNoiDung) NOT IN ('CHUONG', 'BAI', 'NHOM_KY_NANG')
                       AND UPPER(a.LoaiNoiDung) NOT LIKE 'QUIZ%' THEN 1 ELSE 0 END) AS SoHocLieu
    FROM Activity a
    LEFT JOIN dbo.tblGiaoVien gv
        ON UPPER(LTRIM(RTRIM(gv.GiaoVienID))) = UPPER(a.MaGV)
    GROUP BY
          a.KhoiID
        , a.MaGV
        , COALESCE(NULLIF(LTRIM(RTRIM(CONCAT(gv.HoGV, N' ', gv.TenGV))), N''), a.MaGV)
    ORDER BY TongThaoTac DESC, TenGiaoVien;
END

CREATE PROC [dbo].[spAPI_BaoCao_2_ChiTietGiaoVienThaoTacHocLieuSo_ByCapID]
    @CapID       INT
  , @KhoiID      INT
  , @MaGV        VARCHAR(50)
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

    -- Trả từng node và từng loại thao tác để nút "Xem chi tiết" giải thích được giáo viên đã làm gì.
    SELECT
          hl.KhoiID
        , hl.MonHocID
        , mh.TenMonHoc_HienThi
        , hl.HocLieuID
        , hl.TenHocLieu
        , nd.NoiDungID
        , nd.ParentID
        , nd.TenNoiDung
        , nd.LoaiNoiDung
        , LTRIM(RTRIM(@MaGV)) AS MaGV
        -- Dùng Unicode literal để không làm mất dấu tiếng Việt khi tAPI trả JSON.
        , N'Tạo' AS LoaiThaoTac
        , nd.CreateTime AS ThoiGianThaoTac
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
      AND UPPER(LTRIM(RTRIM(nd.CreateUser))) = UPPER(LTRIM(RTRIM(@MaGV)))
      AND UPPER(LTRIM(RTRIM(nd.CreateUser))) NOT IN ('NA0000022', 'LUAN')
      AND (@KhoiID = 0 OR hl.KhoiID = @KhoiID)
      AND (@NgayBatDau IS NULL OR CAST(nd.CreateTime AS DATE) >= @NgayBatDau)
      AND (@NgayKetThuc IS NULL OR CAST(nd.CreateTime AS DATE) <= @NgayKetThuc)

    UNION ALL

    SELECT
          hl.KhoiID
        , hl.MonHocID
        , mh.TenMonHoc_HienThi
        , hl.HocLieuID
        , hl.TenHocLieu
        , nd.NoiDungID
        , nd.ParentID
        , nd.TenNoiDung
        , nd.LoaiNoiDung
        , LTRIM(RTRIM(@MaGV)) AS MaGV
        , N'Cập nhật' AS LoaiThaoTac
        , nd.UpdateTime AS ThoiGianThaoTac
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
      AND UPPER(LTRIM(RTRIM(nd.UpdateUser))) = UPPER(LTRIM(RTRIM(@MaGV)))
      AND UPPER(LTRIM(RTRIM(nd.UpdateUser))) NOT IN ('NA0000022', 'LUAN')
      AND UPPER(LTRIM(RTRIM(nd.UpdateUser))) <> UPPER(LTRIM(RTRIM(ISNULL(nd.CreateUser, ''))))
      AND (@KhoiID = 0 OR hl.KhoiID = @KhoiID)
      AND (@NgayBatDau IS NULL OR CAST(nd.UpdateTime AS DATE) >= @NgayBatDau)
      AND (@NgayKetThuc IS NULL OR CAST(nd.UpdateTime AS DATE) <= @NgayKetThuc)
    ORDER BY ThoiGianThaoTac DESC, KhoiID, MonHocID, HocLieuID, NoiDungID;
END

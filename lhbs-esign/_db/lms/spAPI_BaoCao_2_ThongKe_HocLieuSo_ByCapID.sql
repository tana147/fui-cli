
CREATE PROC [dbo].[spAPI_BaoCao_2_ThongKe_HocLieuSo_ByCapID]
    @CapID       INT
  , @NgayBatDau  DATE
  , @NgayKetThuc DATE
  , @NienKhoa    INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Khi màn hình truyền niên khóa nhưng không truyền ngày riêng, dùng toàn bộ năm học đó.
    IF @NgayBatDau IS NULL AND @NienKhoa IS NOT NULL
        SET @NgayBatDau = DATEFROMPARTS(@NienKhoa, 8, 1);
    IF @NgayKetThuc IS NULL AND @NienKhoa IS NOT NULL
        SET @NgayKetThuc = DATEFROMPARTS(@NienKhoa + 1, 5, 31);

    -- ================================================================
    -- CTE: Đếm nội dung của từng học liệu, có filter khoảng ngày
    -- ================================================================
    ;WITH HL AS (
        SELECT
              hl.HocLieuID
            , hl.TenHocLieu
            , hl.MonHocID
            , mh.TenMonHoc_HienThi
            , hl.KhoiID
            , COUNT(ndhl.NoiDungID) AS SoNoiDung
            , SUM(CASE
                    WHEN ndhl.NoiDungID IS NOT NULL
                     AND (
                            (
                                (@NgayBatDau IS NULL OR CAST(ndhl.CreateTime AS DATE) >= @NgayBatDau)
                                AND (@NgayKetThuc IS NULL OR CAST(ndhl.CreateTime AS DATE) <= @NgayKetThuc)
                            )
                            OR
                            (
                                (@NgayBatDau IS NULL OR CAST(ndhl.UpdateTime AS DATE) >= @NgayBatDau)
                                AND (@NgayKetThuc IS NULL OR CAST(ndhl.UpdateTime AS DATE) <= @NgayKetThuc)
                            )
                         )
                    THEN 1 ELSE 0
                  END) AS SoNoiDungTrongKhoang
        FROM dbo.tblHocLieu_FP hl
        INNER JOIN dbo.tblMonHoc mh
            ON  mh.MonHocID = hl.MonHocID
            AND mh.Enable   = 1
            AND mh.CapID    = @CapID
        LEFT JOIN dbo.tblNoiDungHocLieu_FP ndhl
            ON  ndhl.HocLieuID = hl.HocLieuID
            AND ndhl.Is_Xoa    = 0
        INNER JOIN dbo.tblKhoi kh
            ON  kh.KhoiID = hl.KhoiID
            AND kh.CapID  = @CapID
            AND kh.Enable = 1
        WHERE hl.Is_Xoa = 0
          AND hl.Loai   = 'HOC_LIEU'
        GROUP BY
              hl.HocLieuID
            , hl.TenHocLieu
            , hl.MonHocID
            , mh.TenMonHoc_HienThi
            , hl.KhoiID
    )
    SELECT
          MonHocID
        , TenMonHoc_HienThi
        , KhoiID
        , COUNT(HocLieuID)                                 AS TongHocLieu
        , SUM(CASE WHEN SoNoiDung > 0 THEN 1 ELSE 0 END)  AS HocLieuCoNoiDung
        , SUM(CASE WHEN SoNoiDungTrongKhoang > 0 THEN 1 ELSE 0 END) AS HocLieuCoNoiDungTrongKhoang
        , SUM(CASE WHEN SoNoiDung = 0 THEN 1 ELSE 0 END)  AS HocLieuChuaCoNoiDung
        , SUM(SoNoiDung)                                   AS TongNoiDung
        , SUM(SoNoiDungTrongKhoang)                        AS TongNoiDungTrongKhoang
    FROM HL
    GROUP BY
          MonHocID
        , TenMonHoc_HienThi
        , KhoiID
    -- Giữ cả học liệu chưa có nội dung để các cột TongHocLieu,
    -- HocLieuCoNoiDung và HocLieuChuaCoNoiDung phản ánh đủ tổng số.
    ORDER BY KhoiID, MonHocID;
END

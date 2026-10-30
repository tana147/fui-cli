CREATE PROCEDURE [dbo].[spAPI_ThongKeXepLoaiKyNangAV_TheoLop_HK1]
  @JsonLop NVARCHAR(MAX),
  @HocKy       NVARCHAR(20)
AS
BEGIN
  SET NOCOUNT ON;

  --------------------------------------------------
  -- 1) Đọc danh sách lớp từ JSON
  --------------------------------------------------
  DECLARE @Classes TABLE (LopID VARCHAR(9));
  INSERT INTO @Classes(LopID)
    SELECT value FROM OPENJSON(@JsonLop);

  --------------------------------------------------
  -- 2) Xác định prefix cột điểm theo @HocKy
  --------------------------------------------------
  DECLARE @Prefix NVARCHAR(10) =
    CASE @HocKy
      WHEN N'Giữa HK1' THEN N'S1_Mid'
      WHEN N'Cuối HK1' THEN N'S1_Final'
      WHEN N'Giữa HK2' THEN N'S2_Mid'
      WHEN N'Cuối HK2' THEN N'S2_Final'
      ELSE NULL
    END;
  IF @Prefix IS NULL
  BEGIN
    RAISERROR(
      'Giá trị @HocKy không hợp lệ. Phải là: Giữa HK1, Cuối HK1, Giữa HK2, hoặc Cuối HK2.',
      16,1
    );
    RETURN;
  END

  --------------------------------------------------
  -- 3) Danh sách 5 mã cột + 4) 3 mức đánh giá
  --------------------------------------------------
  DECLARE @MaCotList TABLE (MaCotDiem NVARCHAR(50));
  INSERT INTO @MaCotList VALUES
    (@Prefix + N'_TA2_Listening_Conv'),
    (@Prefix + N'_TA2_Reading_Conv'),
    (@Prefix + N'_TA2_Writing_Conv'),
    (@Prefix + N'_TA2_Speaking_Conv'),
    (@Prefix + N'_TA2_Avg_Conv');

  DECLARE @Cats TABLE (KetQuaDanhGia_VI NVARCHAR(100), ThuTu INT);
	INSERT INTO @Cats VALUES
	  (N'Exceeding requirements/Vượt đạt',    1),
	  (N'Meeting Requirements/Đạt',            2),
	  (N'Not Meeting Requirements/Chưa đạt',   3);

  --------------------------------------------------
  -- 5) CTE Agg: tính SoLuong + Total như trước
  --------------------------------------------------
  ;WITH Agg AS (
    SELECT
      kq.LopID,
      tp.MaCotDiem,
      kq.KetQuaDanhGia_VI,
      COUNT(*)       AS SoLuong,
      SUM(COUNT(*)) 
        OVER (PARTITION BY kq.LopID, tp.MaCotDiem) AS Total
    FROM tblKetQuaHocTap kq
    JOIN TemplateBangDiemChiTiet tp ON tp.CotDiemID = kq.CotDiemID
    JOIN tblHocSinh hs             ON hs.HocSinhID = kq.HocSinhID
    JOIN @Classes c                ON c.LopID = kq.LopID
    WHERE kq.Enable = 1
      AND hs.TinhTrang = 0
    GROUP BY kq.LopID, tp.MaCotDiem, kq.KetQuaDanhGia_VI
  ),
  --------------------------------------------------
  -- 6) CTE Raw: tạo đủ 3 mức, zero-fill, tính tỷ lệ thô
  --------------------------------------------------
  Raw AS (
  SELECT
    x.LopID,
    x.MaCotDiem,
    cats.KetQuaDanhGia_VI,
    cats.ThuTu,
    ISNULL(a.SoLuong, 0) AS SoLuong,
    ISNULL(100.0 * a.SoLuong / NULLIF(a.Total,0), 0)
      AS PercentRawUnrounded,
    -- tổng thô trên cả 3 mức
    SUM(ISNULL(100.0 * a.SoLuong / NULLIF(a.Total,0), 0))
      OVER (PARTITION BY x.LopID, x.MaCotDiem)
      AS SumRawUnrounded,
    -- tìm ThuTu cuối có SoLuong>0
    MAX(CASE WHEN ISNULL(a.SoLuong,0) > 0 THEN cats.ThuTu ELSE NULL END)
      OVER (PARTITION BY x.LopID, x.MaCotDiem)
      AS LastNzThuTu
  FROM (
    SELECT c.LopID, m.MaCotDiem
    FROM @Classes c
    CROSS JOIN @MaCotList m
  ) AS x
  CROSS JOIN @Cats AS cats
  LEFT JOIN Agg AS a
  ON a.LopID = x.LopID
 AND a.MaCotDiem = x.MaCotDiem
 AND REPLACE(a.KetQuaDanhGia_VI, N' ', N'') = REPLACE(cats.KetQuaDanhGia_VI, N' ', N'')
),
Pct AS (
  SELECT
    LopID, MaCotDiem, KetQuaDanhGia_VI, ThuTu,
    SoLuong, PercentRawUnrounded, SumRawUnrounded, LastNzThuTu
  FROM Raw
)

SELECT
  x.LopID,
  n.TenNhom,
  x.MaCotDiem,
  cats.KetQuaDanhGia_VI,
  p.SoLuong,
  CASE
    WHEN p.SoLuong = 0 THEN 0.00
    WHEN cats.ThuTu = p.LastNzThuTu THEN
      ROUND(
        p.PercentRawUnrounded 
        + (100.0 - p.SumRawUnrounded)
      , 2)
    ELSE
      ROUND(p.PercentRawUnrounded, 2)
  END AS TyLeChinhSua
FROM (
  SELECT LopID, MaCotDiem
  FROM @Classes c
  CROSS JOIN @MaCotList m
) AS x
JOIN tblNhom n
  ON n.NhomID = x.LopID
  and n.IsNhomLMS_GiaoBai = 0
CROSS JOIN @Cats AS cats
JOIN Pct AS p
  ON p.LopID            = x.LopID
 AND p.MaCotDiem        = x.MaCotDiem
 AND p.KetQuaDanhGia_VI = cats.KetQuaDanhGia_VI
ORDER BY
  x.LopID,
 
  CASE
    WHEN x.MaCotDiem LIKE '%_Listening_%' THEN 1
    WHEN x.MaCotDiem LIKE '%_Reading_%'  THEN 2
    WHEN x.MaCotDiem LIKE '%_Writing_%'  THEN 3
    WHEN x.MaCotDiem LIKE '%_Speaking_%' THEN 4
    WHEN x.MaCotDiem LIKE '%_Avg_%'      THEN 5
    ELSE 6  -- phòng trường hợp khác
  END,
  cats.ThuTu;
END

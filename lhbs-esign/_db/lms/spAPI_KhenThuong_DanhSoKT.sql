
CREATE PROC [dbo].[spAPI_KhenThuong_DanhSoKT]
    @JsonKhoi    NVARCHAR(MAX)
  , @NienKhoa   INT
  , @PreviewOnly BIT
AS
BEGIN
    DECLARE @KhoiUuTien TABLE
    (
        ThuTu  INT IDENTITY(1, 1)
      , KhoiID NVARCHAR(50)
    );
    INSERT INTO @KhoiUuTien (KhoiID)
    SELECT Value FROM OPENJSON(@JsonKhoi);

    DECLARE @DanhHieuUuTien TABLE
    (
        Cap      INT
      , DanhHieu NVARCHAR(200)
      , ThuTuDH  INT
    );
    INSERT INTO @DanhHieuUuTien (Cap, DanhHieu, ThuTuDH)
    VALUES
    (1, N'Học sinh Xuất sắc',                                                 1),
    (1, N'Học sinh Tiêu biểu hoàn thành tốt trong học tập và rèn luyện',      2),
    (2, N'Học sinh Xuất sắc',                                                 1),
    (2, N'Học sinh Giỏi',                                                     2),
    (3, N'Học sinh Xuất sắc',                                                 1),
    (3, N'Học sinh Giỏi',                                                     2);

    -- Đưa kết quả ranked vào table variable để dùng lại
    DECLARE @RankedKhenThuong TABLE
    (
        HSLopID      INT
      , VaoSoKT_Cu   INT
      , HoTen        NVARCHAR(200)
      , TenLop       NVARCHAR(100)
      , SoDanhBo     NVARCHAR(50)
      , KhoiID       NVARCHAR(50)
      , Cap          INT
      , DanhHieu     NVARCHAR(200)
      , SoThuTuMoi   INT
    );

    INSERT INTO @RankedKhenThuong
    (
        HSLopID, VaoSoKT_Cu, HoTen, TenLop, SoDanhBo, KhoiID, Cap, DanhHieu, SoThuTuMoi
    )
    SELECT
        kt.HSLopID
      , kt.VaoSoKT
      , hs.Ho + ' ' + hs.Ten
      , L.TenLop
      , HSL.SoDanhBo
      , kt.KhoiID
      , CASE
            WHEN TRY_CAST(kt.KhoiID AS INT) BETWEEN 1  AND 5  THEN 1
            WHEN TRY_CAST(kt.KhoiID AS INT) BETWEEN 6  AND 9  THEN 2
            WHEN TRY_CAST(kt.KhoiID AS INT) BETWEEN 10 AND 12 THEN 3
            ELSE 9
        END
      , kt.DanhHieu
      , ROW_NUMBER() OVER (
            ORDER BY
                CASE
                    WHEN TRY_CAST(kt.KhoiID AS INT) BETWEEN 1  AND 5  THEN 1
                    WHEN TRY_CAST(kt.KhoiID AS INT) BETWEEN 6  AND 9  THEN 2
                    WHEN TRY_CAST(kt.KhoiID AS INT) BETWEEN 10 AND 12 THEN 3
                    ELSE 9
                END
              , COALESCE(dh.ThuTuDH, 9999)
              , COALESCE(kut.ThuTu, 9999)
              , L.TenLop
              , HSL.SoDanhBo
        )
    FROM
           dbo.tblKhenThuong            kt
           INNER JOIN dbo.tblHocSinhLop HSL ON kt.HSLopID   = HSL.HSLopID
           INNER JOIN dbo.tblHocSinh    hs  ON hs.HocSinhID = HSL.HocSinhID
           INNER JOIN dbo.tblLop        L   ON L.LopID      = HSL.LopID AND L.NienKhoa = @NienKhoa
           AND HSL.NienKhoa = L.NienKhoa
        LEFT  JOIN @KhoiUuTien       kut ON kt.KhoiID    = kut.KhoiID
           LEFT  JOIN @DanhHieuUuTien   dh  ON dh.Cap       = CASE
                                                                   WHEN TRY_CAST(kt.KhoiID AS INT) BETWEEN 1  AND 5  THEN 1
                                                                   WHEN TRY_CAST(kt.KhoiID AS INT) BETWEEN 6  AND 9  THEN 2
                                                                   WHEN TRY_CAST(kt.KhoiID AS INT) BETWEEN 10 AND 12 THEN 3
                                                                   ELSE 9
                                               END
                                             AND dh.DanhHieu = kt.DanhHieu
    WHERE
           ISNULL(kt.Is_DaIn, 0)   = 0
      AND  ISNULL(kt.DanhHieu, '') <> ''
      AND  kt.NienKhoa             = @NienKhoa;

    -- Preview hoặc Update dùng chung @RankedKhenThuong
    IF @PreviewOnly = 1
        SELECT
            rkt.SoThuTuMoi   AS VaoSoKT_Moi
          , rkt.VaoSoKT_Cu
          , rkt.KhoiID
          , rkt.Cap
          , rkt.TenLop
          , rkt.SoDanhBo
          , rkt.HoTen
          , rkt.DanhHieu
        FROM @RankedKhenThuong rkt
        ORDER BY rkt.SoThuTuMoi;
    ELSE
    BEGIN
        UPDATE kt
        SET kt.VaoSoKT = rkt.SoThuTuMoi
        FROM
               dbo.tblKhenThuong          kt
               INNER JOIN @RankedKhenThuong rkt ON kt.HSLopID = rkt.HSLopID
        WHERE
               ISNULL(kt.Is_DaIn, 0)   = 0
          AND  ISNULL(kt.DanhHieu, '') <> ''
          AND  kt.NienKhoa             = @NienKhoa;

        SELECT CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' bản ghi đã được cập nhật.' AS ThongBao;
    END

END;
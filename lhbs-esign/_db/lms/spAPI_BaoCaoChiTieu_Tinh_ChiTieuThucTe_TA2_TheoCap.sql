CREATE PROCEDURE [dbo].[spAPI_BaoCaoChiTieu_Tinh_ChiTieuThucTe_TA2_TheoCap]
    @Semester VARCHAR(20) = '1',
    @NienKhoa INT = 2025,
    @MonHocID INT = 76,
    @CapID INT = 3,
    @LopID VARCHAR(20)
AS
BEGIN

DECLARE @PrefixCotDiem varchar(20) = 'S'
DECLARE @AppendCotDiem varchar(20) = '_Final_TA2_Avg_Conv'

DECLARE @TableNhom  as Table (LopID varchar(20))
INSERT INTO @TableNhom(LopID)
SELECT LTRIM(RTRIM(value))
FROM STRING_SPLIT(@LopID, ',');

   DECLARE @TableNhomALL  as Table (LopID varchar(20))
INSERT INTO @TableNhomALL(LopID)
SELECT NhomID
FROM tblNhom WHERE NienKhoa = @NienKhoa and KhoiID = CASE WHEN @LopID = 'N100000' THEN 10 WHEN @LopID = 'N110000' THEN 11 ELSE 12 END;

    DECLARE @ChiTieu TABLE
    (
        ChiTieu_ID INT,
        NhomID varchar(20),
        TenMucDo NVARCHAR(200)
    );
        INSERT INTO @ChiTieu
        (
            ChiTieu_ID,
            NhomID,
            TenMucDo
        )
        SELECT ct.ChiTieu_ID,
                ct.NhomID,
               md.TenMucDo
        FROM tbl_ChiTieu ct
            INNER JOIN tbl_MucDo md
                ON md.MucDo_ID = ct.MucDo_ID
        WHERE ct.NhomID IS NOT NULL
              AND ((@Semester = '1' AND ct.MucDo_ID = 14) OR (@Semester = '2' AND ct.MucDo_ID = 15))
              AND ct.NhomID in (SELECT LopID FROM @TableNhom);

    WITH DiemHS
    AS (
        SELECT hs.HocSinhID,
               kqht.KetQuaDanhGia_VI AS DiemTrungBinh
        FROM tblHocSinh hs
            LEFT JOIN tblHocSinhNhom hsn
                ON hsn.HocSinhID = hs.HocSinhID
                   AND hsn.Enable = 1
            LEFT JOIN tblMonHocLop mhl
                ON mhl.LopNhomID = hsn.NhomID
                   AND mhl.MonHocID = @MonHocID
                   AND mhl.NienKhoa = @NienKhoa
            LEFT JOIN TemplateBangDiem tbd
                ON tbd.TemplateBangDiemID = mhl.TemplateBangDiemID
            LEFT JOIN TemplateBangDiemChiTiet ct
                ON ct.TemplateBangDiemID = tbd.TemplateBangDiemID
                   AND ct.MaCotDiem = @PrefixCotDiem + @Semester + @AppendCotDiem
                   AND ct.Enable = 1
            LEFT JOIN tblKetQuaHocTap kqht
                ON kqht.HocSinhID = hs.HocSinhID
                   AND kqht.CotDiemID = ct.CotDiemID
                   AND kqht.NienKhoa = @NienKhoa
        WHERE hs.TinhTrang = 0
               AND (hsn.NhomID in (SELECT LopID FROM @TableNhom)  OR (@LopID in ('N100000','N110000','N120000') AND hsn.NhomID in (SELECT LopID FROM @TableNhomALL)))),
         KetQua  AS (
            SELECT 
                c.TenMucDo,
               c.ChiTieu_ID,
               CAST(SUM(   CASE
                               WHEN  d.DiemTrungBinh like N'Exceeding%' OR d.DiemTrungBinh like N'Meeting%'
                               THEN
                                   1
                               ELSE
                                   0
                           END
                       ) * 100.0 /
                    (
                        SELECT COUNT(*) FROM DiemHS
                    ) AS DECIMAL(5, 2)) AS TiLePhanTram
        FROM @ChiTieu c
            CROSS JOIN DiemHS d
        GROUP BY c.TenMucDo,
                 c.ChiTieu_ID
				 
	)
    UPDATE ct
    SET ChiTieuThucTe = kq.TiLePhanTram
    FROM tbl_ChiTieu ct
        INNER JOIN KetQua kq
            ON kq.ChiTieu_ID = ct.ChiTieu_ID
               AND ct.HocKi = CAST(@Semester AS INT)
               AND ct.MucDo_ID in (14,15)
               AND ct.NhomID in (SELECT LopID FROM @TableNhom);
END;
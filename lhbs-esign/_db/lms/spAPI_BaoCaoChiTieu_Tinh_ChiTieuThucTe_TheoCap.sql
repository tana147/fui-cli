CREATE PROCEDURE [dbo].[spAPI_BaoCaoChiTieu_Tinh_ChiTieuThucTe_TheoCap]
    @Semester VARCHAR(20) = '2',
    @NienKhoa INT = 2025,
    @MonHocID INT = 46,
    @CapID INT = 2,
    @LopID VARCHAR(40)
AS
BEGIN
    DECLARE @MaCotDiem VARCHAR(100) = 'S'+@Semester+'_Final_Total_Point';
    DECLARE @DiemHS TABLE(HocSinhID INT, DiemTrungBinh decimal(18,2))

    IF (@CapID = 1)
    BEGIN
        SET @MaCotDiem = 'DiemTBCK_HK' + @Semester;
    END;

    DECLARE @ChiTieu TABLE
    (
        ChiTieu_ID INT,
        Prefix VARCHAR(5),
        Suffix VARCHAR(5),
        TenMucDo NVARCHAR(200),
        DiemMin DECIMAL(9, 2),
        DiemMax DECIMAL(9, 2)
    );

    IF @CapID IN ( 1, 2 )
    BEGIN
        IF(@LopID in (
            '-625',
            '-725',
            '-825',
            '-925',
            '-125',
            '-225',
            '-325',
            '-425',
            '-525'
        ))
        BEGIN 
                DECLARE @TableLopC1C2 table (LopID varchar(20),CapID int)
                INSERT INTO @TableLopC1C2(LopID,CapID)
                SELECT LopID,CapID FROM tblLop 
                WHERE CapID = @CapID and NienKhoa= @NienKhoa and Enable = 1
        END
    
        
            INSERT INTO @DiemHS(HocSinhID, DiemTrungBinh)
            SELECT hs.HocSinhID,
                   kqht.KetQuaDanhGia_VI AS DiemTrungBinh
            FROM tblHocSinh hs
                LEFT JOIN tblHocSinhLop hsl
                    ON hsl.HocSinhID = hs.HocSinhID
                LEFT JOIN tblMonHocLop mhl
                    ON mhl.LopNhomID = hsl.LopID
                       AND mhl.MonHocID = @MonHocID
                       AND mhl.NienKhoa = @NienKhoa
                LEFT JOIN TemplateBangDiem tbd
                    ON tbd.TemplateBangDiemID = mhl.TemplateBangDiemID
                LEFT JOIN TemplateBangDiemChiTiet ct
                    ON ct.TemplateBangDiemID = tbd.TemplateBangDiemID
                       AND ct.MaCotDiem = @MaCotDiem
                       AND ct.Enable = 1
                LEFT JOIN tblKetQuaHocTap kqht
                    ON kqht.HocSinhID = hs.HocSinhID
                       AND kqht.CotDiemID = ct.CotDiemID
                       AND kqht.NienKhoa = @NienKhoa
            WHERE hs.TinhTrang = 0
                  AND (hsl.LopID = @LopID OR ( @LopID in (
               '-625',
               '-725',
               '-825',
               '-925',
               '-125',
               '-225',
               '-325',
               '-425',
               '-525'
            ) AND hsl.LopID in (SELECT LopID FROM @TableLopC1C2 WHERE CapID = @CapID)))

            INSERT INTO @ChiTieu
            (
                ChiTieu_ID,
                Prefix,
                Suffix,
                TenMucDo,
                DiemMin,
                DiemMax
            )
            SELECT ct.ChiTieu_ID,
                   ct.Prefix,
                   ct.Suffix,
                   md.TenMucDo,
                   ct.DiemMin,
                   ct.DiemMax
            FROM tbl_ChiTieu ct
                INNER JOIN tbl_MucDo md
                    ON md.MucDo_ID = ct.MucDo_ID
            WHERE ct.LopID = @LopID;
    END;
    ELSE
    BEGIN

        INSERT INTO @DiemHS(HocSinhID, DiemTrungBinh)
        SELECT hs.HocSinhID,
               kqht.KetQuaDanhGia_VI AS DiemTrungBinh
        FROM tblHocSinh hs
            LEFT JOIN tblHocSinhNhom hsn
                ON hsn.HocSinhID = hs.HocSinhID
            LEFT JOIN tblMonHocLop mhl
                ON mhl.LopNhomID = hsn.NhomID
                   AND mhl.MonHocID = @MonHocID
                   AND mhl.NienKhoa = @NienKhoa
            LEFT JOIN TemplateBangDiem tbd
                ON tbd.TemplateBangDiemID = mhl.TemplateBangDiemID
            LEFT JOIN TemplateBangDiemChiTiet ct
                ON ct.TemplateBangDiemID = tbd.TemplateBangDiemID
                   AND ct.MaCotDiem = @MaCotDiem
                   AND ct.Enable = 1
            LEFT JOIN tblKetQuaHocTap kqht
                ON kqht.HocSinhID = hs.HocSinhID
                   AND kqht.CotDiemID = ct.CotDiemID
                   AND kqht.NienKhoa = @NienKhoa
        WHERE hs.TinhTrang = 0
              AND (hsn.NhomID = @LopID 
                   OR (
                        @LopID in ('N100000','N110000','N120000')) 
                        AND 
                        hsn.NhomID in (SELECT NhomID FROM tblNhom WHERE Enable = 1 
                                                                        and NienKhoa = @NienKhoa 
                                                                        and KhoiID = CASE   WHEN @LopID = 'N100000' THEN 10 
                                                                                            WHEN @LopID = 'N110000' THEN 11 
                                                                                            ELSE 12 END
                                      )
                      )

        INSERT INTO @ChiTieu
        (
            ChiTieu_ID,
            Prefix,
            Suffix,
            TenMucDo,
            DiemMin,
            DiemMax
        )
        SELECT ct.ChiTieu_ID,
               ct.Prefix,
               ct.Suffix,
               md.TenMucDo,
               ct.DiemMin,
               ct.DiemMax
        FROM tbl_ChiTieu ct
            INNER JOIN tbl_MucDo md
                ON md.MucDo_ID = ct.MucDo_ID
        WHERE ct.NhomID IS NOT NULL
              AND ct.MucDo_ID NOT IN ( 14, 15 )
              AND ct.NhomID = @LopID;
    END;

    WITH DiemHS
    AS 
    (
        SELECT * FROM @DiemHS
    ),
    KetQua
    AS (SELECT c.TenMucDo,
               c.ChiTieu_ID,
               SUM(   CASE
                          WHEN
                      -- điều kiện prefix
                      (
                          (
                              c.Prefix = '<'
                              AND ISNULL(d.DiemTrungBinh, 0) < c.DiemMin
                          )
                          OR
                          (
                              c.Prefix = '<='
                              AND ISNULL(d.DiemTrungBinh, 0) <= c.DiemMin
                          )
                      )
                      AND
                      -- điều kiện suffix
                      (
                          (
                              c.Suffix = '<'
                              AND ISNULL(d.DiemTrungBinh, 0) < c.DiemMax
                          )
                          OR
                          (
                              c.Suffix = '<='
                              AND ISNULL(d.DiemTrungBinh, 0) <= c.DiemMax
                          )
                      ) THEN
                              1
                          ELSE
                              0
                      END
                  ) AS SoHocSinh,
               CAST(SUM(   CASE
                               WHEN -- điều kiện prefix
                           (
                               (
                                   c.Prefix = '<'
                                   AND ISNULL(d.DiemTrungBinh, 0) > c.DiemMin
                               )
                               OR
                               (
                                   c.Prefix = '<='
                                   AND ISNULL(d.DiemTrungBinh, 0) >= c.DiemMin
                               )
                           )
                           AND
                           -- điều kiện suffix
                           (
                               (
                                   c.Suffix = '<'
                                   AND ISNULL(d.DiemTrungBinh, 0) < c.DiemMax
                               )
                               OR
                               (
                                   c.Suffix = '<='
                                   AND ISNULL(d.DiemTrungBinh, 0) <= c.DiemMax
                               )
                           ) THEN
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
               AND ct.HocKi = CAST(@Semester AS INT) ;
   
END;
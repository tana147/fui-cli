
CREATE PROC [dbo].[spAPI_fn_HocSinh_KeoDiem_C3]
    @JsonData   NVARCHAR(MAX)
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();

    DECLARE @Table_QLD_C3 TABLE
    (
        TenLop             VARCHAR(20)
      , LopID              VARCHAR(50)
      , HocSinhID          INT
      , MonHocCode         NVARCHAR(100)
      , MonHocID           INT
      , MonHocLopID        INT
      , TX1                NVARCHAR(10)
      , TX2                NVARCHAR(10)
      , TX3                NVARCHAR(10)
      , TX4                NVARCHAR(10)
      , TX5                NVARCHAR(10)
      , GK                 NVARCHAR(10)
      , CK                 NVARCHAR(10)
      , DTB                NVARCHAR(10)
      , HocKi              NVARCHAR(10)
      , DiemTB_CaNam       NVARCHAR(10)
      , TemplateBangDiemID INT
    );

    INSERT INTO @Table_QLD_C3
    (
        TenLop
      , HocSinhID
      , MonHocCode
      , TX1
      , TX2
      , TX3
      , TX4
      , TX5
      , GK
      , CK
      , DTB
      , DiemTB_CaNam
      , HocKi
    )
    SELECT TenLop
         , HocSinhID
         , MonHocID
         , TX1
         , TX2
         , TX3
         , TX4
         , TX5
         , GK
         , CK
         , DTB
         , DiemTB_CaNam
         , HocKi
    FROM
           OPENJSON(@JsonData)
           WITH
           (
               TenLop VARCHAR(20)
             , HocSinhID INT
             , MonHocID NVARCHAR(100)
             , TX1 NVARCHAR(10)
             , TX2 NVARCHAR(10)
             , TX3 NVARCHAR(10)
             , TX4 NVARCHAR(10)
             , TX5 NVARCHAR(10)
             , GK NVARCHAR(10)
             , CK NVARCHAR(10)
             , DTB NVARCHAR(10)
             , DiemTB_CaNam NVARCHAR(10)
             , HocKi NVARCHAR(10)
           );

    -- Map lớp gốc / nhóm / môn học lớp
    UPDATE T
    SET    T.MonHocID = mh.MonHocID
         , T.MonHocLopID = mhl.MonHocLopID
         , T.TemplateBangDiemID = mhl.TemplateBangDiemID
         , T.LopID = CASE
                          WHEN T.MonHocCode IN ('anh', 'tin', 'td') THEN hsn.NhomID
                          ELSE CAST(l.LopID AS VARCHAR(50))
                     END
    FROM
           @Table_QLD_C3                 T
           INNER JOIN dbo.tblLop         l ON l.TenLop        = T.TenLop
                                          AND l.NienKhoa      = @NienKhoa
                                          AND l.Enable        = 1
           INNER JOIN dbo.tblMonHoc      mh ON mh.MonHocCode  = T.MonHocCode
                                           AND mh.CapID       = 3
                                           AND mh.Enable      = 1
			LEFT JOIN dbo.tblHocSinhNhom hsn ON hsn.HocSinhID = T.HocSinhID
                                 AND hsn.Enable    = 1
                               --  AND hsn.LopID     = l.LopID
                                 AND EXISTS (
                                     SELECT 1 
                                     FROM dbo.tblMonHocLop mhl2
                                     WHERE mhl2.LopNhomID = CONVERT(VARCHAR(50), hsn.NhomID)
                                       AND mhl2.MonHocID  = mh.MonHocID
                                       AND mhl2.Enable    = 1
                                       AND mhl2.NienKhoa  = @NienKhoa
                                 )
           left JOIN dbo.tblMonHocLop   mhl ON mhl.LopNhomID = CASE
                                                                     WHEN T.MonHocCode IN ('anh', 'tin', 'td') THEN CONVERT(VARCHAR(50), hsn.NhomID)
                                                                     ELSE CONVERT(VARCHAR(50), l.LopID)
                                                                END
                                            AND mhl.MonHocID  = mh.MonHocID
                                            AND mhl.Enable    = 1
                                            AND mhl.NienKhoa  = @NienKhoa;


    DECLARE @tbl_KQHT TABLE
    (
        KQHTID             INT
      , LopID              VARCHAR(50)
      , HocSinhID          INT
      , MonHocID           INT
      , MonHocLopID        INT
      , TemplateBangDiemID INT
      , CotDiemID          INT
      , KetQua_KQHT        NVARCHAR(MAX)
      , KetQua_QLD         NVARCHAR(MAX)
      , KhoaCotDiemID      INT
    );

    INSERT INTO @tbl_KQHT
    (
        KQHTID
      , LopID
      , HocSinhID
      , MonHocID
      , MonHocLopID
      , TemplateBangDiemID
      , CotDiemID
      , KetQua_KQHT
      , KetQua_QLD
    )
    SELECT KQHT.KQHTID
         , T.LopID
         , T.HocSinhID
         , T.MonHocID
         , T.MonHocLopID
         , T.TemplateBangDiemID
         , TCT.CotDiemID
         , KQHT.KetQuaDanhGia_VI
         , CASE
                WHEN TCT.MaCotDiem IN ('DiemGK_' + T.HocKi) THEN T.GK
                WHEN TCT.MaCotDiem IN ('DiemCK_' + T.HocKi) THEN T.CK
                WHEN T.HocKi <> 'CaNam'
                 AND TCT.MaCotDiem IN ('DiemTB_' + T.HocKi) THEN T.DTB
                WHEN T.HocKi = 'CaNam'
                 AND TCT.MaCotDiem IN ('DiemTB_' + T.HocKi) THEN T.DiemTB_CaNam
           END
    FROM
           @Table_QLD_C3                          AS T
           INNER JOIN dbo.TemplateBangDiemChiTiet AS TCT ON TCT.TemplateBangDiemID = T.TemplateBangDiemID
                                                        AND
                                                            (
                                                                -- GK/CK: chỉ kéo điểm cho 8 môn được phép
                                                                -- (103=Toán, 104=Ngữ văn,  100=Lịch sử,
                                                                --  91=Vật lí, 88=Hóa học, 79=Địa lí, 84=GDKT&PL
																--97=Sinh học)
                                                                (
                                                                    TCT.MaCotDiem IN ('DiemGK_' + T.HocKi, 'DiemCK_' + T.HocKi)
                                                               AND  T.MonHocID IN (103, 104,   100, 91, 88, 79, 84, 97)
                                                                )
                                                                -- DTB / DiemTB_CaNam: lấy tất cả môn, nhưng chỉ khi có giá trị
                                                           OR   (   T.HocKi      <> 'CaNam' AND TCT.MaCotDiem IN ('DiemTB_' + T.HocKi) AND T.DTB           IS NOT NULL)
                                                           OR   (   T.HocKi       = 'CaNam' AND TCT.MaCotDiem IN ('DiemTB_' + T.HocKi) AND T.DiemTB_CaNam IS NOT NULL)
                                                            )
           LEFT JOIN dbo.tblKetQuaHocTap          AS KQHT ON KQHT.MonHocLopID      = T.MonHocLopID
                                                         AND KQHT.HocSinhID        = T.HocSinhID
                                                         AND KQHT.CotDiemID        = TCT.CotDiemID
                                                         AND KQHT.Enable           = 1
                                                         AND KQHT.NienKhoa         = @NienKhoa;
 
    DECLARE @tbl_NewKhoaCotDiem TABLE
    (
        KhoaCotDiemID INT
      , LopID         VARCHAR(50)
      , MonHocLopID   INT
      , MaCotDiem     NVARCHAR(200)
    );

    INSERT INTO dbo.tblKhoaCotDiem
    (
        LopID
      , MonHocLopID
      , MaCotDiem
      , Enable
      , TinhTrang
      , CreateUser
      , CreateTime
    )
    OUTPUT INSERTED.KhoaCotDiemID
         , CONVERT(VARCHAR(50), INSERTED.LopID)
         , INSERTED.MonHocLopID
         , INSERTED.MaCotDiem
    INTO @tbl_NewKhoaCotDiem
    (
        KhoaCotDiemID
      , LopID
      , MonHocLopID
      , MaCotDiem
    )
    SELECT DISTINCT
           t.LopID
         , t.MonHocLopID
         , tct.MaCotDiem
         , 1
         , 1
         , @SYS_USERID
         , GETDATE()
    FROM
           @tbl_KQHT                              AS t
           INNER JOIN dbo.TemplateBangDiemChiTiet AS tct ON tct.CotDiemID = t.CotDiemID
    WHERE
           NOT EXISTS
    (
        SELECT 1
        FROM
               dbo.tblKhoaCotDiem kcd
        WHERE
               kcd.LopID      = t.LopID
          AND  kcd.MonHocLopID = t.MonHocLopID
          AND  kcd.MaCotDiem   = tct.MaCotDiem
    );

    UPDATE t
    SET    t.KhoaCotDiemID = COALESCE(nkcd.KhoaCotDiemID, kcd.KhoaCotDiemID)
    FROM
           @tbl_KQHT                              t
           INNER JOIN dbo.TemplateBangDiemChiTiet tct ON tct.CotDiemID     = t.CotDiemID
           LEFT JOIN dbo.tblKhoaCotDiem           kcd ON kcd.LopID         = t.LopID
                                                     AND kcd.MonHocLopID   = t.MonHocLopID
                                                     AND kcd.MaCotDiem     = tct.MaCotDiem
                                                     AND kcd.Enable        = 1
           LEFT JOIN @tbl_NewKhoaCotDiem          nkcd ON nkcd.LopID       = t.LopID
                                                      AND nkcd.MonHocLopID = t.MonHocLopID
                                                      AND nkcd.MaCotDiem   = tct.MaCotDiem;

    UPDATE kd
    SET    kd.KetQuaDanhGia_VI = CASE
                                      WHEN t.MonHocID IN (83, 86, 101) THEN CASE
                                                                                 WHEN t.KetQua_QLD = '9'
                                                                                   OR t.KetQua_QLD = N'Đ' THEN N'Đ'
                                                                                 ELSE N'CĐ'
                                                                            END
                                      ELSE ISNULL(t.KetQua_QLD, kd.KetQuaDanhGia_VI)
                                 END
         , kd.KetQuaDanhGia_EN = CASE
                                      WHEN t.MonHocID IN (83, 86, 101) THEN CASE
                                                                                 WHEN t.KetQua_QLD = '9'
                                                                                   OR t.KetQua_QLD = N'Đ' THEN N'Đ'
                                                                                 ELSE N'CĐ'
                                                                            END
                                      ELSE ISNULL(t.KetQua_QLD, kd.KetQuaDanhGia_EN)
                                 END
         , kd.KhoaCotDiemID = t.KhoaCotDiemID
         , kd.UpdateUser = @SYS_USERID
         , kd.UpdateTime = GETDATE()
         , kd.NhapDiemUser = @SYS_USERID
         , kd.NhapDiemTime = GETDATE()
    FROM
           dbo.tblKetQuaHocTap  kd
           INNER JOIN @tbl_KQHT t ON kd.HocSinhID   = t.HocSinhID
                                 AND kd.MonHocLopID = t.MonHocLopID
                                 AND kd.CotDiemID   = t.CotDiemID
                                 AND kd.LopID       = t.LopID
                                 AND kd.NienKhoa    = @NienKhoa
                                 AND kd.Enable      = 1
    WHERE
           ISNULL(t.KetQua_QLD, '')            <> ''
      AND
           (
               ISNUMERIC(t.KetQua_QLD)         = 0
          OR   TRY_CAST(t.KetQua_QLD AS FLOAT) >= 0
           )
      AND  CASE
                WHEN t.MonHocID IN (83, 86, 101) THEN CASE
                                                           WHEN kd.KetQuaDanhGia_VI = '9'
                                                             OR kd.KetQuaDanhGia_VI = N'Đ' THEN N'Đ'
                                                           ELSE N'CĐ'
                                                      END
                ELSE ISNULL(kd.KetQuaDanhGia_VI, '')
           END                                 <> CASE
                                                       WHEN t.MonHocID IN (83, 86, 101) THEN CASE
                                                                                                  WHEN t.KetQua_QLD = '9'
                                                                                                    OR t.KetQua_QLD = N'Đ' THEN N'Đ'
                                                                                                  ELSE N'CĐ'
                                                                                             END
                                                       ELSE t.KetQua_QLD
                                                  END;

    INSERT INTO dbo.tblKetQuaHocTap
    (
        MonHocLopID
      , HocSinhID
      , LopID
      , NienKhoa
      , CotDiemID
      , KetQuaDanhGia_VI
      , KetQuaDanhGia_EN
      , KhoaCotDiemID
      , Enable
      , CreateUser
      , CreateTime
      , NhapDiemUser
      , NhapDiemTime
    )
    SELECT t.MonHocLopID
         , t.HocSinhID
         , t.LopID
         , @NienKhoa
         , t.CotDiemID
         , CASE
                WHEN t.MonHocID IN (83, 86, 101) THEN CASE
                                                           WHEN t.KetQua_QLD = '9'
                                                             OR t.KetQua_QLD = N'Đ' THEN N'Đ'
                                                           ELSE N'CĐ'
                                                      END
                ELSE t.KetQua_QLD
           END
         , CASE
                WHEN t.MonHocID IN (83, 86, 101) THEN CASE
                                                           WHEN t.KetQua_QLD = '9'
                                                             OR t.KetQua_QLD = N'Đ' THEN N'Đ'
                                                           ELSE N'CĐ'
                                                      END
                ELSE t.KetQua_QLD
           END
         , t.KhoaCotDiemID
         , 1
         , @SYS_USERID
         , GETDATE()
         , @SYS_USERID
         , GETDATE()
    FROM
           @tbl_KQHT t
    WHERE
           NOT EXISTS
    (
        SELECT 1
        FROM
               dbo.tblKetQuaHocTap kd
        WHERE
               kd.HocSinhID  = t.HocSinhID
          AND  kd.MonHocLopID = t.MonHocLopID
          AND  kd.CotDiemID   = t.CotDiemID
          AND  kd.LopID       = t.LopID
          AND  kd.NienKhoa    = @NienKhoa
          AND  kd.Enable      = 1
    );
END;
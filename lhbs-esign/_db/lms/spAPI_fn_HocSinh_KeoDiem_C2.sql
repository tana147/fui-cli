
CREATE PROC [dbo].[spAPI_fn_HocSinh_KeoDiem_C2]
    @JsonData   NVARCHAR(MAX)
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();

    -- =============================================
    -- Bước 1: Parse JSON
    -- =============================================
    DECLARE @Table_QLD_C2 TABLE
    (
        TenLop             VARCHAR(20)
      , LopID              INT
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
	   , DiemTB_CaNam          NVARCHAR(10) 
      , HocKi              NVARCHAR(10)
      , TemplateBangDiemID INT
    );

    INSERT INTO @Table_QLD_C2
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
    FROM OPENJSON(@JsonData)
    WITH
    (
        TenLop      VARCHAR(20)
      , HocSinhID    INT
      , MonHocID     NVARCHAR(100)
      , TX1          NVARCHAR(10)
      , TX2          NVARCHAR(10)
      , TX3          NVARCHAR(10)
      , TX4          NVARCHAR(10)
      , TX5          NVARCHAR(10)
      , GK           NVARCHAR(10)
      , CK           NVARCHAR(10)
      , DTB          NVARCHAR(10)
	 , DiemTB_CaNam          NVARCHAR(10)
      , HocKi        NVARCHAR(10)
    );

    -- =============================================
    -- Bước 2: Map LopID, MonHocID, MonHocLopID, TemplateBangDiemID
    -- =============================================
    UPDATE T
    SET    T.LopID              = l.LopID
         , T.MonHocID           = mh.MonHocID
         , T.MonHocLopID        = mhl.MonHocLopID
         , T.TemplateBangDiemID = mhl.TemplateBangDiemID
    FROM @Table_QLD_C2 AS T
    INNER JOIN dbo.tblLop AS l
        ON l.TenLop = T.TenLop
       AND l.NienKhoa = @NienKhoa
       AND l.Enable = 1
    INNER JOIN dbo.tblMonHoc AS mh
        ON mh.MonHocCode = T.MonHocCode
       AND mh.CapID = 2
       AND mh.Enable = 1
    INNER JOIN dbo.tblMonHocLop AS mhl
        ON mhl.LopNhomID = CONVERT(VARCHAR, l.LopID)
       AND mhl.MonHocID = mh.MonHocID
       AND mhl.Enable = 1
       AND mhl.NienKhoa = @NienKhoa;

    -- =============================================
    -- Bước 3: Bảng tạm kết quả
    -- Logic:
    --   - GK, CK : chỉ áp dụng cho môn trong danh sách (73,74,52,56,60)
    --   - DTB    : áp dụng cho tất cả môn (không filter MonHocID)
    -- =============================================
    DECLARE @tbl_KQHT TABLE
    (
        KQHTID             INT
      , LopID              INT
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
                WHEN T.HocKi <> 'CaNam' AND TCT.MaCotDiem IN ('DiemTB_' + T.HocKi) THEN T.DTB
				WHEN t.HocKi = 'CaNam' AND TCT.MaCotDiem IN ('DiemTB_' + T.HocKi) THEN T.DiemTB_CaNam
           END AS KetQua_QLD
    FROM @Table_QLD_C2 AS T
    INNER JOIN dbo.TemplateBangDiemChiTiet AS TCT
        ON T.TemplateBangDiemID = TCT.TemplateBangDiemID
       AND (
                TCT.MaCotDiem IN ('DiemGK_' + T.HocKi, 'DiemCK_' + T.HocKi)
             OR (T.HocKi <> 'CaNam' AND TCT.MaCotDiem IN ('DiemTB_' + T.HocKi))
			  OR (T.HocKi = 'CaNam' AND TCT.MaCotDiem IN ('DiemTB_' + T.HocKi))
           )
    LEFT JOIN dbo.tblKetQuaHocTap AS KQHT
        ON KQHT.MonHocLopID = T.MonHocLopID
       AND KQHT.Enable = 1
       AND KQHT.HocSinhID = T.HocSinhID
       AND KQHT.CotDiemID = TCT.CotDiemID
       AND KQHT.NienKhoa = @NienKhoa
   WHERE
    -- GK, CK: chỉ xử lý cho môn trong danh sách
    (
        TCT.MaCotDiem IN ('DiemGK_' + T.HocKi, 'DiemCK_' + T.HocKi)
        AND T.MonHocID IN (73, 74, 52, 56, 60)
        AND ISNULL(CASE WHEN TCT.MaCotDiem = 'DiemGK_' + T.HocKi THEN T.GK
                        WHEN TCT.MaCotDiem = 'DiemCK_' + T.HocKi THEN T.CK
                   END, '') <> ''   -- ← thêm: bỏ qua nếu không có giá trị
    )
    OR
    -- DTB HK1/HK2: tất cả môn, nhưng phải có giá trị
    (
        TCT.MaCotDiem IN ('DiemTB_' + T.HocKi)
        AND T.HocKi <> 'CaNam'
        AND ISNULL(T.DTB, '') <> ''          -- ← thêm: bỏ qua nếu DTB null/empty
    )
    OR
    -- DTB CaNam: tất cả môn, nhưng phải có giá trị
    (
        TCT.MaCotDiem IN ('DiemTB_' + T.HocKi)
        AND T.HocKi = 'CaNam'
        AND ISNULL(T.DiemTB_CaNam, '') <> '' -- ← thêm: bỏ qua nếu DiemTB_CaNam null/empty
    );

    -- =============================================
    -- Bước 4: Insert KhoaCotDiem nếu chưa tồn tại
    -- =============================================
    DECLARE @tbl_NewKhoaCotDiem TABLE
    (
        KhoaCotDiemID INT
      , LopID         INT
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
         , INSERTED.LopID
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
    FROM @tbl_KQHT AS t
    INNER JOIN dbo.TemplateBangDiemChiTiet AS tct
        ON tct.CotDiemID = t.CotDiemID
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.tblKhoaCotDiem AS kcd
        WHERE kcd.LopID = t.LopID
          AND kcd.MonHocLopID = t.MonHocLopID
          AND kcd.MaCotDiem = tct.MaCotDiem
    );

    -- =============================================
    -- Bước 5: Map KhoaCotDiemID vào @tbl_KQHT
    -- =============================================
    UPDATE t
    SET t.KhoaCotDiemID = COALESCE(nkcd.KhoaCotDiemID, kcd.KhoaCotDiemID)
    FROM @tbl_KQHT AS t
    INNER JOIN dbo.TemplateBangDiemChiTiet AS tct
        ON tct.CotDiemID = t.CotDiemID
    LEFT JOIN dbo.tblKhoaCotDiem AS kcd
        ON kcd.LopID = t.LopID
       AND kcd.MonHocLopID = t.MonHocLopID
       AND kcd.MaCotDiem = tct.MaCotDiem
       AND kcd.Enable = 1
    LEFT JOIN @tbl_NewKhoaCotDiem AS nkcd
        ON nkcd.LopID = t.LopID
       AND nkcd.MonHocLopID = t.MonHocLopID
       AND nkcd.MaCotDiem = tct.MaCotDiem;

    -- =============================================
    -- Bước 6: Update record đã tồn tại
    -- Fix: dùng t.KetQua_QLD (giá trị mới) thay vì kd.KetQuaDanhGia_VI (giá trị cũ)
    --      để convert Đ/CĐ cho đúng
    -- =============================================
    UPDATE kd
    SET    kd.KetQuaDanhGia_VI = CASE
                                    WHEN t.MonHocID IN (53, 55, 65, 71)
                                    THEN CASE WHEN t.KetQua_QLD = '9' OR t.KetQua_QLD = N'Đ' THEN N'Đ' ELSE N'CĐ' END
                                    ELSE ISNULL(t.KetQua_QLD, kd.KetQuaDanhGia_VI)
                                 END
         , kd.KetQuaDanhGia_EN = CASE
                                    WHEN t.MonHocID IN (53, 55, 65, 71)
                                    THEN CASE WHEN t.KetQua_QLD = '9' OR t.KetQua_QLD = N'Đ' THEN N'Đ' ELSE N'CĐ' END
                                    ELSE ISNULL(t.KetQua_QLD  , kd.KetQuaDanhGia_EN )
                                 END
         , kd.KhoaCotDiemID    = t.KhoaCotDiemID
         , kd.UpdateUser       = @SYS_USERID
         , kd.UpdateTime       = GETDATE()
         , kd.NhapDiemUser     = @SYS_USERID
         , kd.NhapDiemTime     = GETDATE()
    FROM dbo.tblKetQuaHocTap AS kd
    INNER JOIN @tbl_KQHT AS t
        ON t.HocSinhID = kd.HocSinhID
       AND t.MonHocLopID = kd.MonHocLopID
       AND t.CotDiemID = kd.CotDiemID
    WHERE kd.Enable = 1
      AND ISNULL(t.KetQua_QLD, '') <> ''
      AND
      (
            ISNUMERIC(t.KetQua_QLD) = 0
         OR TRY_CAST(t.KetQua_QLD AS FLOAT) >= 0
      )
      AND kd.NienKhoa = @NienKhoa
      AND CASE
            WHEN t.MonHocID IN (53, 55, 65, 71)
            THEN CASE WHEN kd.KetQuaDanhGia_VI = '9' OR t.KetQua_QLD = N'Đ' THEN N'Đ' ELSE N'CĐ' END
            ELSE ISNULL(kd.KetQuaDanhGia_VI, '')
          END
          <> CASE
                WHEN t.MonHocID IN (53, 55, 65, 71)
                THEN CASE WHEN t.KetQua_QLD = '9' OR t.KetQua_QLD = N'Đ' THEN N'Đ' ELSE N'CĐ' END
                ELSE t.KetQua_QLD
             END;
	
    -- =============================================
    -- Bước 7: Insert record chưa tồn tại
    -- =============================================
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
                WHEN t.MonHocID IN (53, 55, 65, 71)
                THEN CASE WHEN t.KetQua_QLD = '9' OR t.KetQua_QLD = N'Đ' THEN N'Đ' ELSE N'CĐ' END
                ELSE t.KetQua_QLD
           END
         , CASE
                WHEN t.MonHocID IN (53, 55, 65, 71)
                THEN CASE WHEN t.KetQua_QLD = '9' OR t.KetQua_QLD = N'Đ' THEN N'Đ' ELSE N'CĐ' END
                ELSE t.KetQua_QLD
           END
         , t.KhoaCotDiemID
         , 1
         , @SYS_USERID
         , GETDATE()
         , @SYS_USERID
         , GETDATE()
    FROM @tbl_KQHT AS t
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.tblKetQuaHocTap AS kd
        WHERE t.HocSinhID = kd.HocSinhID
          AND t.MonHocLopID = kd.MonHocLopID
          AND t.CotDiemID = kd.CotDiemID
          AND kd.NienKhoa = @NienKhoa
          AND kd.Enable = 1
    );
END
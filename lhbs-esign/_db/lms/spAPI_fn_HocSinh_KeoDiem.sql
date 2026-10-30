
CREATE PROC [dbo].[spAPI_fn_HocSinh_KeoDiem]
    @NienKhoa   INT = 2025
  , @JsonData   NVARCHAR(MAX)
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    -- Bước 1. ParseJSON QLD vào table @Table_QLD_CAP1
    -- Bước 2. Dựa Theo Tên Môn Học Trong JSON -> Tìm MonHocID -> TemplateBangDiemID -> CotDiemID
    -- Bước 3. Tạo bảng tạm, Insert CotDiemID vào bảng tạm
    -- Bước 4. Mapping Diem vào table Tạm
    -- Bước 5. Insert KhoaCotDiem nếu chưa có, sau đó map KhoaCotDiemID
    -- Bước 6. Insert / Update giá trị xuống tblKetQuaHocTap theo KQHTID

    -- =============================================
    -- Bước 1: ParseJSON
    -- =============================================
    DECLARE @Table_QLD_CAP1 TABLE
    (
        TenLop             VARCHAR(20)
      , LopID              INT
      , HocSinhID          INT
      , TenMon             NVARCHAR(100)
      , MonHocID           INT
      , MonHocLopID        INT
      , MucDoDanhGia       NVARCHAR(2000)
      , DiemMonHoc         NVARCHAR(2000)
      , NhanXet            NVARCHAR(2000)
      , ThoiDiemDanhGia    VARCHAR(3)
      , MaNhomDiem         VARCHAR(50)
      , Semester           VARCHAR(3)
      , TemplateBangDiemID INT
    );

    INSERT INTO @Table_QLD_CAP1
    (
        TenLop
      , HocSinhID
      , TenMon
      , MucDoDanhGia
      , DiemMonHoc
      , NhanXet
      , ThoiDiemDanhGia
    )
    SELECT *
    FROM
           OPENJSON(@JsonData)
           WITH
           (
               TenLop         VARCHAR(20)
             , HocSinhID       INT
             , TenMon          NVARCHAR(100)
             , MucDoDanhGia    NVARCHAR(2000)
             , DiemMonHoc      NVARCHAR(2000)
             , NhanXet         NVARCHAR(2000)
             , ThoiDiemDanhGia VARCHAR(3)
           );

    -- =============================================
    -- Bước 2: Update LopID, MonHocID, MonHocLopID, TemplateBangDiemID
    -- =============================================
    UPDATE T
    SET    T.LopID              = l.LopID
         , T.MonHocID           = mh.MonHocID
         , T.MonHocLopID        = mhl.MonHocLopID
         , T.TemplateBangDiemID = mhl.TemplateBangDiemID
    FROM
           @Table_QLD_CAP1             AS T
           INNER JOIN dbo.tblLop       AS l   ON l.TenLop       = T.TenLop
                                             AND l.NienKhoa     = @NienKhoa
                                             AND l.Enable       = 1
           INNER JOIN dbo.tblMonHoc    AS mh  ON mh.MonHocName  = T.TenMon
                                             AND mh.CapID       = 1
                                             AND mh.Enable      = 1
           INNER JOIN dbo.tblMonHocLop AS mhl ON mhl.LopNhomID  = CONVERT(VARCHAR, l.LopID)
                                             AND mhl.MonHocID   = mh.MonHocID
                                             AND mhl.Enable     = 1
                                             AND mhl.NienKhoa   = @NienKhoa;

    -- Chỉ giữ lại các môn được phép
    DELETE t
    FROM   @Table_QLD_CAP1 t
    WHERE  t.MonHocID NOT IN (1, 2, 3, 4, 5, 19, 35);

    -- Update MaNhomDiem, Semester
    UPDATE t
    SET    t.MaNhomDiem = CASE
                               WHEN t.ThoiDiemDanhGia = 'GK1' THEN 'GK_HK1'
                               WHEN t.ThoiDiemDanhGia = 'CK1' THEN 'CK_HK1'
                               WHEN t.ThoiDiemDanhGia = 'GK2' THEN 'GK_HK2'
                               WHEN t.ThoiDiemDanhGia = 'CK2' THEN 'CK_HK2'
                               ELSE ''
                          END
         , t.Semester   = CASE
                               WHEN t.ThoiDiemDanhGia = 'GK1' THEN 'HK1'
                               WHEN t.ThoiDiemDanhGia = 'CK1' THEN 'HK1'
                               WHEN t.ThoiDiemDanhGia = 'GK2' THEN 'HK2'
                               WHEN t.ThoiDiemDanhGia = 'CK2' THEN 'HK2'
                               ELSE ''
                          END
    FROM   @Table_QLD_CAP1 AS t;

    -- =============================================
    -- Bước 3: Khai báo @tbl_KQHT
    -- =============================================
    DECLARE @tbl_KQHT TABLE
    (
        KQHTID             INT
      , LopID              INT
      , HocSinhID          INT
      , MonHocID           INT
      , MonHocLopID        INT
      , ThoiDiemDanhGia    VARCHAR(3)
      , TemplateBangDiemID INT
      , CotDiemID          INT
      , MaNhomCotDiem      NVARCHAR(200)
      , KetQua_KQHT        NVARCHAR(MAX)
      , KetQua_QLD         NVARCHAR(MAX)
      , KhoaCotDiemID      INT
    );

    -- =============================================
    -- Bước 4: Insert dữ liệu vào @tbl_KQHT
    -- =============================================
    INSERT INTO @tbl_KQHT
    (
        KQHTID
      , LopID
      , HocSinhID
      , MonHocID
      , MonHocLopID
      , ThoiDiemDanhGia
      , TemplateBangDiemID
      , CotDiemID
      , MaNhomCotDiem
      , KetQua_KQHT
      , KetQua_QLD
    )
    SELECT KQHT.KQHTID
         , T.LopID
         , T.HocSinhID
         , T.MonHocID
         , T.MonHocLopID
         , T.ThoiDiemDanhGia
         , T.TemplateBangDiemID
         , TCT.CotDiemID
         , TCT.MaNhomCotDiem
         , KQHT.KetQuaDanhGia_VI
         , CASE
                WHEN TCT.MaCotDiem IN ('Diem' + T.MaNhomDiem) THEN T.DiemMonHoc
           END AS KetQua_QLD
    FROM
           @Table_QLD_CAP1                       AS T
           INNER JOIN dbo.TemplateBangDiemChiTiet AS TCT  ON TCT.TemplateBangDiemID = T.TemplateBangDiemID
                                                         AND TCT.MaCotDiem          IN ('Diem' + T.MaNhomDiem)
           LEFT JOIN  dbo.tblKetQuaHocTap         AS KQHT ON KQHT.MonHocLopID       = T.MonHocLopID
                                                         AND KQHT.Enable            = 1
                                                         AND KQHT.HocSinhID         = T.HocSinhID
                                                         AND KQHT.CotDiemID         = TCT.CotDiemID;

    -- =============================================
    -- Bước 5a: INSERT KhoaCotDiem nếu chưa tồn tại
    --          Dùng OUTPUT để bắt KhoaCotDiemID vừa insert
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
         , 'kdiem'
         , GETDATE()
    FROM
           @tbl_KQHT                             AS t
           INNER JOIN dbo.TemplateBangDiemChiTiet AS tct ON tct.CotDiemID = t.CotDiemID
    WHERE
           NOT EXISTS
           (
               SELECT *
               FROM   dbo.tblKhoaCotDiem AS kcd
               WHERE  kcd.LopID       = t.LopID
                 AND  kcd.MonHocLopID = t.MonHocLopID
                 AND  kcd.MaCotDiem   = tct.MaCotDiem
           );

    -- =============================================
    -- Bước 5b: Update KhoaCotDiemID vào @tbl_KQHT
    --          Ưu tiên dòng mới insert, fallback dòng đã có sẵn
    -- =============================================
    UPDATE t
    SET    t.KhoaCotDiemID = COALESCE(nkcd.KhoaCotDiemID, kcd.KhoaCotDiemID)
    FROM
           @tbl_KQHT                             AS t
           INNER JOIN dbo.TemplateBangDiemChiTiet AS tct  ON tct.CotDiemID    = t.CotDiemID
           LEFT JOIN  dbo.tblKhoaCotDiem          AS kcd  ON kcd.LopID        = t.LopID
                                                        AND kcd.MonHocLopID   = t.MonHocLopID
                                                        AND kcd.MaCotDiem     = tct.MaCotDiem
                                                        AND kcd.Enable        = 1
           LEFT JOIN  @tbl_NewKhoaCotDiem         AS nkcd ON nkcd.LopID       = t.LopID
                                                        AND nkcd.MonHocLopID  = t.MonHocLopID
                                                        AND nkcd.MaCotDiem    = tct.MaCotDiem;
														 
    -- =============================================
    -- Bước 6a: UPDATE các record đã tồn tại
    -- =============================================
    UPDATE kd
    SET    kd.KetQuaDanhGia_VI = t.KetQua_QLD
         , kd.KetQuaDanhGia_EN = t.KetQua_QLD
         , kd.KhoaCotDiemID    = t.KhoaCotDiemID
         , kd.UpdateUser       = 'kdiem'
         , kd.UpdateTime       = GETDATE()
         , kd.NhapDiemUser     = 'kdiem'
         , kd.NhapDiemTime     = GETDATE()
    FROM
           dbo.tblKetQuaHocTap  AS kd
           INNER JOIN @tbl_KQHT AS t ON t.HocSinhID   = kd.HocSinhID
                                    AND t.MonHocLopID  = kd.MonHocLopID
                                    AND t.CotDiemID    = kd.CotDiemID
    WHERE
           kd.Enable                          = 1
      AND  ISNULL(t.KetQua_QLD, '')           <> ''
      AND (    ISNUMERIC(t.KetQua_QLD)         = 0
            OR TRY_CAST(t.KetQua_QLD AS FLOAT) >= 0
          )
      AND  ISNULL(kd.KetQuaDanhGia_VI, '')    <> ISNULL(t.KetQua_QLD, '');

    -- =============================================
    -- Bước 6b: INSERT các record chưa tồn tại
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
         , t.KetQua_QLD
         , t.KetQua_QLD
         , t.KhoaCotDiemID
         , 1
         , 'kdiem'
         , GETDATE()
         , 'kdiem'
         , GETDATE()
    FROM
           @tbl_KQHT AS t
    WHERE
           NOT EXISTS
           (
               SELECT *
               FROM   dbo.tblKetQuaHocTap AS kd
               WHERE  t.HocSinhID   = kd.HocSinhID
                 AND  t.MonHocLopID = kd.MonHocLopID
                 AND  t.CotDiemID   = kd.CotDiemID
                 AND  kd.Enable     = 1
           );
END; 
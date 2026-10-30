
CREATE PROC [dbo].[spAPI_HocSinhBangDiem_STEM_CK_Get]
    @LopID              VARCHAR(10)
  , @MonHocID           INT
  , @TemplateBangDiemID INT
  , @Semester           VARCHAR(20)
  , @NienKhoa           INT             -- để tra cứu tblConfig_STEM
  , @KhoiID             INT             -- để lọc config theo khối
  , @SYS_USERID         VARCHAR(9)
  , @Sys_GroupID        INT
AS
BEGIN
    SET NOCOUNT ON;

    ----------------------------------------------------------------------
    -- Chỉ dùng cho môn STEM (MonHocID = 36)
    ----------------------------------------------------------------------
    IF @MonHocID <> 36
    BEGIN
        RAISERROR('Stored này chỉ dùng cho môn STEM (MonHocID = 36).', 16, 1);
        RETURN;
    END;

    ----------------------------------------------------------------------
    -- Validate @Semester
    ----------------------------------------------------------------------
    IF @Semester NOT IN ('HK1', 'HK2')
    BEGIN
        RAISERROR('Giá trị @Semester không hợp lệ. Chỉ chấp nhận HK1 hoặc HK2.', 16, 1);
        RETURN;
    END;

    ----------------------------------------------------------------------
    -- Lấy config từ spAPI_Config_STEM_Get theo NienKhoa + HocKi
    -- Nếu không có config → fallback mặc định:
    --   HK1 dùng DiemCK, HK2 dùng DiemGK
    ----------------------------------------------------------------------
    DECLARE @HocKi_LayTongDiemChuDe VARCHAR(20);

    -- Dùng temp table để nhận kết quả từ store
    CREATE TABLE #ConfigSTEM (
        ConfigID                INT
      , NienKhoa                INT
      , KhoiID                  INT
      , HocKi                   VARCHAR(20)
      , HocKi_LayTongDiemChuDe  VARCHAR(20)
      , Enable                  BIT
    );

    INSERT INTO #ConfigSTEM
    EXEC dbo.spAPI_Config_STEM_Get
        @NienKhoa    = @NienKhoa
      , @KhoiID      = @KhoiID
      , @SYS_USERID  = @SYS_USERID
      , @Sys_GroupID = @Sys_GroupID;

    SELECT @HocKi_LayTongDiemChuDe = cfg.HocKi_LayTongDiemChuDe
    FROM   #ConfigSTEM cfg
    WHERE  cfg.HocKi  = @Semester
      AND  cfg.Enable = 1;

    DROP TABLE #ConfigSTEM;

    -- Fallback nếu không tìm thấy config
    IF @HocKi_LayTongDiemChuDe IS NULL
    BEGIN
        SET @HocKi_LayTongDiemChuDe = CASE @Semester
            WHEN 'HK1' THEN 'DiemCK'
            WHEN 'HK2' THEN 'DiemGK'
        END;
    END;

    ----------------------------------------------------------------------
    -- Main Query
    ----------------------------------------------------------------------
    SELECT
           HS.HocSinhID
         , HSL.SoDanhBo
         , HS.Ho
         , HS.Ten
         , HS.NgaySinh
         , HS.Nu
         , HS.Ho + ' ' + HS.Ten                                           AS HoTen
         , HS.EnglishName
         , mh.MonHocID
         , BD.CotDiemID
         , BD.MaCotDiem
         , BD.LoaiCotDiem
         , BD.GiaTriCotDiem
         , BD.KieuDanhGiaID
         , BD.TenCotDiem_VI
         , BD.TenCotDiem_EN
         , BD.TenHienThi_VI
         , BD.TenHienThi_EN
         , BD.ThuTuCotDiem
         , BD.ThuTuNhom
         , BD.MaNhomCotDiem
         , BD.TenNhomCotDiem_VI
         , BD.TenNhomCotDiem_EN
         , BD.HexBackground
         , BD.Formula
         , BD.DiemMin
         , BD.DiemMax
         , BD.QuyenNhapDiem
         , BD.WidthCSS
         , KQ.KetQuaDanhGia_VI
         , KQ.KetQuaDanhGia_EN
         , ISNULL(KQ.Is_Edit, 0)                                          AS Is_Edit
         , ISNULL(KQ.KQHTID, 0)                                           AS KQHTID
         , KQ.NhapDiemUser
         , CASE WHEN KQ.NhapDiemUser <> @SYS_USERID THEN 1 ELSE NULL END AS Is_Comment
         , ltt.TinhTrang
         , CASE
               WHEN mh.CapID = 1         THEN dbo.RenderTinhTrang(ltt.TinhTrang)
               WHEN mh.CapID IN (2, 3)   THEN dbo.RenderTinhTrang_C2_C3(ltt.TinhTrang)
           END                                                            AS TenTinhTrang
         , CASE
               WHEN mh.CapID = 1         THEN dbo.RenderColorTinhTrang(ltt.TinhTrang)
               WHEN mh.CapID IN (2, 3)   THEN dbo.RenderTinhTrang_C2_C3(ltt.TinhTrang)
           END                                                            AS MauTinhTrang
         , ltt.Is_GVCN_DaDuyet
         , ltt.Lop_TinhTrangID
         , ltt.NoiDungNhanXet

    FROM dbo.tblHocSinh                         HS

         INNER JOIN dbo.tblHocSinhLop           HSL ON HSL.HocSinhID           = HS.HocSinhID
                                                   AND HSL.LopID               = @LopID
                                                   AND HSL.Enable              = 1

         INNER JOIN dbo.tblMonHocLop            MHL ON MHL.LopNhomID           = HSL.LopID
                                                   AND MHL.TemplateBangDiemID  = @TemplateBangDiemID
                                                   AND MHL.MonHocID            = 36
                                                   AND MHL.Enable              = 1

         INNER JOIN dbo.tblMonHoc               mh  ON mh.MonHocID             = MHL.MonHocID
                                                   AND mh.Enable               = 1

         INNER JOIN dbo.TemplateBangDiemChiTiet BD  ON BD.TemplateBangDiemID   = MHL.TemplateBangDiemID
                                                   AND BD.Enable               = 1
                                                   AND (
                                                       -- Các cột TongDiem CD1/CD2/CD3 luôn lấy
                                                       BD.MaCotDiem IN (
                                                           'TongDiem_CD1_' + @Semester,
                                                           'TongDiem_CD2_' + @Semester,
                                                           'TongDiem_CD3_' + @Semester
                                                       )
                                                       -- Cột điểm chính: lấy theo HocKi_LayTongDiemChuDe từ tblConfig_STEM
                                                       -- VD: HocKi_LayTongDiemChuDe = 'DiemCK' → DiemCK_HK1, SaoCK_HK1, NhanXetCK_HK1
                                                       --     HocKi_LayTongDiemChuDe = 'DiemGK' → DiemGK_HK2, SaoGK_HK2, NhanXetGK_HK2
                                                       OR BD.MaCotDiem IN (
                                                           @HocKi_LayTongDiemChuDe + '_' + @Semester,
                                                           'Sao'     + REPLACE(@HocKi_LayTongDiemChuDe, 'Diem', '') + '_' + @Semester,
                                                           'NhanXet' + REPLACE(@HocKi_LayTongDiemChuDe, 'Diem', '') + '_' + @Semester
                                                       )
                                                   )

         LEFT  JOIN dbo.tblKetQuaHocTap         KQ  ON KQ.HocSinhID            = HS.HocSinhID
                                                   AND KQ.CotDiemID            = BD.CotDiemID
                                                   AND KQ.MonHocLopID          = MHL.MonHocLopID
                                                   AND KQ.Enable               = 1

         LEFT  JOIN dbo.tblLop_TinhTrang        ltt ON ltt.Lop_TinhTrangID     = KQ.Lop_TinhTrangID
                                                   AND ltt.Enable              = 1

    WHERE HS.TinhTrang = 0

    ORDER BY
           HSL.SoDanhBo
         , BD.ThuTuNhom
         , BD.ThuTuCotDiem;

END;

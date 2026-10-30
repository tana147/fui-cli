-- [dbo].[spAPI_LMS_OutSLL_GetKetQuaHocTap_ByHocSinhID] '2477', 1, 2025, '25100082', '1'
CREATE PROC [dbo].[spAPI_LMS_OutSLL_GetKetQuaHocTap_ByHocSinhID]
    @LopID      VARCHAR(10)
  , @KyDanhGia  INT
  , @NamHoc     INT
  , @HocSinhID  INT
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    DECLARE @Semester VARCHAR(4);
    DECLARE @Table_KyDanhGia TABLE
    (
        KyDanhGia INT
      , Semester  VARCHAR(3)
      , MaCotDiem VARCHAR(50)
    );
    INSERT INTO @Table_KyDanhGia
    (
        KyDanhGia
      , Semester
      , MaCotDiem
    )
    VALUES
    (
        1
      , 'HK1'
      , 'DiemGK_HK1'
    )
  , (
        1
      , 'HK1'
      , 'MucDoDanhGiaGK_HK1'
    )
  , (
        1
      , 'HK1'
      , 'NhanXetGK_HK1'
    )
  , (
        1
      , 'HK1'
      , 'SaoGK_HK1'
    )
  , (
        2
      , 'HK1'
      , 'DiemCK_HK1'
    )
  , (
        2
      , 'HK1'
      , 'MucDoDanhGiaCK_HK1'
    )
  , (
        2
      , 'HK1'
      , 'NhanXetCK_HK1'
    )
  , (
        2
      , 'HK1'
      , 'SaoCK_HK1'
    )
  , (
        3
      , 'HK2'
      , 'DiemGK_HK2'
    )
  , (
        3
      , 'HK2'
      , 'MucDoDanhGiaGK_HK2'
    )
  , (
        3
      , 'HK2'
      , 'NhanXetGK_HK2'
    )
  , (
        3
      , 'HK1'
      , 'SaoGK_HK2'
    )
  , (
        4
      , 'HK2'
      , 'DiemCK_HK2'
    )
  , (
        4
      , 'HK2'
      , 'MucDoDanhGiaCK_HK2'
    )
  , (
        4
      , 'HK2'
      , 'NhanXetCK_HK2'
    )
  , (
        4
      , 'HK2'
      , 'SaoCK_HK2'
    );

    -- Khi LopID là số: xử lý theo bảng tblHocSinhLop
    SELECT HS.HocSinhID
         , HSL.SoDanhBo
         , HS.Ho
         , HS.Ten
         , HS.NgaySinh
         , HS.Nu
         , HS.Ho + ' ' + HS.Ten AS HoTen
         , BD.CotDiemID
         , CASE
                WHEN BD.MaCotDiem IN ('DiemGK_HK1', 'DiemCK_HK1', 'DiemGK_HK2', 'DiemCK_HK2') THEN 'DiemMonHoc'
                WHEN BD.MaCotDiem IN ('MucDoDanhGiaGK_HK1', 'MucDoDanhGiaCK_HK1', 'MucDoDanhGiaGK_HK2', 'MucDoDanhGiaCK_HK2') THEN 'MucDoDanhGia'
                WHEN BD.MaCotDiem IN ('NhanXetGK_HK1', 'NhanXetCK_HK1', 'NhanXetGK_HK2', 'NhanXetCK_HK2') THEN 'NhanXet'
                WHEN BD.MaCotDiem IN ('SaoGK_HK1', 'SaoCK_HK1', 'SaoGK_HK2', 'SaoCK_HK2') THEN 'QuyDoiSao'
           END                  AS MaCotDiem
         , KQ.KetQuaDanhGia_VI  AS KetQuaDanhGia
         , KQ.NhapDiemUser
         , KQ.MonHocLopID
         , mh.MonHocCode
         , mh.TenMonDuLieuNganh
         , mh.TenMonHoc_HienThi AS MonHocName
    FROM
           dbo.tblHocSinh                         HS
           INNER JOIN dbo.tblHocSinhLop           HSL ON HS.HocSinhID          = HSL.HocSinhID
                                                     AND HSL.LopID             = TRY_CAST(@LopID AS INT)
                                                     AND HSL.Enable            = 1
           INNER JOIN dbo.tblMonHocLop            MHL ON MHL.LopNhomID         = HSL.LopID
                                                     AND MHL.Enable            = 1
           INNER JOIN dbo.tblMonHoc               mh ON mh.MonHocID            = MHL.MonHocID
           INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID  = MHL.TemplateBangDiemID
                                                    AND BD.Enable              = 1
           INNER JOIN dbo.tblKetQuaHocTap         KQ ON KQ.HocSinhID           = HS.HocSinhID
                                                    AND KQ.CotDiemID           = BD.CotDiemID
                                                    AND KQ.MonHocLopID         = MHL.MonHocLopID
                                                    AND KQ.Enable              = 1
                                                    AND KQ.NienKhoa            = @NamHoc
           inner JOIN dbo.tblLop_TinhTrang         l_tt ON l_tt.Lop_TinhTrangID = KQ.Lop_TinhTrangID
                                                      AND l_tt.Enable          = 1
                                                      AND l_tt.TinhTrang       = 8 --Công bố PH
                                                       
           INNER JOIN @Table_KyDanhGia            AS kydg ON kydg.MaCotDiem    = BD.MaCotDiem
                                                         AND kydg.KyDanhGia    = @KyDanhGia
    WHERE
           HS.TinhTrang = 0
      AND  HS.HocSinhID  = @HocSinhID
    ORDER BY
           HSL.SoDanhBo
         , mh.Sort
         , BD.ThuTuNhom
         , BD.ThuTuCotDiem;

END;
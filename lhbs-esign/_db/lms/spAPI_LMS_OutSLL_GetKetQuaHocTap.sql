-- spAPI_LMS_OutSLL_GetKetQuaHocTap 2491,1,2025,'gv0000611'
CREATE PROC [dbo].[spAPI_LMS_OutSLL_GetKetQuaHocTap] --Câu này đang sử dụng dành cho C1
    @LopID      VARCHAR(10)
  , @KyDanhGia  INT
  , @NamHoc     INT
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    DECLARE @Semester VARCHAR(20);
    DECLARE @CapID INT;
    SELECT @CapID = CapID
    FROM
           dbo.tblLop
    WHERE
           LopID = @LopID AND NienKhoa = @NamHoc;
    IF (@CapID = 1)
    BEGIN
        IF @KyDanhGia = 1
            SET @Semester = 'GK_HK1';
        ELSE IF @KyDanhGia = 2
            SET @Semester = 'CK_HK1';
        ELSE IF @KyDanhGia = 3
            SET @Semester = 'GK_HK2';
        ELSE IF @KyDanhGia = 4
            SET @Semester = 'CK_HK2';
    END;
    ELSE
    BEGIN
        IF @KyDanhGia = 1
            SET @Semester = 'HK1';
        ELSE IF @KyDanhGia = 2
            SET @Semester = 'HK2';
    END;

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
                WHEN BD.MaCotDiem LIKE 'Diem' + @Semester THEN 'DiemMonHoc'
                WHEN BD.MaCotDiem LIKE 'MucDoDanhGia' + @Semester THEN 'MucDoDanhGia'
                WHEN BD.MaCotDiem LIKE 'NhanXet' + @Semester THEN 'NhanXet'
           END                  AS MaCotDiem
         , KQ.KetQuaDanhGia_VI  AS KetQuaDanhGia
         , KQ.NhapDiemUser
         , KQ.MonHocLopID
         , mh.MonHocCode
         , mh.TenMonDuLieuNganh
         , mh.TenMonHoc_HienThi
    FROM
           dbo.tblHocSinh                         HS
           INNER JOIN dbo.tblHocSinhLop           HSL ON HS.HocSinhID          = HSL.HocSinhID
                                                     AND HSL.LopID             = TRY_CAST(@LopID AS INT)
                                                     AND HSL.Enable            = 1
           INNER JOIN dbo.tblMonHocLop            MHL ON MHL.LopNhomID         = HSL.LopID
                                                     AND MHL.Enable            = 1
           INNER JOIN dbo.tblMonHoc               mh ON mh.MonHocID            = MHL.MonHocID
           INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID  = MHL.TemplateBangDiemID
                                                    AND BD.MaCotDiem IN ('Diem' + @Semester, 'MucDoDanhGia' + @Semester, 'NhanXet' + @Semester)
                                                    AND BD.Enable              = 1
           INNER JOIN dbo.tblKetQuaHocTap         KQ ON KQ.HocSinhID           = HS.HocSinhID
                                                    AND KQ.CotDiemID           = BD.CotDiemID
                                                    AND KQ.MonHocLopID         = MHL.MonHocLopID
                                                    AND KQ.Enable              = 1
                                                    AND KQ.NienKhoa            = @NamHoc
           --INNER JOIN dbo.tblLop_TinhTrang        l_tt ON l_tt.Lop_TinhTrangID = KQ.Lop_TinhTrangID
           --                                           AND l_tt.Enable          = 1
                                                      --AND l_tt.TinhTrang       = 8
    WHERE
           HS.TinhTrang = 0
    ORDER BY
           HSL.SoDanhBo
         , mh.Sort
         , BD.ThuTuNhom
         , BD.ThuTuCotDiem;

END;



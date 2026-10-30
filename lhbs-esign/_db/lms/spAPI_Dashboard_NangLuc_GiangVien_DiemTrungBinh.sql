-- spAPI_Dashboard_NangLuc_GiangVien_DiemTrungBinh 2024, 2, 46
CREATE PROC [dbo].[spAPI_Dashboard_NangLuc_GiangVien_DiemTrungBinh]
    @NienKhoa INT
  , @CapID    INT
  , @MonHocID INT
AS
BEGIN
    SELECT tl.LopID
         , tl.TenLop
         , ROUND(AVG(   CASE
                             WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1
                              AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) IS NOT NULL THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                             ELSE NULL
                        END
                    ), 2
                )                 AS DiemTB
         , DPD_VN.[HoTenGiaoVien] AS GV_VN
         , DPD_VN.DiemPDP         AS PDP_GV_VN
         , DPD_NN.[HoTenGiaoVien] AS GV_NN
         , DPD_NN.DiemPDP         AS PDP_GV_NN
    FROM
           dbo.tblKetQuaHocTap                       tkqht
           INNER JOIN dbo.tblLop                     tl ON tl.LopID                   = tkqht.LopID AND tl.NienKhoa = @NienKhoa
           INNER JOIN dbo.tblHocSinh                 hs ON hs.HocSinhID               = tkqht.HocSinhID
           INNER JOIN dbo.TemplateBangDiemChiTiet    tbdct ON tbdct.CotDiemID         = tkqht.CotDiemID
           INNER JOIN dbo.tblMonHocLop               tmhl ON tmhl.MonHocLopID         = tkqht.MonHocLopID
           INNER JOIN dbo.tblMonHoc                  tmh ON tmh.MonHocID              = tmhl.MonHocID
           INNER JOIN [dbo].[tblGiaoVienLopTiengAnh] GV ON GV.TenLop                  = tl.TenLop
           INNER JOIN [dbo].[tblGiaoVienDPDTiengAnh] DPD_VN ON DPD_VN.[HoTenGiaoVien] = GV.HoTenGiaoVien1
           INNER JOIN [dbo].[tblGiaoVienDPDTiengAnh] DPD_NN ON DPD_NN.[HoTenGiaoVien] = GV.HoTenGiaoVien2
    WHERE
           tkqht.NienKhoa                                    = @NienKhoa
      AND  tl.CapID                                           = @CapID
      AND  tmh.MonHocID                                       = @MonHocID
      AND  tbdct.MaCotDiem                                    = 'DiemTB_HK1'
      AND  TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) > 0
      AND  tkqht.Enable                                       = 1
    GROUP BY
           tl.LopID
         , tl.TenLop
         , DPD_VN.[HoTenGiaoVien]
         , DPD_VN.DiemPDP
         , DPD_NN.[HoTenGiaoVien]
         , DPD_NN.DiemPDP
    ORDER BY
           tl.TenLop;
END;
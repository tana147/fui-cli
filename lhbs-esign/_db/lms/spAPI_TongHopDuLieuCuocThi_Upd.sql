-- [dbo].[spAPI_TongHopDuLieuCuocThi_Get] 2025, '2445'
CREATE PROC [dbo].[spAPI_TongHopDuLieuCuocThi_Upd]
    @TongHopDuLieuCuocThiID           INT
  , @NienKhoa                         INT
  , @HocSinhID                        INT
  , @LopID                            INT
  , @ThoiGianThi                      NVARCHAR(50)
  , @HocKi                            NVARCHAR(50)
  , @TenCuocThi                       NVARCHAR(100)
  , @LinhVucDuAn                      NVARCHAR(50)
  , @MoTaNganGonNoiDung_MucTieu       NVARCHAR(200)
  , @GVHuongDan                       NVARCHAR(50)
  , @To_BoPhan                        NVARCHAR(50)
  , @GV_ToHoTro                       NVARCHAR(50)
  , @ToChucCongNhan                   NVARCHAR(50)
  , @CapDoGiaiThuong                  NVARCHAR(50)
  , @GiaiThuongDatDuoc                NVARCHAR(50)
  , @MinhChung_SoHieuQD_LinkChungNhan NVARCHAR(50)
  , @GhiChuBoSung                     NVARCHAR(50)
  , @SYS_USERID                       VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblTong_Hop_Du_Lieu_Cuoc_Thi
    SET    ThoiGianThi = @ThoiGianThi
         , HocKi = @HocKi
         , TenCuocThi = @TenCuocThi
         , LinhVucDuAn = @LinhVucDuAn
         , MoTaNganGonNoiDung_MucTieu = @MoTaNganGonNoiDung_MucTieu
         , GVHuongDan = @GVHuongDan
         , To_BoPhan = @To_BoPhan
         , GV_ToHoTro = @GV_ToHoTro
         , ToChucCongNhan = @ToChucCongNhan
         , CapDoGiaiThuong = @CapDoGiaiThuong
         , GiaiThuongDatDuoc = @GiaiThuongDatDuoc
         , MinhChung_SoHieuQD_LinkChungNhan = @MinhChung_SoHieuQD_LinkChungNhan
         , GhiChuBoSung = @GhiChuBoSung
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           TongHopDuLieuCuocThiID = @TongHopDuLieuCuocThiID;
END;
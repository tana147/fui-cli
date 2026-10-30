CREATE PROCEDURE [dbo].[spAPI_TongHopDuLieuCuocThi_Ins]
    @NienKhoa                         INT
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
    INSERT INTO dbo.tblTong_Hop_Du_Lieu_Cuoc_Thi
    (
        NienKhoa
      , HocSinhID
      , LopID
      , ThoiGianThi
      , HocKi
      , TenCuocThi
      , LinhVucDuAn
      , MoTaNganGonNoiDung_MucTieu
      , GVHuongDan
      , To_BoPhan
      , GV_ToHoTro
      , ToChucCongNhan
      , CapDoGiaiThuong
      , GiaiThuongDatDuoc
      , MinhChung_SoHieuQD_LinkChungNhan
      , GhiChuBoSung
      , Enable
      , CreateUser
      , CreateTime
    )
    VALUES
    (
        @NienKhoa
      , @HocSinhID
      , @LopID
      , @ThoiGianThi
      , @HocKi
      , @TenCuocThi
      , @LinhVucDuAn
      , @MoTaNganGonNoiDung_MucTieu
      , @GVHuongDan
      , @To_BoPhan
      , @GV_ToHoTro
      , @ToChucCongNhan
      , @CapDoGiaiThuong
      , @GiaiThuongDatDuoc
      , @MinhChung_SoHieuQD_LinkChungNhan
      , @GhiChuBoSung
      , 1
      , @SYS_USERID
      , GETDATE()
    ); 
END;
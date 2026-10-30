-- [dbo].[spAPI_TongHopDuLieuCuocThi_Get] 2025, '2445'
CREATE PROC [dbo].[spAPI_TongHopDuLieuCuocThi_Get]
    @NienKhoa INT
  , @LopID    VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TongHopDuLieuCuocThiID
         , th.HocSinhID
         , hs.Ho + ' ' + hs.Ten  AS HoTen
         , th.LopID
         , l.TenLop
         , th.ThoiGianThi
         , th.HocKi
         , th.TenCuocThi
         , th.LinhVucDuAn
         , th.MoTaNganGonNoiDung_MucTieu
         , th.GVHuongDan
         , th.To_BoPhan
         , th.GV_ToHoTro
         , th.ToChucCongNhan
         , th.CapDoGiaiThuong
         , th.GiaiThuongDatDuoc
         , th.MinhChung_SoHieuQD_LinkChungNhan
         , th.GhiChuBoSung
    FROM
           dbo.tblTong_Hop_Du_Lieu_Cuoc_Thi th
           INNER JOIN dbo.tblHocSinh        hs ON hs.HocSinhID = th.HocSinhID
           INNER JOIN dbo.tblLop            l ON l.LopID       = th.LopID
                                             AND l.Enable      = 1
                                             AND l.NienKhoa    = @NienKhoa
    WHERE
           th.Enable  = 1
      AND  th.NienKhoa = @NienKhoa
      AND  th.LopID    = @LopID
    ORDER BY
           th.TongHopDuLieuCuocThiID DESC;
END;
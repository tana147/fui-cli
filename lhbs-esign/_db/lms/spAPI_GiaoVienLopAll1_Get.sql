
--[spAPI_GiaoVienLopAll1_Get] 2024,3 , 12,104
CREATE PROCEDURE [dbo].[spAPI_GiaoVienLopAll1_Get]
@NienKhoa INT,
@CapID INT  NULL,
@KhoiID INT NULL,
@MonHocID INT NULL 
AS
BEGIN
    SELECT tgvl.GVLopID
         , tgvl.VaiTro
         , CASE WHEN tgvl.VaiTro = 3 THEN N'Giáo viên giảng dạy' END AS TenVaiTro
         , tgv.GiaoVienID
         , tgv.HoGV + ' ' + tgv.TenGV                                AS HoTen
         , tgvl.LopID
         , tl.TenLop
         , tgv.TenGV
         , tmh.MonHocID
		 , tmh.MonHocName
         , tmh.TenMonDuLieuNganh
         , tmh.Color
         , tk.TenKhoiHoc
    FROM
           dbo.tblGiaoVien              tgv
           INNER JOIN dbo.tblGiaoVienLop tgvl ON tgv.GiaoVienID = tgvl.GiaoVienID AND tgvl.Enable = 1 AND tgvl.NienKhoa =@NienKhoa AND (@KhoiID IS NULL OR tgvl.KhoiID = @KhoiID)
          INNER JOIN dbo.tblLop         tl ON tl.LopID         = tgvl.LopID AND tl.Enable = 1 AND tl.NienKhoa =@NienKhoa
          INNER JOIN dbo.tblMonHoc      tmh ON tgvl.MonHocID   = tmh.MonHocID AND tmh.Enable = 1 AND (@MonHocID IS NULL OR tmh.MonHocID = @MonHocID)
          INNER JOIN dbo.tblKhoi        tk ON tk.KhoiID        = tgvl.KhoiID AND tk.Enable = 1 AND  (@CapID IS NULL OR tk.CapID =  @CapID)
	ORDER BY tgv.GiaoVienID;
END;

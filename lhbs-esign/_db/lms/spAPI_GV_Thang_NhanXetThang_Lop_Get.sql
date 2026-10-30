CREATE PROC [dbo].[spAPI_GV_Thang_NhanXetThang_Lop_Get]
    @LopID           INT
  , @HSLopID         INT
  , @NienKhoa        INT
  , @SYS_SystemRight INT
  , @Sys_GroupID     INT
AS
BEGIN
    SELECT nxt_l.Lop_NhanXetThangID
         , nxt_l.LopID
         , N'Tháng ' + CAST(nxt_l.Thang AS NVARCHAR(2)) + '/' + CAST(nxt_l.Nam AS NVARCHAR(4)) AS Thang_HienThi
         , N'Tháng ' + CAST(nxt_l.Thang AS NVARCHAR(2)) + '/' + CAST(nxt_l.Nam AS NVARCHAR(4)) AS Thang_HienThi_VI
         , CAST(nxt_l.Text_Thang_EN AS NVARCHAR(3)) + ' - ' + CAST(nxt_l.Nam AS NVARCHAR(4))   AS Thang_HienThi_EN
         , nxt_l.Thang
         , nxt_l.Nam
         , nxt_l.NienKhoa
         , nxt_l.Text_Thang_VI
         , nxt_l.Text_Thang_EN
         , nxt_l.IconUrl
         , nxt_l.TinhTrang
         , dbo.RenderColorTinhTrang(nxt_l.TinhTrang)                                           AS MauTinhTrang
         , dbo.RenderTinhTrang(nxt_l.TinhTrang)                                                AS TenTinhTrang
         , Is_Viewed
         , nxt_l.HocKy
    FROM
           dbo.tblNhanXetThang_Lop        AS nxt_l
           INNER JOIN dbo.tblNhanXetThang AS nxt ON nxt.Lop_NhanXetThangID = nxt_l.Lop_NhanXetThangID
                                                AND nxt.HSLopID            = @HSLopID
                                                AND nxt.Enable             = 1
    WHERE
           nxt_l.LopID             = @LopID
      AND  (@NienKhoa IS NULL OR @NienKhoa = 0 OR nxt_l.NienKhoa = @NienKhoa)
      AND  nxt_l.TinhTrang          = 4
      AND  nxt_l.Is_HienThiPhuHuynh = 1
      AND  nxt_l.Enable             = 1;
END;
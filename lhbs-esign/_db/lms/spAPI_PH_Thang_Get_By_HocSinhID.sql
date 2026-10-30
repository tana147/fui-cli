CREATE PROC [dbo].[spAPI_PH_Thang_Get_By_HocSinhID]
    @HocSinhID          INT
  , @Lop_NhanXetThangID INT
  , @SYS_SystemRight    INT
  , @Sys_GroupID        INT
AS
BEGIN
        SELECT convert_to_object                                                                   = ''
             , nxt.NhanXetThangID
             , N'Tháng ' + CAST(nxt_l.Thang AS NVARCHAR(2)) + '/' + CAST(nxt_l.Nam AS NVARCHAR(4)) AS Thang_HienThi
             , N'Tháng ' + CAST(nxt_l.Thang AS NVARCHAR(2)) + '/' + CAST(nxt_l.Nam AS NVARCHAR(4)) AS Thang_HienThi_VI
             , CAST(nxt_l.Text_Thang_EN AS NVARCHAR(3)) + ' - ' + CAST(nxt_l.Nam AS NVARCHAR(4))   AS Thang_HienThi_EN
             , nxt_l.Thang
             , nxt_l.Nam
             , nxt_l.NienKhoa
             , nxt.HSLopID
             , nxt.HocSinhID
             , nxt.NoiDungKienThuc_HTML
             , nxt.NoiDungNangLuc_HTML
             , nxt.NoiDungHoatDongKhac_HTML
             , nxt.NoiDungTiengViet_HTML
             , nxt.NoiDungToan_HTML
             , nxt.NoiDungMonHocKhac_HTML
             , CASE
                    WHEN DiemTiengViet = 0
                      OR DiemTiengViet IS NULL THEN NULL
                    ELSE nxt.SoSao_TiengViet
               END                                                                                 AS SoSao_TiengViet
             , CASE
                    WHEN DiemToan = 0
                      OR DiemToan IS NULL THEN NULL
                    ELSE nxt.SoSao_Toan
               END                                                                                 AS SoSao_Toan
             , nxt.Parent_Comment
             , nxt.NhanXetToan_HTML
             , nxt.NhanXetTiengViet_HTML
             , nxt.HoatDongGiaoDucKhac_HTML
             , nxt.PhamChatNangLuc_HTML
             , nxt.NhanXetMonHocKhac_HTML
             , nxt.DiemTiengViet
             , nxt.DiemToan
			 , UuDiem
			 , NhuocDiem
			 , DeXuat
        FROM
               dbo.tblNhanXetThang                AS nxt
               INNER JOIN dbo.tblNhanXetThang_Lop AS nxt_l ON nxt_l.Lop_NhanXetThangID = nxt.Lop_NhanXetThangID
                                                          AND nxt_l.Enable             = 1
                                                          AND nxt_l.Is_HienThiPhuHuynh = 1
                                                          AND nxt_l.TinhTrang          = 4
        WHERE
               nxt.Lop_NhanXetThangID = @Lop_NhanXetThangID
          AND  nxt.HocSinhID           = @HocSinhID;
END;




CREATE PROC [dbo].[spAPI_NhanXetThang_Lop_Get] 
@NienKhoa INT = 2025,
@LopID INT
AS
BEGIN

    SELECT   nxt_l.Lop_NhanXetThangID
           , nxt_l.LopID
           , N'Tháng ' + CAST(nxt_l.Thang AS NVARCHAR(2)) + '/' + CAST(nxt_l.Nam AS NVARCHAR(4)) + CASE
                                                                                                        WHEN nxt_l.Text_Thang_VI = N'Cuối năm' THEN N' - Cuối năm'
                                                                                                        ELSE ''
                                                                                                   END AS Thang_HienThi
           , N'Tháng ' + CAST(nxt_l.Thang AS NVARCHAR(2)) + '/' + CAST(nxt_l.Nam AS NVARCHAR(4)) + CASE
                                                                                                        WHEN nxt_l.Text_Thang_VI = N'Cuối năm' THEN N' - Cuối năm'
                                                                                                        ELSE ''
                                                                                                   END AS Thang_HienThi_VI
           , CAST(nxt_l.Text_Thang_EN AS NVARCHAR(3)) + ' - ' + CAST(nxt_l.Nam AS NVARCHAR(4)) + CASE
                                                                                                      WHEN nxt_l.Text_Thang_VI = N'Cuối năm' THEN N' - End of the year'
                                                                                                      ELSE ''
                                                                                                 END   AS Thang_HienThi_EN
           , nxt_l.Thang
           , nxt_l.Nam
           , nxt_l.NienKhoa
           , nxt_l.Text_Thang_VI
           , nxt_l.Text_Thang_EN
           , nxt_l.IconUrl
           , nxt_l.TinhTrang
           , dbo.RenderNhanXet_ColorTinhTrang(nxt_l.TinhTrang)                                                 AS MauTinhTrang
           , dbo.RenderNhanXet_TinhTrang(nxt_l.TinhTrang)                                              AS TenTinhTrang
           , nxt_l.Is_HienThiPhuHuynh
           , nxt_l.ReasonReject
		   , l.GVCN
		   , nxt_l.HocKy
    FROM
             dbo.tblNhanXetThang_Lop AS nxt_l
			 inner join dbo.tblLop as l on l.LopID = nxt_l.LopID
			                              and l.Enable = 1
			                              and l.NienKhoa = @NienKhoa
    WHERE
             nxt_l.LopID = @LopID
      -- Danh sách tháng phải cùng lớp và cùng niên khóa, tránh lấy chéo dữ liệu cũ.
      AND    nxt_l.NienKhoa = @NienKhoa
      AND    nxt_l.Enable   = 1
	  AND	 nxt_l.TinhTrang >= 0
	  AND    nxt_l.Is_Showing = 1
    ORDER BY (nxt_l.Nam - @NienKhoa) * 12 + nxt_l.Thang - 8 desc;
END;

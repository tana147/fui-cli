--  [dbo].[spAPI_NhanXetThang_Lop_Get_GV] 2025 , 0

CREATE PROC [dbo].[spAPI_NhanXetThang_Lop_Get_GV]
    @NienKhoa INT = 2025
  , @LopID    INT 
AS
BEGIN
    SELECT nxt_l.Lop_NhanXetThangID
			, l.TenLop
         , nxt_l.LopID
		 , CapID
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
         , dbo.RenderNhanXet_ColorTinhTrang(nxt_l.TinhTrang)                                         AS MauTinhTrang
         , dbo.RenderNhanXet_TinhTrang(nxt_l.TinhTrang)                                              AS TenTinhTrang
         , Is_HienThiPhuHuynh
         , ReasonReject
         , nxt_l.HocKy
    FROM
           dbo.tblNhanXetThang_Lop AS nxt_l
		   inner join tblLop l on l.LopID  = nxt_l.LopID and l.Enable = 1 and l.NienKhoa = @NienKhoa
    WHERE
           (nxt_l.LopID     = @LopID or @LopID = 0)
      -- Khóa cả lớp và niên khóa để không hiển thị tháng của năm học khác.
      AND  nxt_l.NienKhoa  = @NienKhoa
      AND  nxt_l.Enable     = 1
      AND  nxt_l.Is_Showing = 1
    -- ORDER BY (nxt_l.Nam - @NienKhoa) * 12 + nxt_l.Thang - 8;
    ORDER BY
           Is_HienThiPhuHuynh 
		, nxt_l.Thang desc
		, nxt_l.Nam desc
		, TenLop
END;

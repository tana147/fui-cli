CREATE PROC [dbo].[spAPI_NhanXetThang_Import]
    @JSON_NhanXetThang NVARCHAR(MAX)
  , @SYS_USERID        VARCHAR(9)
AS
BEGIN
    DECLARE @Table_NhanXetThang TABLE
    (
        Lop_NhanXetThangID       INT
      , HocSinhID                INT
      , HSLopID                  INT
      , DiemToan                 NVARCHAR(50)
      , NhanXetToan_HTML         NVARCHAR(4000)
      , DiemTiengViet            NVARCHAR(50)
      , NhanXetTiengViet_HTML    NVARCHAR(4000)
      , NhanXetMonHocKhac_HTML   NVARCHAR(4000)
      , HoatDongGiaoDucKhac_HTML NVARCHAR(4000)
      , PhamChatNangLuc_HTML     NVARCHAR(4000)
      , NoiDungKienThuc_HTML     NVARCHAR(4000)
      , NoiDungNangLuc_HTML      NVARCHAR(4000)
      , NoiDungHoatDongKhac_HTML NVARCHAR(4000)
	  , UuDiem	                 NVARCHAR(MAX)
	 ,  NhuocDiem NVARCHAR(MAX)
	 ,  DeXuat	 NVARCHAR(MAX)
	 , NhanXetGVCN NVARCHAR(500)
    );

    INSERT INTO @Table_NhanXetThang
    (
        Lop_NhanXetThangID
      , HocSinhID
      , HSLopID
      , DiemToan
      , NhanXetToan_HTML
      , DiemTiengViet
      , NhanXetTiengViet_HTML
      , NhanXetMonHocKhac_HTML
      , HoatDongGiaoDucKhac_HTML
      , PhamChatNangLuc_HTML
      , NoiDungKienThuc_HTML
      , NoiDungNangLuc_HTML
      , NoiDungHoatDongKhac_HTML
	  ,  UuDiem	 
		, NhuocDiem
		, DeXuat	 
		, NhanXetGVCN 
    )
    SELECT Lop_NhanXetThangID
         , HocSinhID
         , HSLopID
         , CASE WHEN DiemToan = '' OR DiemToan IS NULL THEN NULL ELSE DiemToan END
         , NhanXetToan_HTML
         , CASE
                WHEN DiemTiengViet = ''
                  OR DiemTiengViet IS NULL THEN NULL
                ELSE DiemTiengViet
           END
         , NhanXetTiengViet_HTML
         , NhanXetMonHocKhac_HTML
         , HoatDongGiaoDucKhac_HTML
         , PhamChatNangLuc_HTML
         , NoiDungKienThuc_HTML
         , NoiDungNangLuc_HTML
         , NoiDungHoatDongKhac_HTML
		 ,UuDiem	 
		 ,NhuocDiem
		 ,DeXuat	 
		 , NhanXetGVCN  

    FROM
           OPENJSON(@JSON_NhanXetThang)
           WITH
           (
               Lop_NhanXetThangID INT
             , HocSinhID INT
             , HSLopID INT
             , DiemToan NVARCHAR(50)
             , NhanXetToan_HTML NVARCHAR(4000)
             , DiemTiengViet NVARCHAR(50)
             , NhanXetTiengViet_HTML NVARCHAR(4000)
             , NhanXetMonHocKhac_HTML NVARCHAR(4000)
             , HoatDongGiaoDucKhac_HTML NVARCHAR(4000)
             , PhamChatNangLuc_HTML NVARCHAR(4000)
             , NoiDungKienThuc_HTML NVARCHAR(4000)
             , NoiDungNangLuc_HTML NVARCHAR(4000)
             , NoiDungHoatDongKhac_HTML NVARCHAR(4000)
			 ,UuDiem	  NVARCHAR(MAX)
			 ,NhuocDiem NVARCHAR(MAX)
			 ,DeXuat	 NVARCHAR(MAX) 
			 , NhanXetGVCN NVARCHAR(500)

           );

    UPDATE nxt
    SET    nxt.DiemToan = ISNULL(t_nxt.DiemToan, nxt.DiemToan)
         , nxt.SoSao_Toan = ISNULL(dbo.Convert_Star_By_Diem_NhanXetThang(t_nxt.DiemToan), nxt.SoSao_Toan)
         , nxt.NhanXetToan_HTML = ISNULL(t_nxt.NhanXetToan_HTML, nxt.NhanXetToan_HTML)
         , nxt.DiemTiengViet = ISNULL(t_nxt.DiemTiengViet, nxt.DiemTiengViet)
         , nxt.SoSao_TiengViet = ISNULL(dbo.Convert_Star_By_Diem_NhanXetThang(t_nxt.DiemTiengViet), nxt.SoSao_TiengViet)
         , nxt.NhanXetTiengViet_HTML = ISNULL(t_nxt.NhanXetTiengViet_HTML, nxt.NhanXetTiengViet_HTML)
         , nxt.NhanXetMonHocKhac_HTML = ISNULL(t_nxt.NhanXetMonHocKhac_HTML, nxt.NhanXetMonHocKhac_HTML)
         , nxt.HoatDongGiaoDucKhac_HTML = ISNULL(t_nxt.HoatDongGiaoDucKhac_HTML, nxt.HoatDongGiaoDucKhac_HTML)
         , nxt.PhamChatNangLuc_HTML = ISNULL(t_nxt.PhamChatNangLuc_HTML, nxt.PhamChatNangLuc_HTML)
         , nxt.NoiDungKienThuc_HTML = ISNULL(t_nxt.NoiDungKienThuc_HTML, nxt.NoiDungKienThuc_HTML)
         , nxt.NoiDungNangLuc_HTML = ISNULL(t_nxt.NoiDungNangLuc_HTML, nxt.NoiDungNangLuc_HTML)
         , nxt.NoiDungHoatDongKhac_HTML = ISNULL(t_nxt.NoiDungHoatDongKhac_HTML, nxt.NoiDungHoatDongKhac_HTML)
		 , nxt.UuDiem	  = t_nxt.UuDiem	
		 , nxt.NhuocDiem  = t_nxt.NhuocDiem
		 , nxt.DeXuat	  = t_nxt.DeXuat	
		 , nxt.NhanXetGVCN = t_nxt.NhanXetGVCN	
         , nxt.UpdateTime = GETDATE()
         , nxt.UpdateUser = @SYS_USERID
    FROM
           dbo.tblNhanXetThang            AS nxt
           INNER JOIN @Table_NhanXetThang AS t_nxt ON t_nxt.HSLopID            = nxt.HSLopID
                                                  AND t_nxt.Lop_NhanXetThangID = nxt.Lop_NhanXetThangID;

    INSERT INTO dbo.tblNhanXetThang
    (
        Lop_NhanXetThangID
      , HSLopID
      , HocSinhID
      , DiemToan
      , SoSao_Toan
      , NhanXetToan_HTML
      , DiemTiengViet
      , SoSao_TiengViet
      , NhanXetTiengViet_HTML
      , NhanXetMonHocKhac_HTML
      , HoatDongGiaoDucKhac_HTML
      , PhamChatNangLuc_HTML
      , NoiDungKienThuc_HTML
      , NoiDungNangLuc_HTML
      , NoiDungHoatDongKhac_HTML
	 , UuDiem	 
	 , NhuocDiem 
	 , DeXuat	 
	 , NhanXetGVCN
      , Enable
      , CreateUser
      , CreateTime
    )
    SELECT Lop_NhanXetThangID
         , HSLopID
         , HocSinhID
         , DiemToan
         , dbo.Convert_Star_By_Diem_NhanXetThang(DiemToan)      AS SoSao_Toan
         , NhanXetToan_HTML
         , DiemTiengViet
         , dbo.Convert_Star_By_Diem_NhanXetThang(DiemTiengViet) AS SoSao_TiengViet
         , NhanXetTiengViet_HTML
         , NhanXetMonHocKhac_HTML
         , HoatDongGiaoDucKhac_HTML
         , PhamChatNangLuc_HTML
         , NoiDungKienThuc_HTML
         , NoiDungNangLuc_HTML
         , NoiDungHoatDongKhac_HTML
		  , UuDiem	 
			, NhuocDiem 
			, DeXuat	 
			, NhanXetGVCN
         , 1
         , @SYS_USERID
         , GETDATE()
    FROM
           @Table_NhanXetThang AS t_nxt
    WHERE
           NOT EXISTS
    (
        SELECT 1
        FROM
               dbo.tblNhanXetThang AS nxt
        WHERE
               t_nxt.HSLopID           = nxt.HSLopID
          AND  t_nxt.Lop_NhanXetThangID = nxt.Lop_NhanXetThangID
    );

END;
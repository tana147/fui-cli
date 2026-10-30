CREATE PROC [dbo].[spAPI_NhanXetThang_Ins]
    @JSON_NhanXetThang NVARCHAR(MAX)
  , @SYS_USERID        VARCHAR(9)
AS
BEGIN
    DECLARE @Table_NhanXetThang TABLE
    (
        Lop_NhanXetThangID       INT
      , HocSinhID                INT
      , HSLopID                  INT
      , DiemToan                  NVARCHAR(50)
      , NhanXetToan_HTML         NVARCHAR(MAX)
      , DiemTiengViet             NVARCHAR(50)
      , NhanXetTiengViet_HTML    NVARCHAR(MAX)
      , NhanXetMonHocKhac_HTML   NVARCHAR(MAX)
      , HoatDongGiaoDucKhac_HTML NVARCHAR(MAX)
      , PhamChatNangLuc_HTML     NVARCHAR(MAX)
      , NoiDungKienThuc_HTML     NVARCHAR(MAX)
      , NoiDungNangLuc_HTML      NVARCHAR(MAX)
      , NoiDungHoatDongKhac_HTML NVARCHAR(MAX)
	  	  -- Thêm vào định nghĩa bảng biến
	  , PhoiHopCMHS                   NVARCHAR(50)
	  , NhanXetGVCN_VePhuHuynh_HTML  NVARCHAR(MAX)
	  , NhanXetGVCN_VeHocSinh_HTML   NVARCHAR(MAX)
	  , PhanLoai_TuyenThang          NVARCHAR(50)
	  , Flyers                       NVARCHAR(50)
	  , DiemTA                        NVARCHAR(50) 
	  , DKHocTiep                    bit
	  , DeXuat_NDCamKet              NVARCHAR(500)
	  , UuDiem						 NVARCHAR(MAX)
	  , NhuocDiem						 NVARCHAR(MAX)
	  , DeXuat							 NVARCHAR(MAX)
	  , NhanXetGVCN NVARCHAR(500)
	  , NhanXet_ChuanBiNienKhoaSau nvarchar(1000)
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
	  , PhoiHopCMHS
	  , NhanXetGVCN_VePhuHuynh_HTML
	  , NhanXetGVCN_VeHocSinh_HTML
	  , PhanLoai_TuyenThang
	  , Flyers
	  , DiemTA
	  , DKHocTiep
	  , DeXuat_NDCamKet
	  ,UuDiem			
	  , NhuocDiem		
	  , DeXuat		
	  , NhanXetGVCN 
	  ,  NhanXet_ChuanBiNienKhoaSau  

    )
    SELECT Lop_NhanXetThangID
         , HocSinhID
         , HSLopID
         , case when DiemToan is null or DiemToan = '' then null  else DiemToan end 
         , NhanXetToan_HTML
         , case when DiemTiengViet is null or DiemTiengViet = '' then null  else DiemTiengViet end
         , NhanXetTiengViet_HTML
         , NhanXetMonHocKhac_HTML
         , HoatDongGiaoDucKhac_HTML
         , PhamChatNangLuc_HTML
         , NoiDungKienThuc_HTML
         , NoiDungNangLuc_HTML
         , NoiDungHoatDongKhac_HTML
		 , PhoiHopCMHS
		 , NhanXetGVCN_VePhuHuynh_HTML
		 , NhanXetGVCN_VeHocSinh_HTML
		 , PhanLoai_TuyenThang
		 , Flyers
		 ,  case when DiemTA is null or DiemTA = '' then null  else DiemTA end  
		 , DKHocTiep
		 , DeXuat_NDCamKet
		 , UuDiem			
		 ,  NhuocDiem		
		 ,  DeXuat	
		 ,  NhanXetGVCN 
		 ,   NhanXet_ChuanBiNienKhoaSau 
    FROM
           OPENJSON(@JSON_NhanXetThang)
           WITH
           (
               Lop_NhanXetThangID INT
             , HocSinhID INT
             , HSLopID INT
             , DiemToan  NVARCHAR(50)
             , NhanXetToan_HTML NVARCHAR(MAX)
             , DiemTiengViet  NVARCHAR(50)
             , NhanXetTiengViet_HTML NVARCHAR(MAX)
             , NhanXetMonHocKhac_HTML NVARCHAR(MAX)
             , HoatDongGiaoDucKhac_HTML NVARCHAR(MAX)
             , PhamChatNangLuc_HTML NVARCHAR(MAX)
             , NoiDungKienThuc_HTML NVARCHAR(MAX)
             , NoiDungNangLuc_HTML NVARCHAR(MAX)
             , NoiDungHoatDongKhac_HTML NVARCHAR(MAX)
			 
			, PhoiHopCMHS                   NVARCHAR(50)
			, NhanXetGVCN_VePhuHuynh_HTML  NVARCHAR(MAX)
			, NhanXetGVCN_VeHocSinh_HTML   NVARCHAR(MAX)
			, PhanLoai_TuyenThang          NVARCHAR(50)
			, Flyers                       NVARCHAR(50) 
			, DiemTA                        NVARCHAR(50) 
			, DKHocTiep                    bit
			, DeXuat_NDCamKet              NVARCHAR(500)
			,UuDiem			NVARCHAR(MAX)
			,NhuocDiem		NVARCHAR(MAX)
			,DeXuat			NVARCHAR(MAX)
			 , NhanXetGVCN NVARCHAR(500)
			 , NhanXet_ChuanBiNienKhoaSau nvarchar(1000)
           );

    UPDATE nxt
    SET    nxt.DiemToan = t_nxt.DiemToan
         , nxt.SoSao_Toan = dbo.Convert_Star_By_Diem_NhanXetThang(t_nxt.DiemToan)
         , nxt.NhanXetToan_HTML = t_nxt.NhanXetToan_HTML
         , nxt.DiemTiengViet = t_nxt.DiemTiengViet
         , nxt.SoSao_TiengViet = dbo.Convert_Star_By_Diem_NhanXetThang(t_nxt.DiemTiengViet)
         , nxt.NhanXetTiengViet_HTML = t_nxt.NhanXetTiengViet_HTML
         , nxt.NhanXetMonHocKhac_HTML = t_nxt.NhanXetMonHocKhac_HTML
         , nxt.HoatDongGiaoDucKhac_HTML = t_nxt.HoatDongGiaoDucKhac_HTML
         , nxt.PhamChatNangLuc_HTML = t_nxt.PhamChatNangLuc_HTML
         , NoiDungKienThuc_HTML = t_nxt.NoiDungKienThuc_HTML
         , NoiDungNangLuc_HTML = t_nxt.NoiDungNangLuc_HTML
         , NoiDungHoatDongKhac_HTML = t_nxt.NoiDungHoatDongKhac_HTML
		 , nxt.PhoiHopCMHS = t_nxt.PhoiHopCMHS
		 , nxt.NhanXetGVCN_VePhuHuynh_HTML = t_nxt.NhanXetGVCN_VePhuHuynh_HTML
		 , nxt.NhanXetGVCN_VeHocSinh_HTML = t_nxt.NhanXetGVCN_VeHocSinh_HTML
		 , nxt.PhanLoai_TuyenThang = t_nxt.PhanLoai_TuyenThang
		 , nxt.Flyers = t_nxt.Flyers
		 , nxt.DiemTA = t_nxt.DiemTA
		 , nxt.DKHocTiep = t_nxt.DKHocTiep
		 , nxt.DeXuat_NDCamKet = t_nxt.DeXuat_NDCamKet
		 , nxt.UuDiem		 = t_nxt.UuDiem	
		 , nxt.NhuocDiem	 = t_nxt.NhuocDiem
		 , nxt.DeXuat		 = t_nxt.DeXuat	
		 , nxt.NhanXetGVCN  = t_nxt.NhanXetGVCN
		 , nxt.NhanXet_ChuanBiNienKhoaSau   = t_nxt.NhanXet_ChuanBiNienKhoaSau
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
      , Enable
      , CreateUser
      , CreateTime
	  , PhoiHopCMHS
	  , NhanXetGVCN_VePhuHuynh_HTML
	  , NhanXetGVCN_VeHocSinh_HTML
	  , PhanLoai_TuyenThang
	  , Flyers
	  , DiemTA
	  , DKHocTiep
	  , DeXuat_NDCamKet
	  , UuDiem	
	  , NhuocDiem
	  , DeXuat	
	  , NhanXetGVCN
	  , NhanXet_ChuanBiNienKhoaSau
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
         , 1
         , @SYS_USERID
         , GETDATE()
		 , PhoiHopCMHS
		 , NhanXetGVCN_VePhuHuynh_HTML
		 , NhanXetGVCN_VeHocSinh_HTML
		 , PhanLoai_TuyenThang
		 , Flyers
		 , DiemTA
		 , DKHocTiep
		 , DeXuat_NDCamKet
		 ,UuDiem	
		  ,NhuocDiem
		  ,DeXuat	
		  , NhanXetGVCN
		  , NhanXet_ChuanBiNienKhoaSau
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
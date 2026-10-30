
CREATE PROC [dbo].[spAPI_NhanXetThang_Ins_By_NhanXetThangID]
    @NhanXetThangID              INT
  , @Lop_NhanXetThangID          INT
  , @HSLopID                     INT
  , @HocSinhID                   INT
  , @NoiDungKienThuc_HTML        NVARCHAR(MAX)
  , @NoiDungNangLuc_HTML         NVARCHAR(MAX)
  , @NoiDungHoatDongKhac_HTML    NVARCHAR(MAX)
  , @NoiDungToan_HTML            NVARCHAR(MAX)
  , @NoiDungTiengViet_HTML       NVARCHAR(MAX)
  , @NoiDungMonHocKhac_HTML      NVARCHAR(MAX)
  , @NhanXetCuoiNam_HTML         NVARCHAR(MAX)
  , @NhanXetToan_HTML            NVARCHAR(MAX)
  , @NhanXetTiengViet_HTML       NVARCHAR(MAX)
  , @NhanXetMonHocKhac_HTML      NVARCHAR(MAX)
  , @HoatDongGiaoDucKhac_HTML    NVARCHAR(MAX)
  , @PhamChatNangLuc_HTML        NVARCHAR(MAX)
  , @DiemTiengViet               NVARCHAR(50) NULL
  , @DiemToan                    NVARCHAR(50) NULL
  , @SYS_USERID                  VARCHAR(9)
  , @PhoiHopCMHS                 NVARCHAR(50)
  , @NhanXetGVCN_VePhuHuynh_HTML NVARCHAR(MAX)
  , @NhanXetGVCN_VeHocSinh_HTML  NVARCHAR(MAX)
  , @PhanLoai_TuyenThang         NVARCHAR(50)
  , @Flyers						 NVARCHAR(50) NULL
  , @DiemTA                      NVARCHAR(50) NULL 
  , @DKHocTiep                   BIT
  , @DeXuat_NDCamKet             NVARCHAR(500)
  ,  @UuDiem	NVARCHAR(MAX)
	,@NhuocDiem	NVARCHAR(MAX)
	,@DeXuat	NVARCHAR(MAX)
 , @NhanXetGVCN NVARCHAR(500) 
 , @NhanXet_ChuanBiNienKhoaSau NVARCHAR(1000)
AS
BEGIN
	set @DiemToan =  CASE WHEN @DiemToan = '' or @DiemToan is null THEN null else @DiemToan  END
	set @DiemTiengViet =  CASE WHEN @DiemTiengViet = '' or @DiemTiengViet is null THEN null else @DiemTiengViet  END
	set @DiemTA =  CASE WHEN @DiemTA = '' or @DiemTA is null THEN null else @DiemTA  END

    IF (@NhanXetThangID > 0)
    BEGIN
        UPDATE dbo.tblNhanXetThang
        SET    NoiDungKienThuc_HTML = @NoiDungKienThuc_HTML
             , NoiDungNangLuc_HTML = @NoiDungNangLuc_HTML
             , NoiDungHoatDongKhac_HTML = @NoiDungHoatDongKhac_HTML
             , NoiDungToan_HTML = @NoiDungToan_HTML
             , NoiDungTiengViet_HTML = @NoiDungTiengViet_HTML
             , NoiDungMonHocKhac_HTML = @NoiDungMonHocKhac_HTML
             , SoSao_Toan = dbo.Convert_Star_By_Diem_NhanXetThang(@DiemToan)
             , SoSao_TiengViet = dbo.Convert_Star_By_Diem_NhanXetThang(@DiemTiengViet)
             , DiemToan = @DiemToan
             , DiemTiengViet = @DiemTiengViet
             , NhanXetCuoiNam_HTML = @NhanXetCuoiNam_HTML
             , NhanXetToan_HTML = @NhanXetToan_HTML
             , NhanXetTiengViet_HTML = @NhanXetTiengViet_HTML
             , HoatDongGiaoDucKhac_HTML = @HoatDongGiaoDucKhac_HTML
             , NhanXetMonHocKhac_HTML = @NhanXetMonHocKhac_HTML
             , PhamChatNangLuc_HTML = @PhamChatNangLuc_HTML
             , UpdateUser = @SYS_USERID
             , UpdateTime = GETDATE()
             , PhoiHopCMHS = @PhoiHopCMHS
             , NhanXetGVCN_VePhuHuynh_HTML = @NhanXetGVCN_VePhuHuynh_HTML
             , NhanXetGVCN_VeHocSinh_HTML = @NhanXetGVCN_VeHocSinh_HTML
             , PhanLoai_TuyenThang = @PhanLoai_TuyenThang
             , Flyers = @Flyers
             , DiemTA = @DiemTA
             , DKHocTiep = @DKHocTiep
             , DeXuat_NDCamKet = @DeXuat_NDCamKet
			 , UuDiem	 = @UuDiem	
			 , NhuocDiem = @NhuocDiem
			 , DeXuat	 = @DeXuat	
			 , NhanXetGVCN = @NhanXetGVCN
			 ,  NhanXet_ChuanBiNienKhoaSau = @NhanXet_ChuanBiNienKhoaSau 
        WHERE
               NhanXetThangID = @NhanXetThangID;

		SELECT  @NhanXetThangID             ,
			    @Lop_NhanXetThangID         ,
			    @HSLopID                    ,
			    @HocSinhID                  ,
			    @NoiDungKienThuc_HTML       ,
			    @NoiDungNangLuc_HTML        ,
			    @NoiDungHoatDongKhac_HTML   ,
			    @NoiDungToan_HTML           ,
			    @NoiDungTiengViet_HTML      ,
			    @NoiDungMonHocKhac_HTML     ,
			    @NhanXetCuoiNam_HTML        ,
			    @NhanXetToan_HTML           ,
			    @NhanXetTiengViet_HTML      ,
			    @NhanXetMonHocKhac_HTML     ,
			    @HoatDongGiaoDucKhac_HTML   ,
			    @PhamChatNangLuc_HTML       ,
			    @DiemTiengViet              ,
			    @DiemToan                   ,
			    @SYS_USERID                 ,
			    @PhoiHopCMHS                ,
			    @NhanXetGVCN_VePhuHuynh_HTML,
			    @NhanXetGVCN_VeHocSinh_HTML ,
			    @PhanLoai_TuyenThang        ,
			    @Flyers						,
			    @DiemTA                     ,
			    @DKHocTiep                  ,
			    @DeXuat_NDCamKet            ,
				@UuDiem	  ,
				@NhuocDiem,
				@DeXuat	,
				@NhanXetGVCN,
				@NhanXet_ChuanBiNienKhoaSau

    END;
    ELSE
    BEGIN
        INSERT INTO dbo.tblNhanXetThang
        (
            Lop_NhanXetThangID
          , HSLopID
          , HocSinhID
          , NoiDungKienThuc_HTML
          , NoiDungNangLuc_HTML
          , NoiDungHoatDongKhac_HTML
          , NoiDungToan_HTML
          , NoiDungTiengViet_HTML
          , NoiDungMonHocKhac_HTML
          , SoSao_Toan
          , SoSao_TiengViet
          , DiemTiengViet
          , DiemToan
          , NhanXetCuoiNam_HTML
          , NhanXetToan_HTML
          , NhanXetTiengViet_HTML
          , HoatDongGiaoDucKhac_HTML
          , NhanXetMonHocKhac_HTML
          , PhamChatNangLuc_HTML
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
			,NhuocDiem
			,DeXuat	
			,NhanXetGVCN
			, NhanXet_ChuanBiNienKhoaSau

        )
        VALUES
        (
            @Lop_NhanXetThangID
          , @HSLopID                  -- HSLopID - int
          , @HocSinhID                -- HocSinhID - int
          , @NoiDungKienThuc_HTML     -- NoiDungKienThuc - nvarchar(2000)
          , @NoiDungNangLuc_HTML      -- NoiDungNangLuc - nvarchar(2000)
          , @NoiDungHoatDongKhac_HTML -- NoiDungHoatDongKhac - nvarchar(2000)
          , @NoiDungToan_HTML
          , @NoiDungTiengViet_HTML
          , @NoiDungMonHocKhac_HTML
          , dbo.Convert_Star_By_Diem_NhanXetThang(@DiemToan)
          , dbo.Convert_Star_By_Diem_NhanXetThang(@DiemTiengViet)
          , @DiemTiengViet
          , @DiemToan
          , @NhanXetCuoiNam_HTML
          , @NhanXetToan_HTML
          , @NhanXetTiengViet_HTML
          , @HoatDongGiaoDucKhac_HTML
          , @NhanXetMonHocKhac_HTML
          , @PhamChatNangLuc_HTML
          , 1                         -- Enable - bit
          , @SYS_USERID               -- CreateUser - varchar(9)
          , GETDATE()                 -- CreateTime - datetime 
          , @PhoiHopCMHS
          , @NhanXetGVCN_VePhuHuynh_HTML
          , @NhanXetGVCN_VeHocSinh_HTML
          , @PhanLoai_TuyenThang
          , @Flyers
          , @DiemTA
          , @DKHocTiep
          , @DeXuat_NDCamKet
		  ,@UuDiem	  
		  ,@NhuocDiem
		  ,@DeXuat	
		  , @NhanXetGVCN
		  , @NhanXet_ChuanBiNienKhoaSau
        );
    END;
END;
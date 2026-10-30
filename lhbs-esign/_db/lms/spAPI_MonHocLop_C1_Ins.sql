CREATE	 PROC [dbo].[spAPI_MonHocLop_C1_Ins]
    @JSON_DiemHocSinh NVARCHAR(MAX),
    @SYS_USERID VARCHAR(9)
AS
BEGIN

    DECLARE @Table_Diem_HocSinh TABLE
    (
        KyDanhGia		int				 ,
		LopID			int				 ,
		STT				varchar(50)		 ,
		SoDanhBo		varchar(200)	 ,
		HocSinhID		int				 ,
		HoTen			nvarchar(200)	 ,
		NgaySinh		nvarchar(10)	 ,
		TenLop			nvarchar(100)	 ,
		TenMon			nvarchar(200)	 ,
		ThoiDiemDanhGia	nvarchar(200)	 ,
		NhanXet			nvarchar(500)	 ,
		DiemMonHoc		float			 ,
		MucDoDanhGia	varchar(100)	 
    );
    INSERT INTO @Table_Diem_HocSinh
    (	
         KyDanhGia			,
		 LopID				,
		 STT				,
		 SoDanhBo			,
		 HocSinhID			,
		 HoTen				,
		 NgaySinh			,
		 TenLop				,
		 TenMon				,
		 ThoiDiemDanhGia	,
		 NhanXet			,
		 DiemMonHoc			,
		 MucDoDanhGia	
    )
    SELECT   KyDanhGia			,
             LopID				,
             STT				,
             SoDanhBo			,
             HocSinhID			,
             HoTen				,
             NgaySinh			,
             TenLop				,
             TenMon				,
             ThoiDiemDanhGia	,
             NhanXet			,
             DiemMonHoc			,
             MucDoDanhGia	
    FROM
        OPENJSON(@JSON_DiemHocSinh)
        WITH
        (
             KyDanhGia		int				 ,
			 LopID			int				 ,
			 STT				varchar(50)		 ,
			 HocSinhID		int				 ,
			 SoDanhBo		varchar(200)	 ,
			 HoTen			nvarchar(200)	 ,
			 NgaySinh		nvarchar(10)	 ,
			 TenLop			nvarchar(100)	 ,
			 TenMon			nvarchar(200)	 ,
			 ThoiDiemDanhGia	nvarchar(200)	 ,
			 NhanXet			nvarchar(500)	 ,
			 DiemMonHoc		float			 ,
			 MucDoDanhGia	varchar(100)	 
        );

    -- Merge data into the target table
    MERGE INTO dbo.tbl_QLDiem_Tam_C1 AS Target
    USING @Table_Diem_HocSinh AS Source
    ON Target.LopID = Source.LopID
       AND Target.HocSinhID = Source.HocSinhID
	   AND Target.KyDanhGia = Source.KyDanhGia
    WHEN MATCHED THEN
        UPDATE SET  --Target.KyDanhGia		= source.KyDanhGia		,
				    --Target.LopID			= source.LopID			,
                    Target.STT				= source.STT			,	
                    Target.HocSinhID		= source.HocSinhID		,
                    Target.SoDanhBo			= source.SoDanhBo		,	
                    Target.HoTen			= source.HoTen			,
                    Target.NgaySinh			= source.NgaySinh		,	
                    Target.TenLop			= source.TenLop			,
                    Target.TenMon			= source.TenMon			,
                    Target.ThoiDiemDanhGia	= source.ThoiDiemDanhGia,	
                    Target.NhanXet			= source.NhanXet		,	
                    Target.DiemMonHoc		= source.DiemMonHoc		,
                    Target.MucDoDanhGia		= source.MucDoDanhGia	,	
				   Target.Is_Update = 1,
                   Target.UpdateUser = @SYS_USERID,
                   Target.UpdateTime = GETDATE()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT
        (
            KyDanhGia		,
            LopID			,
            STT				,
            HocSinhID		,
            SoDanhBo		,
            HoTen			,
            NgaySinh		,
            TenLop			,
            TenMon			,
            ThoiDiemDanhGia	,
            NhanXet			,
            DiemMonHoc		,
            MucDoDanhGia	,
			Is_Insert		,
            CreateUser		,
            CreateTime 
        )
        VALUES
        (
		 Source.KyDanhGia		,
		 Source.LopID			,
		 Source.STT				,
		 Source.HocSinhID		,
		 Source.SoDanhBo		,
		 Source.HoTen			,
		 Source.NgaySinh		,
		 Source.TenLop			,
		 Source.TenMon			,
		 Source.ThoiDiemDanhGia	,
		 Source.NhanXet			,
		 Source.DiemMonHoc		,
		 Source.MucDoDanhGia	,
		 1, 
		 @SYS_USERID,
         GETDATE()
		 );

END;
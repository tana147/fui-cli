CREATE PROCEDURE [dbo].[spAPI_BaiHoc_Upd] 
	@BaiHocID INT,
    @NoiDungBaiHoc NVARCHAR(254),
    @GiaoVienID VARCHAR(10),
    @DiemBaiHoc NUMERIC,
    @LoaiBaiHoc NVARCHAR(10),
    @ChuongTrinhHocID INT,
    @CobaiLab bit,
	@CoBaiQuiz  bit,
	@CoTaiLieuHoc bit,
	@CoTaiLieuVideo bit,
    @TrangThaiBaiHoc BIT,
    @BaiDuocMoDen DATETIME,
    @HanChot DATETIME,
    @GiaHanHanChot DATETIME,
    @XuLyQuaHan NVARCHAR(10),
    @ThoiGianLamBai INT,
    @ChoPhepLamLai BIT,
    @SYS_USERID VARCHAR(20)
AS
	BEGIN
		-- Kiểm tra GiaoVienID
	    IF NOT EXISTS (
		SELECT
			1
		FROM
			[LMS-LHBS].dbo.tblGiaoVien
		WHERE
			GiaoVienID = @GiaoVienID)
	    BEGIN
	        PRINT 'GiaoVienID không tồn tại.';
	
	RETURN 1;
	-- Lỗi: GiaoVienID không tồn tại
	END
	-- Kiểm tra ChuongTrinhHocID
	    IF NOT EXISTS (
	SELECT
	1
	FROM
	[LMS-LHBS].dbo.tblLMSChuongTrinhHoc
	WHERE
	ChuongTrinhHocID = @ChuongTrinhHocID)
	    BEGIN
	        PRINT 'ChuongTrinhHocID không tồn tại.';
	
	RETURN 2;
	-- Lỗi: ChuongTrinhHocID không tồn tại
	END
	-- Thêm mới bài học
	UPDATE 
		[LMS-LHBS].dbo.tblLMSBaiHoc
	    SET 
		
		 
    	NoiDungBaiHoc=@NoiDungBaiHoc ,
		GiaoVienID=@GiaoVienID,
		DiemBaiHoc=@DiemBaiHoc ,
		LoaiBaiHoc=@LoaiBaiHoc ,
		ChuongTrinhHocID=@ChuongTrinhHocID,
		CobaiLab=@CobaiLab,
		CoBaiQuiz=@CoBaiQuiz,
		CoTaiLieuHoc=@CoTaiLieuHoc,
		CoTaiLieuVideo=@CoTaiLieuVideo,
		TrangThaiBaiHoc=@TrangThaiBaiHoc,
		BaiDuocMoDen=@BaiDuocMoDen,
		HanChot=@HanChot,
		GiaHanHanChot=@GiaHanHanChot,
		XuLyQuaHan=@XuLyQuaHan,
		ThoiGianLamBai=@ThoiGianLamBai ,
		ChoPhepLamLai=@ChoPhepLamLai,
		CreateUser=@SYS_USERID,
		CreateTime=GETDATE()
		WHERE
			GiaoVienID = @GiaoVienID
			AND ChuongTrinhHocID = @ChuongTrinhHocID
			AND BaiHocID = @BaiHocID
	    
	    
	
	PRINT 'Cập nhật bài học thành công.';
	
	RETURN 0;
	-- Thành công
	END;
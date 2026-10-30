CREATE PROCEDURE [dbo].[spAPI_BaiHoc_Ins] 
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
	    INSERT
		INTO
		[LMS-LHBS].dbo.tblLMSBaiHoc (
        NoiDungBaiHoc ,
		GiaoVienID,
		DiemBaiHoc ,
		LoaiBaiHoc ,
		ChuongTrinhHocID,
		CobaiLab,
		CoBaiQuiz,
		CoTaiLieuHoc,
		CoTaiLieuVideo,
		TrangThaiBaiHoc,
		BaiDuocMoDen,
		HanChot,
		GiaHanHanChot,
		XuLyQuaHan,
		ThoiGianLamBai ,
		ChoPhepLamLai,
		CreateUser,
		CreateTime
	    )
	VALUES (
	@NoiDungBaiHoc,
	@GiaoVienID,
	@DiemBaiHoc,
	@LoaiBaiHoc,
	@ChuongTrinhHocID, 
	@CobaiLab,
	@CoBaiQuiz,
	@CoTaiLieuHoc,
	@CoTaiLieuVideo,
	@TrangThaiBaiHoc, 
	@BaiDuocMoDen,
	@HanChot,
	@GiaHanHanChot,
	@XuLyQuaHan,
	@ThoiGianLamBai, 
	@ChoPhepLamLai,
	@SYS_USERID,
	GETDATE()
	    );
	
	PRINT 'Tạo mới bài học thành công.';
	
	RETURN 0;
	-- Thành công
	END;
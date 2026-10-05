
CREATE PROC [dbo].[spAPI_HoiDong_Get_ByHoiDongID]  --1289
@HoiDong_ID INT,
@SYS_USERID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN	
	DECLARE @SLTVHD INT
	SET @SLTVHD = (SELECT COUNT(*) FROM  [dbo].[HoiDongThanhVien] WHERE HoiDongID = @HoiDong_ID AND Is_Xoa = 0)

	DECLARE @is_CoDiem AS BIT 
	BEGIN
		SET @is_CoDiem  = (SELECT DISTINCT Is_PublishDiem FROM  [dbo].[HoiDongThanhVien] WHERE HoiDongID = @HoiDong_ID AND Is_Xoa = 0)
	END

	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,9) ANd @is_CoDiem  = 0) 
	BEGIN 
		--SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		--RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	DECLARE @ProcessID_NC INT = 1
	DECLARE @ProcessID_UD INT = 4

	SELECT 
		  HD.[HoiDongID]
		, HD.[StudentID]
		, S.HoSV
		, S.TenSV
		, N.NganhID
		, N.TenNganh
		, N.MaNganh
		, HD.[DeTai]
		, HD.[Decision_ID]
		, HD.[LoaiHoiDong]
		, HD.[DiemHoiDong]
		, HD.[KetQuaHoiDong]
		, HD.[NhanXet]
		, HD.[FileNhanXetID]
		, HD.[FileNhanXetName]
		, PS.[Process_ID]
		, '/FileData/' + HD.[FileNhanXetID] AS FileNhanXetURL
		, HD.[HoiDong_Status] 
		, HD.ThoiGianBaoVe
		, CASE WHEN LEN(D.[Decision_SoQD]) > 20 OR ISNULL(D.[Decision_SoQD],'') = '' THEN N'            /QĐ-ĐHLH' ELSE  D.[Decision_SoQD] END  AS Decision_SoQD
		, CASE WHEN ISNULL(D.[Decision_NgayQD],'') = '' THEN ' ... ' ELSE D.[Decision_NgayQD] END  AS Decision_NgayQD
		, CASE WHEN ISNULL(D.[Decision_ThangQD],'')= '' THEN ' ... ' ELSE D.[Decision_ThangQD] END Decision_ThangQD
		, CASE WHEN ISNULL(D.[Decision_NamQD],'')= '' THEN ' 20... ' ELSE D.Decision_NamQD END AS Decision_NamQD
		, D.[DecisionFile_ID]
		, D.[DecisionFile_Url]
		, D.[DecisionFile_Name]
		, CONVERT(INT, RIGHT(D.Created_By,4)) AS  Decision_NguoiTao
		, @SLTVHD AS SLTVHD_So
		, [dbo].[Num2Text](@SLTVHD) AS SLTVHD_Chu
		, HD.Is_PublishDiem
		, HD.HoiDong_Status
		
		FROM HoiDong HD 
			INNER JOIN StudentInfo S ON HD.StudentID = S.StudentID
			INNER JOIN Nganh N ON N.NganhID = S.NganhID
			INNER JOIN Decision D ON D.Decision_ID = HD.Decision_ID
			INNER JOIN Process_Student PS ON PS.Student_ID = HD.StudentID 
				AND PS.Process_ID IN (@ProcessID_NC, @ProcessID_UD) AND PS.Process_Student_Status <> 'X'
		WHERE HD.HoiDongID = @HoiDong_ID --AND HoiDong_Status = 0
	
	SELECT 
		ROW_NUMBER() OVER (ORDER BY [TVHDID]) AS 'STT'
		,[TVHDID]
		, [HoiDongID]
		, [StudentID]
		, TV.[HocViHocHam]
		, TV.[GiangVienID]
		, TV.[HoTenGiangVien]
		, TV.[CoQuanCongTac]
		, gv.[CoQuanCongTacTiengViet]
		, gv.[NganhID]
		, TV.[NganhGiangDay]
		, TV.[ChucTrach]
		, [Diem]
		, [KetQua]
		, [NhanXet]
		, [FileNhanXetID]
		, [FileNhanXetName]
		, '/FileData/' + TV.[FileNhanXetID] AS FileNhanXetURL
		, [FileDiemID]
		, [FileDiemName]
		, '/FileData/' + TV.FileDiemID AS FileDiemURL
		,  TV.Is_PublishDiem
		
		FROM [dbo].[HoiDongThanhVien]  TV 
		INNER JOIN ChucTrach CT ON TV.ChucTrach = CT.ChucTrach AND CT.LoaiID =1
		LEFT JOIN GiangVien gv ON gv.GiangVienID = TV.GiangVienID
		WHERE TV.HoiDongID = @HoiDong_ID AND TV.Is_Xoa = 0
		ORDER BY CT.Sort

END

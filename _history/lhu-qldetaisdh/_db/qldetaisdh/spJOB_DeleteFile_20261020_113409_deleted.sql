

CREATE PROC [dbo].[spJOB_DeleteFile]
AS
BEGIN
	DECLARE @FileDangSuDung TABLE (FileID VARCHAR(100))
	
	--	Flow_Detail
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FILE_ID FROM Flow_Detail WHERE File_ID <> ''
	
	--	Decision
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  DecisionFile_ID  FROM Decision WHERE DecisionFile_ID <> ''
	
	--	HoiDong (FileNhanXetID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileNhanXetID FROM HoiDong WHERE FileNhanXetID <> ''
	
	--	HoiDong (FileKiemPhieuID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileKiemPhieuID FROM HoiDong WHERE FileKiemPhieuID <> ''
	
	--	HoiDongThanhVien (FileNhanXetID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT 	[FileNhanXetID] FROM [dbo].[HoiDongThanhVien] WHERE [FileNhanXetID] <> ''
	
	--	HoiDongThanhVien (FileDiemID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT 	 [FileDiemID] FROM [dbo].[HoiDongThanhVien] WHERE [FileDiemID] <> ''
	
	--	Decision_Detail
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  DecisionFile_ID FROM Decision_Detail WHERE DecisionFile_ID <> ''
	
	--	Flow_Detail_His
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  File_ID FROM Flow_Detail_His WHERE File_ID <> ''
	
	--	Flow_Detail_LOG
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  File_ID FROM Flow_Detail_LOG WHERE File_ID <> ''
	
	--	Flow_Detail_Old
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  File_ID FROM Flow_Detail_Old WHERE File_ID <> ''
	
	--	GiangVien (FileVanBang_ID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileVanBang_ID FROM GiangVien WHERE FileVanBang_ID <> ''
	
	--	GiangVien (FileLyLichKH_ID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileLyLichKH_ID FROM GiangVien WHERE FileLyLichKH_ID <> ''
	
	--	HoiDongThanhVien_Old (FileNhanXetID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileNhanXetID FROM HoiDongThanhVien_Old WHERE FileNhanXetID <> ''
	
	--	HoiDongThanhVien_Old (FileDiemID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileDiemID FROM HoiDongThanhVien_Old WHERE FileDiemID <> ''
	
	--	HoiDong_Old (FileNhanXetID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileNhanXetID FROM HoiDong_Old WHERE FileNhanXetID <> ''
	
	--	HoiDong_Old (FileKiemPhieuID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileKiemPhieuID FROM HoiDong_Old WHERE FileKiemPhieuID <> ''

	SELECT FILEID FROM @FileDangSuDung
	SELECT FileID, FileName, CreateTime , Size
	FROM [dbo].[FileData] WHERE FileID NOT IN (SELECT FILEID FROM @FileDangSuDung)
	order by CreateTime desc
	

--	DELETE FileData WHERE FileID NOT IN (SELECT FILEID FROM @FileDangSuDung)
END


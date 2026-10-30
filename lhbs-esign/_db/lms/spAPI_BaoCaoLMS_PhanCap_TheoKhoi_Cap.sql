CREATE PROC [dbo].[spAPI_BaoCaoLMS_PhanCap_TheoKhoi_Cap]
	@SYS_USERID VARCHAR(9),
	@HocKi INT,
	@NienKhoa INT
AS
BEGIN
	DECLARE @GiaoVienID VARCHAR(9) = dbo.fn_GetUser_LMS(@SYS_USERID) 
	DECLARE @Table_Khoi TABLE(CapID INT, KhoiID INT)
	INSERT @Table_Khoi
	SELECT DISTINCT k.CapID, gvl.KhoiID  
	FROM dbo.tblGiaoVienLop gvl
		INNER JOIN dbo.tblKhoi k ON k.KhoiID = gvl.KhoiID  
	WHERE gvl.Enable = 1 AND NienKhoa = @NienKhoa 
	AND gvl.HocKy = @HocKi
	AND GiaoVienID = @GiaoVienID
	UNION 
	SELECT DISTINCT k.CapID, gvl.KhoiID  
	FROM dbo.tblEL_GiaoVienLop gvl
		INNER JOIN dbo.tblKhoi k ON k.KhoiID = gvl.KhoiID 
	WHERE gvl.Enable = 1 AND NienKhoa = @NienKhoa 
	AND GiaoVienID = @GiaoVienID
	AND gvl.HocKy = @HocKi

	DECLARE @Table_BT TABLE(KhoiID INT, BT INT)
	INSERT @Table_BT
	SELECT asm.KhoiID, COUNT(asm.AssignmentID) 
	FROM dbo.tblEL_Assignments asm  
	WHERE CreateUser = @GiaoVienID AND asm.IsDeleted = 0 AND ISNULL(asm.IsDev, 0) <> 1
	GROUP BY asm.KhoiID 

	SELECT k.CapID, K.KhoiID, ISNULL(BT,0) AS BT FROM @Table_Khoi K
		LEFT JOIN @Table_BT T ON T.KhoiID = K.KhoiID
END
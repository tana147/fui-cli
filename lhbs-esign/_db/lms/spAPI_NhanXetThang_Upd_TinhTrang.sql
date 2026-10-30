CREATE PROC [dbo].[spAPI_NhanXetThang_Upd_TinhTrang]
@Lop_NhanXetThangID INT,
@TinhTrang TINYINT,
@ReasonReject NVARCHAR(4000)
AS
BEGIN
    UPDATE dbo.tblNhanXetThang_Lop
	SET
		TinhTrang = @TinhTrang,
		ReasonReject = @ReasonReject 
	WHERE 
		Lop_NhanXetThangID = @Lop_NhanXetThangID 
END 
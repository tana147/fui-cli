CREATE PROCEDURE [dbo].[spAPI_AnPhamFile_Del]
    @AnPhamFileID INT,
    @sys_UserID varchar(9)
AS
BEGIN
    /* Step 3: INSERT DANH SÁCH FILE MINH CHỨNG HOÀN PHÍ */
		-- Parse JSON proofs data
		UPDATE [dbo].[AnPham_File]
		SET
		  Is_Xoa = 1,
		  NhanVienCapNhat = @sys_UserID,
		  ThoiGianCapNhat = GETDATE	()
		WHERE [dbo].[AnPham_File].AnPhamFileID = @AnPhamFileID

END;

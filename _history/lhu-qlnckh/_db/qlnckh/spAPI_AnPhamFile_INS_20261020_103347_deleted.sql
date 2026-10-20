CREATE PROCEDURE [dbo].[spAPI_AnPhamFile_INS]
    @ProofSObjArr NVARCHAR(MAX),
    @sys_UserID varchar(9)
AS
BEGIN
    /* Step 3: INSERT DANH SÁCH FILE MINH CHỨNG HOÀN PHÍ */
		-- Parse JSON proofs data
		INSERT INTO [dbo].[AnPham_File]
           (
		   [AnPhamID]
		   ,[FileIDList]
           ,[LoaiFile]
           ,[MoTa]
           ,[TrangThai]
           ,[NhanVienCapNhat]
           ,[ThoiGianCapNhat]
		   )
		SELECT
			json.AnPhamID
			,json.FileIDList
			,json.LoaiFile
			,json.MoTa
			,0
			,@SYS_UserID
            ,GETDATE()
            
		FROM OPENJSON(@ProofSObjArr)
		WITH (
			AnPhamID INT,
			FileIDList CHAR(500),
			LoaiFile TINYINT,
			MoTa NVARCHAR(500)
		) AS json;
END;

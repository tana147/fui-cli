CREATE PROCEDURE [dbo].[spAPI_AnPhamFile_Udp]
    @ProofSObjArr NVARCHAR(MAX),
    @sys_UserID varchar(9)
AS
BEGIN
    /* Step 3: INSERT DANH SÁCH FILE MINH CHỨNG HOÀN PHÍ */
		-- Parse JSON proofs data
		UPDATE [dbo].[AnPham_File]
		SET
		   [FileIDList] = json.FileIDList
           ,[LoaiFile] = json.LoaiFile
           ,[MoTa] = json.MoTa
           ,[NhanVienCapNhat] = @SYS_UserID
           ,[ThoiGianCapNhat]  = GETDATE()
		FROM OPENJSON(@ProofSObjArr)
		WITH (
			AnPhamFileID INT,
			FileIDList CHAR(500),
			LoaiFile TINYINT,
			MoTa NVARCHAR(500)
		) AS json
		WHERE [dbo].[AnPham_File].AnPhamFileID = json.AnPhamFileID

END;

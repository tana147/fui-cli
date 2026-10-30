CREATE PROC [dbo].[spAPI_ChiTieu_Update_TA1_C3]
	@JsonChiTieu varchar(MAX),
	@Sys_UserID varchar(9)
AS
BEGIN
	DECLARE @tempTable table(ChiTieu_ID int, ChiTieuDatRa float, ChiTieuThucTe float, SoVoiThucTe float, NhomID varchar(10),MucDo_ID int)
	INSERT INTO @tempTable
	SELECT * FROM OPENJSON(@JsonChiTieu)
	WITH(ChiTieu_ID int, ChiTieuDatRa float, ChiTieuThucTe float, SoVoiThucTe float, NhomID varchar(10),MucDo_ID int)

	--UPDATE tbl
	--	SET tbl.ChiTieuDatRa = temp.ChiTieuDatRa,
	--		tbl.UpdateUser = @SYSUSER_ID,
	--		tbl.UpdateTime = GETDATE()
	--FROM tbl_ChiTieu tbl
	--INNER JOIN @tempTable temp ON tbl.ChiTieu_ID = temp.ChiTieu_ID;


	MERGE tbl_ChiTieu AS target
	USING @tempTable AS source
	ON target.ChiTieu_ID = source.ChiTieu_ID
	WHEN MATCHED THEN
	    UPDATE 
	        SET target.ChiTieuDatRa = source.ChiTieuDatRa,
				target.UpdateUser = @Sys_UserID,
				target.UpdateTime = GETDATE()
	WHEN NOT MATCHED BY TARGET THEN
	    INSERT ( ChiTieuDatRa, ChiTieuThucTe,SoVoiThucTe, MucDo_ID, NhomID, CreateUser, CreateTime,Enable)
	    VALUES (source.ChiTieuDatRa, source.ChiTieuThucTe, source.SoVoiThucTe,source.MucDo_ID, source.NhomID,@Sys_UserID,GETDATE(),1);

END
CREATE PROC [dbo].[spAPI_ChiTieu_Update_TA2]
	@JsonChiTieu varchar(MAX),
	@Sys_UserID varchar(9)
AS
BEGIN
	DECLARE @tempTable table(ChiTieu_ID int, ChiTieuDatRa float, ChiTieuThucTe float, SoVoiThucTe float,MucDo_ID int, TrinhDo nvarchar(50),NhomID varchar(10))
	INSERT INTO @tempTable
	SELECT * FROM OPENJSON(@JsonChiTieu)
	WITH(ChiTieu_ID int, ChiTieuDatRa float, ChiTieuThucTe float, SoVoiThucTe float,MucDo_ID int, TrinhDo nvarchar(50),NhomID varchar(10))

	MERGE tbl_ChiTieu AS target
	USING @tempTable AS source
	ON target.ChiTieu_ID = source.ChiTieu_ID
	WHEN MATCHED THEN
	    UPDATE 
	        SET target.ChiTieuDatRa = source.ChiTieuDatRa,
				target.TrinhDo = source.TrinhDo,
				target.UpdateUser = @Sys_UserID,
				target.UpdateTime = GETDATE()
	WHEN NOT MATCHED BY TARGET THEN
	    INSERT ( ChiTieuDatRa, ChiTieuThucTe,SoVoiThucTe, MucDo_ID,TrinhDo,NhomID, CreateUser, CreateTime,Enable)
	    VALUES (source.ChiTieuDatRa, source.ChiTieuThucTe, source.SoVoiThucTe,source.MucDo_ID,TrinhDo,NhomID,@Sys_UserID,GETDATE(),1);

END

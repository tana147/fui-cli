-- [dbo].[spAPI_BaoCao_TongHop_Get]1
CREATE PROC [dbo].[spAPI_BaoCao_TongHop_Get_ByBaoCaoID]
	@BaoCaoID INT
AS
BEGIN
     SELECT 
		* 
	 FROM tblBaoCao_ChiTiet
	 WHERE Enable = 1 AND BaoCaoID = @BaoCaoID 
END


CREATE PROCEDURE [dbo].[spAPI_HDKH_DM_Select] 
	@sys_UserID VARCHAR(9)
	AS
	BEGIN
		select	tbl.name as 'TableName' 
		from sys.tables tbl 
		
		where tbl.name like 'tblHDKH_DM_%' 
		select * from tblHDKH_DM_BacDaoTao
	END
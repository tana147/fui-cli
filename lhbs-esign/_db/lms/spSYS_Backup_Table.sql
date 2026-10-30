CREATE PROC [dbo].[spSYS_Backup_Table]
	as
	begin
		DECLARE @table_name1 NVARCHAR(128) = 'tblMonHocLop' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '_'),'-','_'),' ','_');
		DECLARE @sql1 NVARCHAR(MAX);
		SET @sql1 = N'SELECT * INTO ' + @table_name1 + ' FROM tblMonHocLop';
		EXEC sp_executesql @sql1;

		DECLARE @table_name2 NVARCHAR(128) = 'tblKetQuaHocTap' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '_'),'-','_'),' ','_');
		DECLARE @sql2 NVARCHAR(MAX);
		SET @sql2 = N'SELECT * INTO ' + @table_name2 + ' FROM tblKetQuaHocTap';
		EXEC sp_executesql @sql2;

		DECLARE @table_name3 NVARCHAR(128) = 'TemplateBangDiem' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '_'),'-','_'),' ','_');
		DECLARE @sql3 NVARCHAR(MAX);
		SET @sql3 = N'SELECT * INTO ' + @table_name3 + ' FROM TemplateBangDiem';
		EXEC sp_executesql @sql3;


		DECLARE @table_name4 NVARCHAR(128) = 'TemplateBangDiemChiTiet' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '_'),'-','_'),' ','_');
		DECLARE @sql4 NVARCHAR(MAX);
		SET @sql4 = N'SELECT * INTO ' + @table_name4 + ' FROM TemplateBangDiemChiTiet';
		EXEC sp_executesql @sql4;
	END

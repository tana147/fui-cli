	--Bước 1. Tạo 1 backup table 
	

	CREATE PROC [dbo].[spSYS_Backup_Table]
	as
	begin
		DECLARE @table_name1 NVARCHAR(128) = 'Flow_' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '_'),'-','_'),' ','_');
		DECLARE @sql1 NVARCHAR(MAX);
		SET @sql1 = N'SELECT * INTO ' + @table_name1 + ' FROM Flow';
		EXEC sp_executesql @sql1;


		DECLARE @table_name2 NVARCHAR(128) = 'Flow_Detail_' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '_'),'-','_'),' ','_');
		DECLARE @sql2 NVARCHAR(MAX);
		SET @sql2 = N'SELECT * INTO ' + @table_name2 + ' FROM Flow_Detail';
		EXEC sp_executesql @sql2;
		

		DECLARE @table_name3 NVARCHAR(128) = 'Tasks_' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '_'),'-','_'),' ','_');
		DECLARE @sql3 NVARCHAR(MAX);
		SET @sql3 = N'SELECT * INTO ' + @table_name3 + ' FROM Tasks';
		EXEC sp_executesql @sql3;


		DECLARE @table_name4 NVARCHAR(128) = 'Task_Task_' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '_'),'-','_'),' ','_');
		DECLARE @sql4 NVARCHAR(MAX);
		SET @sql4 = N'SELECT * INTO ' + @table_name4 + ' FROM Task_Task';
		EXEC sp_executesql @sql4;


		DECLARE @table_name5 NVARCHAR(128) = 'Task_Detail_' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '_'),'-','_'),' ','_');
		DECLARE @sql5 NVARCHAR(MAX);
		SET @sql5 = N'SELECT * INTO ' + @table_name5 + ' FROM Task_Detail';
		EXEC sp_executesql @sql5;


		
		DECLARE @table_name6 NVARCHAR(128) = 'HoiDong' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '_'),'-','_'),' ','_');
		DECLARE @sql6 NVARCHAR(MAX);
		SET @sql6 = N'SELECT * INTO ' + @table_name6 + ' FROM HoiDong';
		EXEC sp_executesql @sql6;

		DECLARE @table_name7 NVARCHAR(128) = 'Process_Student' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '_'),'-','_'),' ','_');
		DECLARE @sql7 NVARCHAR(MAX);
		SET @sql7 = N'SELECT * INTO ' + @table_name7 + ' FROM Process_Student';
		EXEC sp_executesql @sql7;

		DECLARE @table_name8 NVARCHAR(128) = 'StudentInfo' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '_'),'-','_'),' ','_');
		DECLARE @sql8 NVARCHAR(MAX);
		SET @sql8 = N'SELECT * INTO ' + @table_name8 + ' FROM StudentInfo';
		EXEC sp_executesql @sql8;

		DECLARE @table_name9 NVARCHAR(128) = 'Decision' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '_'),'-','_'),' ','_');
		DECLARE @sql9 NVARCHAR(MAX);
		SET @sql9 = N'SELECT * INTO ' + @table_name9 + ' FROM Decision';
		EXEC sp_executesql @sql9;
	end
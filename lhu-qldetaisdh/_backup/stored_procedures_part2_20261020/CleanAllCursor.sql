CREATE PROCEDURE dbo.CleanAllCursor 
@cursorname varchar(100)
AS
BEGIN
	DECLARE @cursorStatus int 
	Declare @name varchar(100);
	DECLARE @sql varchar(255);
	while 1=1
	begin
		select @name =min(name)
		from sys.dm_exec_cursors(0)  
		where name =@cursorname;

		if(@name is null)
			break;
		SET @cursorStatus =  (SELECT cursor_status('global',@name))
		 

		IF @cursorStatus > 0
			SET @sql = 'CLOSE '+@name

		IF @cursorStatus > -3
			SET @sql = @sql+' DEALLOCATE '+@name

		IF @sql <> ''
			exec(@sql)
	end
END
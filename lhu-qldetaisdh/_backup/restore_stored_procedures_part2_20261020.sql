-- BACKUP OF 31 STORED PROCEDURES / FUNCTIONS (PART 2)
-- DATE: 2026-10-20

-- =============================================
-- OBJECT: bk----UPDATE_STATUS (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROCEDURE [dbo].[UPDATE_STATUS]
	@Student_ID varchar(20),
	@Process_ID int,
	@Flow_ID	int,
	@Task_ID	int,
	@Task_Detail_ID int,
	@Flow_Detail_Status varchar(20)
AS
BEGIN
	DECLARE @ERRCODE INT;
	DECLARE @err_location varchar(1000);
	set @err_location= 'Flow['+ +cast(@Flow_id as varchar) +']-Student[' + cast(@Student_ID as varchar)+']';

	DECLARE @TASK_BEGIN int; 

	DECLARE @TASK_PARENT int; 

	DECLARE @SUM_DETAIL_STATUS INT;
	DECLARE @CNT_PROCESSING INT;

	DECLARE @SUM_CHILD_FLOW_STATUS INT;
	DECLARE @CNT_CHILD_FLOW_PROCESSING INT;	
	
	BEGIN TRY 

		BEGIN TRANSACTION; 

		SELECT @TASK_BEGIN= isnull(TASK_BEGIN,-1) FROM PROCESS_STUDENT WHERE Process_ID = @Process_ID AND STUDENT_ID= @Student_ID AND USE_YN=1;

		IF(@TASK_BEGIN <0)
		BEGIN
			RAISERROR(N'Không tìm thấy Task_begin trong Proceess', 16, 1);
			return 0;
		END;

		--SELECT * FROM FLOW_DETAIL
		UPDATE FLOW_DETAIL SET FLOW_DETAIL_STATUS = @Flow_Detail_Status 
		WHERE FLOW_ID			= @FLOW_ID
			AND TASK_ID			= @TASK_ID
			AND TASK_DETAIL_ID	= CASE WHEN @Task_Detail_ID IS NULL OR @Task_Detail_ID =0 THEN TASK_DETAIL_ID ELSE @Task_Detail_ID END
			;
	
		DECLARE TASK CURSOR FOR
		 WITH TASK_PARENT AS(
		 SELECT TASK_PARENT, TASK_ID, FLOW_ID, 0 LV, TASK_REQUIRE  FROM FLOW WHERE STUDENT_ID = @Student_ID AND FLOW_ID=@Flow_id
		 UNION ALL
		 SELECT A.TASK_PARENT, A.TASK_ID, A.FLOW_ID, LV+1 LV, A.TASK_REQUIRE  FROM FLOW A INNER JOIN TASK_PARENT B ON A.TASK_ID = B.TASK_PARENT
		 )
		 SELECT TASK_PARENT, LV 
		 FROM TASK_PARENT
		 WHERE TASK_PARENT <> @TASK_BEGIN
		 union all
		 SELECT TASK_ID, -1 LV  FROM FLOW WHERE STUDENT_ID = @Student_ID AND FLOW_ID=@Flow_id
		 ORDER BY LV
		 ;

		 Open TASK;
		 FETCH NEXT FROM TASK INTO @TASK_PARENT;
		 WHILE @@FETCH_STATUS = 0
		 BEGIN
			--GET STATUS CHILD NODE
			SELECT @SUM_CHILD_FLOW_STATUS = SUM(CASE WHEN TASK_REQUIRE = 1 THEN CASE WHEN FLOW_STATUS <> 'COMPLETED' THEN 1 ELSE 0 END
													ELSE CASE WHEN FLOW_STATUS ='WAIT' THEN 0 ELSE 1 END
												END),
				  @CNT_CHILD_FLOW_PROCESSING= SUM(CASE WHEN FLOW_STATUS IN('REJECTED','PROCCESSING') THEN 1 ELSE 0 END)
			FROM FLOW 
			WHERE TASK_PARENT = @TASK_PARENT AND STUDENT_ID = @Student_ID
			; 

			set @SUM_CHILD_FLOW_STATUS = isnull(@SUM_CHILD_FLOW_STATUS,0);
			set @CNT_CHILD_FLOW_PROCESSING = isnull(@CNT_CHILD_FLOW_PROCESSING,0);

			--UPDATE FLOW STATUS
			SELECT  @SUM_DETAIL_STATUS= SUM(CASE WHEN FLOW_DETAIL_STATUS<>'COMPLETED' THEN 1 ELSE 0 END), 
					@CNT_PROCESSING =SUM(CASE WHEN FLOW_DETAIL_STATUS IN('REJECTED','PROCCESSING') THEN 1 ELSE 0 END)
			FROM FLOW_DETAIL
			WHERE TASK_ID = @TASK_PARENT;

			IF(@SUM_DETAIL_STATUS=0 AND @SUM_CHILD_FLOW_STATUS = 0)--COMPLETED
			BEGIN 
				UPDATE FLOW SET FLOW_STATUS ='COMPLETED' WHERE TASK_ID= @TASK_PARENT  ;
			END
			ELSE 
			BEGIN
				IF(@CNT_PROCESSING>0 OR @CNT_CHILD_FLOW_PROCESSING >0)
				BEGIN
					UPDATE FLOW SET FLOW_STATUS ='PROCCESSING' WHERE TASK_ID= @TASK_PARENT ;
				END
			END
			--END UPDATE FOW STATUS 

			FETCH NEXT FROM TASK INTO @TASK_PARENT;
		 END

		 CLOSE TASK;
		DEALLOCATE TASK;  

		--UPDATE STATUS PROCESS STUDENT
		SELECT @SUM_CHILD_FLOW_STATUS = SUM(CASE WHEN TASK_REQUIRE = 1 THEN CASE WHEN FLOW_STATUS <> 'COMPLETED' THEN 1 ELSE 0 END
													ELSE CASE WHEN FLOW_STATUS ='WAIT' THEN 0 ELSE 1 END
												END),
				@CNT_CHILD_FLOW_PROCESSING= SUM(CASE WHEN FLOW_STATUS IN('REJECTED','PROCCESSING') THEN 1 ELSE 0 END)
			FROM FLOW 
			WHERE TASK_PARENT = @TASK_BEGIN AND STUDENT_ID = @Student_ID
			;
		IF( @SUM_CHILD_FLOW_STATUS = 0)--COMPLETED
		BEGIN 
			UPDATE PROCESS_STATUS SET Process_Student_Status ='COMPLETED' 
			WHERE STUDENT_ID= @Student_ID AND USE_YN=1
		END 
		ELSE
		BEGIN 
			IF(@CNT_CHILD_FLOW_PROCESSING>0)
			BEGIN
				UPDATE PROCESS_STATUS SET Process_Student_Status ='PROCCESSING' 
				WHERE STUDENT_ID= @Student_ID AND USE_YN=1;
			END
		END 
		 
		COMMIT TRANSACTION ;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION ;
		SET @ERRCODE = @@ERROR;
		set @err_location= 'Flow['+ +cast(@Flow_ID as varchar) +']-Student[' + cast(@Student_ID as varchar)+']:' + @err_location;
		RAISERROR(@err_location, 16, 1);
			return 0;
END CATCH
END
GO

-- =============================================
-- OBJECT: CleanAllCursor (SQL_STORED_PROCEDURE)
-- =============================================
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
GO

-- =============================================
-- OBJECT: FLow_UpdateStatus (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROCEDURE [dbo].[FLow_UpdateStatus]
	@Student_ID varchar(20),
	@Process_ID int, 
	@IN_Task_ID	int,
	@user_id    varchar(20),
	@Out_Err_code int out,
	@Out_Err_Loc varchar(1000) out
AS
BEGIN 
	set @Out_Err_Loc= 'UPDATE_STATUS-Flow['+ +cast(@Process_ID as varchar) +']-Student[' + cast(@Student_ID as varchar)+']';

	DECLARE @TASK_BEGIN int; 
	DECLARE @TASK_PARENT int;  
	DECLARE @TASK_ID int;
	DECLARE @FLOW_ID int;
	DECLARE @FLOW_PARENT int;
	DECLARE @LV int;
	DECLARE @NOW_STATUS VARCHAR(20); 

	SELECT @TASK_BEGIN= isnull(TASK_BEGIN,-1) FROM PROCESS_STUDENT WHERE Process_ID = @Process_ID AND STUDENT_ID= @Student_ID AND USE_YN=1;

		IF(@TASK_BEGIN <0)
		BEGIN
			set @Out_Err_code =1;
			set @Out_Err_Loc = @Out_Err_Loc + '{PROCESS_STUDENT} Data does not exists!';
			--RAISERROR(@Out_Err_Loc, 16, 1);
			return 0;
		END; 
		DECLARE TASK_DETAIL_STATUS CURSOR LOCAL FOR
			WITH TASK_PARENT AS(
				SELECT TASK_PARENT, TASK_ID, FLOW_ID, 0 LV, TASK_REQUIRE, 0 FLOW_PARENT  FROM FLOW WHERE Process_ID = @Process_ID AND STUDENT_ID = @Student_ID AND Task_ID=@IN_Task_ID AND USE_YN=1
				UNION ALL
				SELECT A.TASK_PARENT, A.TASK_ID, A.FLOW_ID, LV+1 LV, A.TASK_REQUIRE, B.FLOW_ID FLOW_PARENT  FROM FLOW A INNER JOIN TASK_PARENT B ON A.TASK_ID = B.TASK_PARENT
				WHERE A.USE_YN=1
			)
			SELECT TASK_PARENT, Task_ID, LV, FLOW_ID, FLOW_PARENT
			FROM TASK_PARENT
			--WHERE TASK_PARENT <> @TASK_BEGIN
			ORDER BY LV
			;
			 
	BEGIN TRY  
			Open TASK_DETAIL_STATUS;
			FETCH NEXT FROM TASK_DETAIL_STATUS INTO @TASK_PARENT,@TASK_ID,@LV,@FLOW_ID,@FLOW_PARENT;
			set @Out_Err_code=0
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF(@LV=0)--last child task
				BEGIN					
					SET @NOW_STATUS = dbo.CheckStatusFlow(@Student_ID,@Process_ID,@FLOW_ID,@TASK_ID,@TASK_BEGIN);
					--set @Out_Err_Loc = @Out_Err_Loc + 'last-child--CheckStatusFlow('+@Student_ID+','+cast(@Process_ID as varchar)+','+cast(@FLOW_ID  as varchar)+','+cast(@TASK_ID as varchar)+','+cast(@TASK_BEGIN as varchar)+')='+@NOW_STATUS;
					IF(@NOW_STATUS=' ')
					BEGIN
						set @Out_Err_code =21;
						set @Out_Err_Loc = @Out_Err_Loc + '{FLOW} Update Flow Status error !'+'CheckStatusFlow('+@Student_ID+','+cast(@Process_ID as varchar)+','+cast(@FLOW_ID  as varchar)+','+cast(@TASK_ID as varchar)+','+cast(@TASK_BEGIN as varchar)+')';
						--CLOSE TASK_BY_TASK;
						--DEALLOCATE TASK_BY_TASK;  
						--RAISERROR(@Out_Err_Loc, 16, 1);
						break;
						--return 0;
					END;	
					UPDATE FLOW SET FLOW_STATUS = @NOW_STATUS, [Updated_By]=@user_id,[Updated_At]=getdate()
					WHERE Process_ID = @Process_ID AND STUDENT_ID = @Student_ID AND FLOW_ID = @FLOW_ID AND Task_ID=@TASK_ID AND USE_YN=1
					;
				END;
				--now task
				if(@TASK_PARENT <> @TASK_BEGIN)
				begin					
					SET @NOW_STATUS = dbo.CheckStatusFlow(@Student_ID,@Process_ID,@FLOW_PARENT,@TASK_PARENT,@TASK_BEGIN);
					--set @Out_Err_Loc = @Out_Err_Loc + 'now task--CheckStatusFlow('+@Student_ID+','+cast(@Process_ID  as varchar)+','+cast(@FLOW_PARENT as varchar)+','+cast(@TASK_PARENT as varchar)+','+cast(@TASK_BEGIN as varchar)+')='+@NOW_STATUS;
					IF(@NOW_STATUS=' ')
					BEGIN
						set @Out_Err_code =22;
						set @Out_Err_Loc = @Out_Err_Loc + '{FLOW} Update Flow Status error !'+'CheckStatusFlow('+@Student_ID+','+cast(@Process_ID  as varchar)+','+cast(@FLOW_PARENT as varchar)+','+cast(@TASK_PARENT as varchar)+','+cast(@TASK_BEGIN as varchar)+')';
						--CLOSE TASK_BY_TASK;
						--DEALLOCATE TASK_BY_TASK;  
						--RAISERROR(@Out_Err_Loc, 16, 1);
						--return 0;
						break;
					END;	
					UPDATE FLOW SET FLOW_STATUS = @NOW_STATUS, [Updated_By]=@user_id,[Updated_At]=getdate()
					WHERE Process_ID = @Process_ID AND STUDENT_ID = @Student_ID AND FLOW_ID = @FLOW_PARENT AND Task_ID=@TASK_PARENT AND USE_YN=1
					;
				end
				FETCH NEXT FROM TASK_DETAIL_STATUS INTO @TASK_PARENT,@TASK_ID,@LV,@FLOW_PARENT;
			END

			CLOSE TASK_DETAIL_STATUS;
			DEALLOCATE TASK_DETAIL_STATUS;
			if(@Out_Err_code>0)  
				return 0; 

		--UPDATE STATUS PROCESS STUDENT
		SET @NOW_STATUS = dbo.CheckStatusFlow(@Student_ID,@Process_ID,0,@TASK_BEGIN,@TASK_BEGIN);
		IF(@NOW_STATUS=' ')
		BEGIN
			set @Out_Err_code =30;
			set @Out_Err_Loc = @Out_Err_Loc + '{PROCESS_STATUS} Update Flow Status error !'+'CheckStatusFlow('+@Student_ID+','+cast(@Process_ID as varchar)+',0,'+cast(@TASK_BEGIN as varchar)+','+cast(@TASK_BEGIN as varchar)+')';
			--RAISERROR(@Out_Err_Loc, 16, 1);
			return 0;
		END;   
		UPDATE PROCESS_Student SET Process_Student_Status =@NOW_STATUS, [Updated_By]=@user_id,[Updated_At]=getdate()
		WHERE Process_ID = @Process_ID AND STUDENT_ID= @Student_ID AND USE_YN=1
		;  
		SET @Out_Err_code = 0;
		set @Out_Err_Loc= @Out_Err_Loc+'OK';
		return 1
	END TRY
	BEGIN CATCH
		CLOSE TASK_DETAIL_STATUS;
		DEALLOCATE TASK_DETAIL_STATUS;
		SET @Out_Err_code = @@ERROR;
		set @Out_Err_Loc= 'Flow['+ +cast(@Flow_ID as varchar) +']-Student[' + cast(@Student_ID as varchar)+']:' + @Out_Err_Loc;
		--RAISERROR(@Out_Err_Loc, 16, 1);
			return 0;
	END CATCH
END
GO

-- =============================================
-- OBJECT: fn_diagramobjects (SQL_SCALAR_FUNCTION)
-- =============================================
CREATE FUNCTION dbo.fn_diagramobjects() 
	RETURNS int
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		declare @id_upgraddiagrams		int
		declare @id_sysdiagrams			int
		declare @id_helpdiagrams		int
		declare @id_helpdiagramdefinition	int
		declare @id_creatediagram	int
		declare @id_renamediagram	int
		declare @id_alterdiagram 	int 
		declare @id_dropdiagram		int
		declare @InstalledObjects	int

		select @InstalledObjects = 0

		select 	@id_upgraddiagrams = object_id(N'dbo.sp_upgraddiagrams'),
			@id_sysdiagrams = object_id(N'dbo.sysdiagrams'),
			@id_helpdiagrams = object_id(N'dbo.sp_helpdiagrams'),
			@id_helpdiagramdefinition = object_id(N'dbo.sp_helpdiagramdefinition'),
			@id_creatediagram = object_id(N'dbo.sp_creatediagram'),
			@id_renamediagram = object_id(N'dbo.sp_renamediagram'),
			@id_alterdiagram = object_id(N'dbo.sp_alterdiagram'), 
			@id_dropdiagram = object_id(N'dbo.sp_dropdiagram')

		if @id_upgraddiagrams is not null
			select @InstalledObjects = @InstalledObjects + 1
		if @id_sysdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 2
		if @id_helpdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 4
		if @id_helpdiagramdefinition is not null
			select @InstalledObjects = @InstalledObjects + 8
		if @id_creatediagram is not null
			select @InstalledObjects = @InstalledObjects + 16
		if @id_renamediagram is not null
			select @InstalledObjects = @InstalledObjects + 32
		if @id_alterdiagram  is not null
			select @InstalledObjects = @InstalledObjects + 64
		if @id_dropdiagram is not null
			select @InstalledObjects = @InstalledObjects + 128
		
		return @InstalledObjects 
	END
GO

-- =============================================
-- OBJECT: fnCheckSimilar (SQL_SCALAR_FUNCTION)
-- =============================================
CREATE FUNCTION [dbo].[fnCheckSimilar]
(
    @TenDeTai NVARCHAR(4000)
)
RETURNS NVARCHAR(4000)
AS
BEGIN
    DECLARE @out NVARCHAR(4000)
    --CREATE TABLE #tbl (ThesisName NVARCHAR(500))

    --INSERT INTO @tbl (ThesisName)
    --SELECT TOP 10 ThesisName
    --FROM [dbo].[Thesises]
    --WHERE ThesisName LIKE N'%' + @TenDeTai + '%'

    --IF (SELECT COUNT(*) FROM @tbl) > 0
    --BEGIN
    --    SELECT ThesisName FROM @tbl
    --END
    --ELSE
    --BEGIN
    --    SELECT TOP 10 ThesisName
    --    FROM [dbo].[Thesises]
    --    WHERE dbo.edit_distance(@TenDeTai, ThesisName) <= 30
    --END

    SET @out = STUFF((
  --      SELECT TOP 10 ', ' + ThesisName
  --      FROM [dbo].[Thesises]
		--	WHERE ThesisName LIKE N'%' + @TenDeTai + '%'
		--UNION 
		 SELECT TOP 10 ThesisName
        FROM [dbo].[Thesises]
        WHERE dbo.edit_distance(@TenDeTai, ThesisName) <= 30
        FOR XML PATH('')
    ), 1, 2, '')

    RETURN @out
END
GO

-- =============================================
-- OBJECT: fnCheckSimiliar (SQL_SCALAR_FUNCTION)
-- =============================================
CREATE FUNCTION fnCheckSimiliar
(
    @ThesisName NVARCHAR(4000)

)
RETURNS NVARCHAR(4000)
BEGIN
	DECLARE @out NVARCHAR(4000)
	SET @out =  STUFF((--SELECT ', ' + B.HoTacGia + ' ' + B.TenTacGia
					SELECT  TOP 10 ', ' + ThesisName
					FROM  [dbo].[Thesises] WHERE ThesisName LIKE N'%' +  @ThesisName +'%'
					 FOR XML PATH('')), 1, 2, '') 
	RETURN @out

END
GO

-- =============================================
-- OBJECT: sp_alterdiagram (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROCEDURE dbo.sp_alterdiagram
	(
		@diagramname 	sysname,
		@owner_id	int	= null,
		@version 	int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
	
		declare @theId 			int
		declare @retval 		int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
		declare @ShouldChangeUID	int
	
		if(@diagramname is null)
		begin
			RAISERROR ('Invalid ARG', 16, 1)
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();	 
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		revert;
	
		select @ShouldChangeUID = 0
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		
		if(@DiagId IS NULL or (@IsDbo = 0 and @theId <> @UIDFound))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end
	
		if(@IsDbo <> 0)
		begin
			if(@UIDFound is null or USER_NAME(@UIDFound) is null) -- invalid principal_id
			begin
				select @ShouldChangeUID = 1 ;
			end
		end

		-- update dds data			
		update dbo.sysdiagrams set definition = @definition where diagram_id = @DiagId ;

		-- change owner
		if(@ShouldChangeUID = 1)
			update dbo.sysdiagrams set principal_id = @theId where diagram_id = @DiagId ;

		-- update dds version
		if(@version is not null)
			update dbo.sysdiagrams set version = @version where diagram_id = @DiagId ;

		return 0
	END
GO

-- =============================================
-- OBJECT: sp_creatediagram (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROCEDURE dbo.sp_creatediagram
	(
		@diagramname 	sysname,
		@owner_id		int	= null, 	
		@version 		int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
	
		declare @theId int
		declare @retval int
		declare @IsDbo	int
		declare @userName sysname
		if(@version is null or @diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID(); 
		select @IsDbo = IS_MEMBER(N'db_owner');
		revert; 
		
		if @owner_id is null
		begin
			select @owner_id = @theId;
		end
		else
		begin
			if @theId <> @owner_id
			begin
				if @IsDbo = 0
				begin
					RAISERROR (N'E_INVALIDARG', 16, 1);
					return -1
				end
				select @theId = @owner_id
			end
		end
		-- next 2 line only for test, will be removed after define name unique
		if EXISTS(select diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @diagramname)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end
	
		insert into dbo.sysdiagrams(name, principal_id , version, definition)
				VALUES(@diagramname, @theId, @version, @definition) ;
		
		select @retval = @@IDENTITY 
		return @retval
	END
GO

-- =============================================
-- OBJECT: sp_dropdiagram (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROCEDURE dbo.sp_dropdiagram
	(
		@diagramname 	sysname,
		@owner_id	int	= null
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
	
		if(@diagramname is null)
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end
	
		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT; 
		
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end
	
		delete from dbo.sysdiagrams where diagram_id = @DiagId;
	
		return 0;
	END
GO

-- =============================================
-- OBJECT: sp_helpdiagramdefinition (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROCEDURE dbo.sp_helpdiagramdefinition
	(
		@diagramname 	sysname,
		@owner_id	int	= null 		
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		set nocount on

		declare @theId 		int
		declare @IsDbo 		int
		declare @DiagId		int
		declare @UIDFound	int
	
		if(@diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		revert; 
	
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname;
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId ))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end

		select version, definition FROM dbo.sysdiagrams where diagram_id = @DiagId ; 
		return 0
	END
GO

-- =============================================
-- OBJECT: sp_helpdiagrams (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROCEDURE dbo.sp_helpdiagrams
	(
		@diagramname sysname = NULL,
		@owner_id int = NULL
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		DECLARE @user sysname
		DECLARE @dboLogin bit
		EXECUTE AS CALLER;
			SET @user = USER_NAME();
			SET @dboLogin = CONVERT(bit,IS_MEMBER('db_owner'));
		REVERT;
		SELECT
			[Database] = DB_NAME(),
			[Name] = name,
			[ID] = diagram_id,
			[Owner] = USER_NAME(principal_id),
			[OwnerID] = principal_id
		FROM
			sysdiagrams
		WHERE
			(@dboLogin = 1 OR USER_NAME(principal_id) = @user) AND
			(@diagramname IS NULL OR name = @diagramname) AND
			(@owner_id IS NULL OR principal_id = @owner_id)
		ORDER BY
			4, 5, 1
	END
GO

-- =============================================
-- OBJECT: sp_renamediagram (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROCEDURE dbo.sp_renamediagram
	(
		@diagramname 		sysname,
		@owner_id		int	= null,
		@new_diagramname	sysname
	
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
		declare @DiagIdTarg		int
		declare @u_name			sysname
		if((@diagramname is null) or (@new_diagramname is null))
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end
	
		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT;
	
		select @u_name = USER_NAME(@owner_id)
	
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end
	
		-- if((@u_name is not null) and (@new_diagramname = @diagramname))	-- nothing will change
		--	return 0;
	
		if(@u_name is null)
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @new_diagramname
		else
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @owner_id and name = @new_diagramname
	
		if((@DiagIdTarg is not null) and  @DiagId <> @DiagIdTarg)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end		
	
		if(@u_name is null)
			update dbo.sysdiagrams set [name] = @new_diagramname, principal_id = @theId where diagram_id = @DiagId
		else
			update dbo.sysdiagrams set [name] = @new_diagramname where diagram_id = @DiagId
		return 0
	END
GO

-- =============================================
-- OBJECT: sp_upgraddiagrams (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROCEDURE dbo.sp_upgraddiagrams
	AS
	BEGIN
		IF OBJECT_ID(N'dbo.sysdiagrams') IS NOT NULL
			return 0;
	
		CREATE TABLE dbo.sysdiagrams
		(
			name sysname NOT NULL,
			principal_id int NOT NULL,	-- we may change it to varbinary(85)
			diagram_id int PRIMARY KEY IDENTITY,
			version int,
	
			definition varbinary(max)
			CONSTRAINT UK_principal_name UNIQUE
			(
				principal_id,
				name
			)
		);


		/* Add this if we need to have some form of extended properties for diagrams */
		/*
		IF OBJECT_ID(N'dbo.sysdiagram_properties') IS NULL
		BEGIN
			CREATE TABLE dbo.sysdiagram_properties
			(
				diagram_id int,
				name sysname,
				value varbinary(max) NOT NULL
			)
		END
		*/

		IF OBJECT_ID(N'dbo.dtproperties') IS NOT NULL
		begin
			insert into dbo.sysdiagrams
			(
				[name],
				[principal_id],
				[version],
				[definition]
			)
			select	 
				convert(sysname, dgnm.[uvalue]),
				DATABASE_PRINCIPAL_ID(N'dbo'),			-- will change to the sid of sa
				0,							-- zero for old format, dgdef.[version],
				dgdef.[lvalue]
			from dbo.[dtproperties] dgnm
				inner join dbo.[dtproperties] dggd on dggd.[property] = 'DtgSchemaGUID' and dggd.[objectid] = dgnm.[objectid]	
				inner join dbo.[dtproperties] dgdef on dgdef.[property] = 'DtgSchemaDATA' and dgdef.[objectid] = dgnm.[objectid]
				
			where dgnm.[property] = 'DtgSchemaNAME' and dggd.[uvalue] like N'_EA3E6268-D998-11CE-9454-00AA00A3F36E_' 
			return 2;
		end
		return 1;
	END
GO

-- =============================================
-- OBJECT: spAPI_Decision_Get_ByDecisionID_Backup (SQL_STORED_PROCEDURE)
-- =============================================
-- [dbo].[spAPI_Decision_Get_ByDecisionID_Backup] 2651, 9 
CREATE PROC [dbo].[spAPI_Decision_Get_ByDecisionID_Backup]   
@Decision_ID INT,
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	DECLARE @Decision_SoQD NVARCHAR(100)
	DECLARE @Decision_NamQD VARCHAR(10)
	DECLARE @Decision_NganhID NVARCHAR(200)
	DECLARE @Decission_Type NVARCHAR(200)
	SELECT @Decision_SoQD = LTRIM(RTRIM(D.Decision_SoQD)), @Decision_NganhID = D.Decision_NganhID, @Decission_Type = D.Decision_Type 
	FROM Decision D 
	WHERE D.Decision_ID = @Decision_ID;

	DECLARE @tb AS TABLE(Student_ID CHAR(9)
					,Ho_SV NVARCHAR(200)
					,Ten_SV NVARCHAR(50)
					,Ngay_Sinh VARCHAR(10)
					,Noi_Sinh NVARCHAR(200)
					,Lop_ID VARCHAR(10)
					,Nganh_ID VARCHAR(10)
					,Ten_Nganh NVARCHAR(200)
					,Nien_Khoa VARCHAR(10)
					,Thesis_Name NVARCHAR(500)
					,Thesises_Prof1 NVARCHAR(500)
					,Thesises_Prof2 NVARCHAR(500)
					,ThesisesProf_Email1 NVARCHAR(500)
					,ThesisesProf_Email2 NVARCHAR(500)
					,ThesisesProf_Phone1 NVARCHAR(500)
					,ThesisesProf_Phone2 NVARCHAR(500)
					,ThesisesProf_Uni1 NVARCHAR(500)
					,ThesisesProf_Uni2 NVARCHAR(500));

	-- 1. Nếu là quyết định Hội đồng (sinh từ trang council hoặc có trong bảng HoiDong)
	IF EXISTS (SELECT 1 FROM HoiDong WHERE Decision_ID = @Decision_ID AND Is_Xoa = 0)
	BEGIN
		INSERT INTO @tb(Student_ID 
						,Ho_SV
						,Ten_SV
						,Ngay_Sinh
						,Noi_Sinh
						,Lop_ID
						,Nganh_ID
						,Ten_Nganh
						,Nien_Khoa
						,Thesis_Name
						,Thesises_Prof1
						,Thesises_Prof2
						)
		SELECT d.StudentID AS Student_ID
		, d.HoSV AS Ho_SV
		, d.TenSV AS Ten_SV
		, d.NgaySinh AS Ngay_Sinh
		, d.NoiSinh AS Noi_Sinh
		, d.LopID AS Lop_ID
		, d.NganhID AS Nganh_ID
		, d.TenNganh AS Ten_Nganh
		, d.NienKhoa AS Nien_Khoa
		, COALESCE(NULLIF(LTRIM(RTRIM(hd.DeTai)), ''), f.ThesisName, ' ') AS Thesis_Name
		, ISNULL(f.ThesisesProf1, N'') AS Thesises_Prof1
		, ISNULL(f.ThesisesProf2, N'') AS Thesises_Prof2
		FROM HoiDong hd
		INNER JOIN StudentInfo d ON hd.StudentID = d.StudentID
		OUTER APPLY (
			SELECT 
				MAX(CASE WHEN b.fieldname='ThesisName' THEN a.text_content ELSE ' ' END) ThesisName,
				MAX(CASE WHEN b.fieldname='ThesisesProf1' THEN a.text_content ELSE N'' END) ThesisesProf1,
				MAX(CASE WHEN b.fieldname='ThesisesProf2' THEN a.text_content ELSE N'' END) ThesisesProf2
			FROM flow_detail a 
			INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id 
				AND b.fieldname IN('ThesisName', 'ThesisesProf1', 'ThesisesProf2') 
			INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
			WHERE a.use_yn = 1 AND c.Student_ID = hd.StudentID
		) f
		WHERE hd.Decision_ID = @Decision_ID AND hd.Is_Xoa = 0;
	END
	ELSE
	BEGIN
		-- 2. Nếu là quyết định Giao đề tài (khớp số QĐ trong Flow_Detail.ThesisConfirmNo, xử lý lệch khoảng trắng)
		WITH StudenList AS (
			SELECT C.Student_ID 
			FROM flow_detail a 
			INNER JOIN task_detail b ON a.task_id = b.task_id 
										AND a.task_detail_id = b.task_detail_id 
										AND b.fieldname ='ThesisConfirmNo'
			INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
			WHERE b.FieldName = 'ThesisConfirmNo' 
				AND LTRIM(RTRIM(a.Text_Content)) = @Decision_SoQD
		)
		INSERT INTO @tb(Student_ID 
						,Ho_SV
						,Ten_SV
						,Ngay_Sinh
						,Noi_Sinh
						,Lop_ID
						,Nganh_ID
						,Ten_Nganh
						,Nien_Khoa
						,Thesis_Name
						,Thesises_Prof1
						,Thesises_Prof2
						)
		SELECT d.StudentID AS Student_ID
		, HoSV AS Ho_SV
		, TenSV AS Ten_SV
		, NgaySinh AS Ngay_Sinh
		, NoiSinh AS Noi_Sinh
		, LopID AS Lop_ID
		, d.NganhID AS Nganh_ID
		, TenNganh AS Ten_Nganh
		, NienKhoa AS Nien_Khoa
		, f.ThesisName AS Thesis_Name
		, f.ThesisesProf1 AS Thesises_Prof1
		, f.ThesisesProf2 AS Thesises_Prof2
		FROM StudentInfo d
		INNER JOIN StudenList e ON e.student_id = d.StudentID 
		LEFT JOIN (
			SELECT c.Student_id
				, MAX(CASE WHEN fieldname='ThesisName' THEN text_content ELSE ' ' END) ThesisName
				, MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE N'' END) ThesisesProf1
				, MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE N'' END) ThesisesProf2
			FROM flow_detail a 
			INNER JOIN task_detail b ON a.task_id = b.task_id 
				AND a.task_detail_id = b.task_detail_id 
				AND b.fieldname IN('ThesisName', 'ThesisesProf1', 'ThesisesProf2') 
			INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
			INNER JOIN StudenList e ON e.student_id = c.Student_ID
			WHERE a.use_yn = 1 
			GROUP BY c.student_id
		) f ON d.StudentID = f.student_id
		WHERE (d.NganhID = @Decision_NganhID OR ISNULL(@Decision_NganhID, 0) = 0);
	END

	DECLARE @SLHV_BANGSO INT = (SELECT COUNT(*) FROM @tb);

	-- Result set 1: Thông tin quyết định
	SELECT D.[Decision_ID]
	, CASE WHEN LEN(D.[Decision_SoQD]) > 20 OR ISNULL(D.[Decision_SoQD],'') = '' THEN N'            /QĐ-ĐHLH' ELSE D.[Decision_SoQD] END AS Decision_SoQD
	, CASE WHEN ISNULL(D.[Decision_NgayQD],'') = '' THEN '     ' ELSE D.[Decision_NgayQD] END AS Decision_NgayQD
	, CASE WHEN ISNULL(D.[Decision_ThangQD],'')= '' THEN '     ' ELSE D.[Decision_ThangQD] END Decision_ThangQD
	, CASE WHEN ISNULL(D.[Decision_NamQD],'')= '' THEN ' 20    ' ELSE D.[Decision_NamQD] END AS Decision_NamQD
	, D.[Decision_TieuDe]
	, D.[Decision_NganhID]
	, D.[Decision_Nganh]
	, D.[Decision_NienKhoa]
	, D.[Decision_Dot]
	, D.[Decision_MaSo]
	, D.[Decision_Type]
	, D.[Decision_Description]
	, D.[DecisionFile_ID]
	, D.[DecisionFile_Url]
	, D.[DecisionFile_Name]
	, D.[Decision_TemplateID]
	, D.[Decision_Status]
	, CONVERT(INT, RIGHT(D.Created_By,4)) AS Decision_NguoiTao
	, @SLHV_BANGSO AS Decision_SLHVBangSo
	, [dbo].Num2Text(@SLHV_BANGSO) AS Decision_SLHVBangChu
	FROM [dbo].[Decision] D 
	WHERE D.Decision_ID = @Decision_ID;
	
	-- Result set 2: Danh sách học viên (áp dụng cho tất cả các loại quyết định có học viên)
	WITH cte AS (
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY tb.Student_ID ORDER BY Thesises_Prof1) AS rn,
			ROW_NUMBER() OVER (ORDER BY Thesises_Prof1) AS STT,
			tb.Student_ID,
			PS.Process_ID,
			Ho_SV,
			Ten_SV,
			Ngay_Sinh,
			Noi_Sinh,
			Lop_ID,
			Ten_Nganh,
			Nien_Khoa,
			Thesis_Name,
			Thesises_Prof1,
			Thesises_Prof2
		FROM @tb tb
		LEFT JOIN Process_Student PS ON PS.Student_ID = tb.Student_ID
	)
	SELECT 
		ROW_NUMBER() OVER (ORDER BY Thesises_Prof1) AS STT,
		c.Student_ID,
		Process_ID,
		Ho_SV,
		Ten_SV,
		Ngay_Sinh,
		Noi_Sinh,
		Lop_ID,
		Ten_Nganh,
		si.NganhID,
		Nien_Khoa,
		Thesis_Name,
		Thesises_Prof1,
		Thesises_Prof2,
		gv1.Email_GV AS Email_GVHD1,
		gv1.SoDienThoai AS SoDT_GVHD1,
		gv1.CoQuanCongTac AS CoQuanCongTac_GVHD1,
		gv2.Email_GV AS Email_GVHD2,
		gv2.SoDienThoai AS SoDT_GVHD2,
		gv2.CoQuanCongTac AS CoQuanCongTac_GVHD2
	FROM cte c
	INNER JOIN StudentInfo si ON si.StudentID = c.Student_ID
	OUTER APPLY (
		SELECT TOP 1 Email_GV, SoDienThoai, CoQuanCongTac
		FROM GiangVien 
		WHERE c.Thesises_Prof1 = CONCAT(HocViHocHam, '. ', HoTenGiangVien)
	) gv1
	OUTER APPLY (
		SELECT TOP 1 Email_GV, SoDienThoai, CoQuanCongTac
		FROM GiangVien 
		WHERE c.Thesises_Prof2 = CONCAT(HocViHocHam, '. ', HoTenGiangVien)
	) gv2
	WHERE c.rn = 1
	ORDER BY Thesises_Prof1;

	-- Result set 3: File đính kèm
	SELECT [Decision_DetailID], [Decision_ID], [DecisionFile_ID], [DecisionFile_Url], [DecisionFile_Name], [Decision_Status], [Created_By], [Created_At] 
	FROM [dbo].[Decision_Detail] DT 
	WHERE DT.Decision_ID = @Decision_ID;
END
GO

-- =============================================
-- OBJECT: spAPI_FlowDetail_UpdateStatus_BK (SQL_STORED_PROCEDURE)
-- =============================================
--SELECT * FROM FLOW_DETAIL where flow

CREATE PROCEDURE [dbo].[spAPI_FlowDetail_UpdateStatus] -- '922000123', 2, 24396, 13, 124, 'C', 'GV0000611', 9
    @Student_ID VARCHAR(20),
    @Process_ID INT,
    @Flow_ID INT,
    @Task_ID INT,
    @Task_Detail_ID INT,
    @Flow_Detail_Status VARCHAR(20),
    @sys_UserID VARCHAR(9),
    @sys_SystemRight INT
AS
    BEGIN
        DECLARE @MsgError NVARCHAR(500);
        IF(@sys_SystemRight NOT IN (1, 2, 3, 9))
            BEGIN
                SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này ';
                RAISERROR(@MsgError, 16, 1);
                RETURN 0;
            END;
        DECLARE @ERRCODE INT;
        DECLARE @err_location VARCHAR(1000);
        DECLARE @task_parent INT;
        SELECT
            @task_parent = Task_Begin
        FROM Process
        WHERE Process_ID = @Process_ID;
        SET @err_location = '[FlowDetail_UpdateStatus]-Student['+CAST(@Student_ID AS VARCHAR)+']-Process['+CAST(@Process_ID AS VARCHAR)+']-Task['++CAST(@Task_ID AS VARCHAR)+']-Task_Detail['+CAST(@Task_Detail_ID AS VARCHAR)+']';
        DECLARE
            @last_flow_status    VARCHAR(100),
            @last_task_id        INT,
            @last_flow_id        INT,
            @last_task_detail_id INT,
            @NOW_STATUS          VARCHAR(20);
        BEGIN TRY
            BEGIN TRANSACTION;
            IF(NOT EXISTS (
                          SELECT
                              1
                          FROM Process_Student
                          WHERE Process_ID     = @Process_ID
                                AND Student_ID = @Student_ID
                                AND use_yn     = 1
                          )
              )
                BEGIN
                    SET @err_location = @err_location+'[PROCESS_STUDENT] Data does not exists';
                    RAISERROR(@err_location, 16, 1);
                    RETURN 0;
                END;

            --print @Flow_Detail_Status
            UPDATE
                Flow_Detail
            SET
                Flow_Detail_Status = @Flow_Detail_Status,
                [Updated_By] = @sys_UserID,
                [Updated_At] = GETDATE()
            WHERE Flow_ID            = @Flow_ID
                  AND Task_ID        = @Task_ID
                  AND Task_Detail_ID = CASE WHEN @Task_Detail_ID IS NULL
                                                 OR @Task_Detail_ID = 0 THEN Task_Detail_ID
                                            ELSE @Task_Detail_ID END;

            --PRINT CASE WHEN @Task_Detail_ID IS NULL OR @Task_Detail_ID =0 THEN 'NULL' ELSE @Task_Detail_ID END

            --exec by task_id

            --exec dbo.FLow_UpdateStatus @Student_ID, @Process_ID, @TASK_ID, @user_id, @ERRCODE out, @err_location out

            --exec full tree
            EXEC dbo.FLow_UpdateStatusFull
                @Student_ID,
                @Process_ID,
                0,
                @sys_UserID,
                @ERRCODE OUT,
                @err_location OUT;

            --checking next step of NCKH

            --update flow_detail of NCKH if not yet modify
            UPDATE
                b
            SET
                b.Flow_Status = 'W'
            FROM Flow_Detail a
                 INNER JOIN(
                           SELECT
                               Student_ID,
                               Process_ID,
                               Flow_ID,
                               Task_ID,
                               Flow_Status
                           FROM Flow
                           WHERE Student_ID     = @Student_ID
                                 AND Process_ID = @Process_ID
                                 AND use_yn     = 1
                           ) b ON b.Flow_ID                       = a.Flow_ID
                                  AND b.Task_ID                   = a.Task_ID
                 INNER JOIN Task_Detail c ON a.Task_ID            = c.Task_ID
                                             AND a.Task_Detail_ID = c.Task_Detail_ID
                                             AND c.User_Input     = 'SDH'
            WHERE a.Flow_Detail_Status = 'P'

            --and File_Name is null and text_content is null Em Tâm rào lại
            ;

            --select A.*
            UPDATE
                a
            SET
                a.Flow_Detail_Status = 'W'
            FROM Flow_Detail a
                 INNER JOIN(
                           SELECT
                               Student_ID,
                               Process_ID,
                               Flow_ID,
                               Task_ID
                           FROM Flow
                           WHERE Student_ID     = @Student_ID
                                 AND Process_ID = @Process_ID
                                 AND use_yn     = 1
                           ) b ON b.Flow_ID                       = a.Flow_ID
                                  AND b.Task_ID                   = a.Task_ID
                 INNER JOIN Task_Detail c ON a.Task_ID            = c.Task_ID
                                             AND a.Task_Detail_ID = c.Task_Detail_ID
                                             AND c.User_Input     = 'SDH'
            WHERE a.Flow_Detail_Status = 'P'

            --and File_Name is null and text_content is null Em Tâm rào lại
            ;

            --1. check last task, task_seq completed--> get next step after completed
            WITH TREE_TASK
            AS (
               SELECT
                   Task_Parent,
                   F.Task_ID,
                   0 lv,
                   Flow_ID,
                   Flow_Status,
                   Seq,
                   Task_Require,
                   Seq * 100000 X_SEQ
               FROM Flow F
               WHERE Student_ID      = @Student_ID
                     AND Process_ID  = @Process_ID
                     AND Task_Parent = @task_parent
                     AND F.use_yn    = 1
               UNION ALL
               SELECT
                   F.Task_Parent,
                   F.Task_ID,
                   T.lv+1 lv,
                   F.Flow_ID,
                   F.Flow_Status,
                   F.Seq,
                   F.Task_Require,
                   T.X_SEQ+F.Seq * 100000 /((T.lv+1)* 10) X_SEQ
               FROM Flow F
                    INNER JOIN TREE_TASK T ON F.Task_Parent = T.Task_ID
               WHERE F.use_yn = 1
               )
            SELECT /*TASK_PARENT,*/
                @last_task_id = Task_ID,
                @last_flow_id = Flow_ID,
                @last_flow_status = Flow_Status --, SEQ, TASK_REQUIRE
            FROM(
                SELECT
                    Task_Parent,
                    Task_ID,
                    Flow_ID,
                    Flow_Status,
                    X_SEQ SEQ,
                    Task_Require,
                    MIN(CASE WHEN Flow_Status = 'C' THEN 10000000000 ELSE X_SEQ END) OVER () AS MIN_SEQ
                FROM TREE_TASK A
                ) A
            WHERE SEQ = MIN_SEQ;

            --print @last_flow_status
            IF(@last_flow_status <> 'C')
                BEGIN

                    --get next flow_detail after completed. and user_input ='SDH'
                    SELECT --task_detail_id, flow_detail_status, user_input,
                        @last_task_detail_id = CASE WHEN User_Input = 'SDH'
                                                         AND Flow_Detail_Status <> 'P' THEN Task_Detail_ID
                                                    ELSE 0 END
                    FROM(
                        SELECT
                            Flow_ID,
                            a.Task_ID,
                            a.Task_Detail_ID,
                            Flow_Detail_Status,
                            Task_Detail_Seq,
                            MIN(CASE WHEN Flow_Detail_Status = 'C' THEN 1000 ELSE Task_Detail_Seq END) OVER () AS MIN_SEQ,
                            User_Input
                        FROM Flow_Detail a
                             INNER JOIN Task_Detail c ON a.Task_ID            = c.Task_ID
                                                         AND a.Task_Detail_ID = c.Task_Detail_ID
                        WHERE a.Flow_ID     = @last_flow_id
                              AND a.Task_ID = @last_task_id
                        ) a
                    WHERE MIN_SEQ = Task_Detail_Seq;

                    --PRINT @last_task_detail_id
                    IF(@last_task_detail_id IS NOT NULL AND @last_task_detail_id > 0)
                        BEGIN

                            /* update 1 task detal

update flow_detail set flow_detail_status='P', [Updated_By]='auto_next_nckh',[Updated_At]=getdate()

where flow_id= @last_flow_id and task_id =@last_task_id and task_detail_id = @last_task_detail_id

;

*/

                            --update all SDH

                            --print @Task_Detail_ID

                            --PRINT @last_task_detail_id
                            IF(@Task_Detail_ID = @last_task_detail_id)
                                BEGIN

                                    --PRINT @last_task_detail_id

                                    --PRINT @last_task_detail_id
                                    UPDATE
                                        Flow_Detail
                                    SET
                                        Flow_Detail_Status = 'P',
                                        [Updated_By] = 'auto_next_nckh',
                                        [Updated_At] = GETDATE()
                                    WHERE Flow_ID     = @last_flow_id
                                          AND Task_ID = @last_task_id
                                          AND Task_Detail_ID IN(
                                                               SELECT
                                                                   Task_Detail_ID
                                                               FROM(
                                                                   SELECT
                                                                       Flow_ID,
                                                                       a.Task_ID,
                                                                       a.Task_Detail_ID,
                                                                       Flow_Detail_Status,
                                                                       Task_Detail_Seq,
                                                                       MIN(CASE WHEN Flow_Detail_Status = 'C' THEN 1000 ELSE Task_Detail_Seq END) OVER () AS MIN_SEQ,
                                                                       User_Input,
                                                                       MIN(   CASE WHEN Flow_Detail_Status <> 'C'
                                                                                        AND User_Input <> 'SDH' THEN Task_Detail_Seq
                                                                                   ELSE 1000 END
                                                                          ) OVER () AS last_SEQ
                                                                   FROM Flow_Detail a
                                                                        INNER JOIN Task_Detail c ON a.Task_ID            = c.Task_ID
                                                                                                    AND a.Task_Detail_ID = c.Task_Detail_ID
                                                                   WHERE a.Flow_ID     = @last_flow_id
                                                                         AND a.Task_ID = @last_task_id
                                                                   ) a
                                                               WHERE MIN_SEQ             <= Task_Detail_Seq
                                                                     AND Task_Detail_Seq < last_SEQ
                                                               );
                                END;
                        END;
                    SET @NOW_STATUS = dbo.CheckStatusFlow(@Student_ID, @Process_ID, @last_flow_id, @last_task_id, 0);

                    --PRINT @NOW_STATUS

                    --set @Out_Err_Loc = @Out_Err_Loc + 'last-child--CheckStatusFlow('+@Student_ID+','+cast(@Process_ID as varchar)+','+cast(@FLOW_ID as varchar)+','+cast(@TASK_ID as varchar)+','+cast(@TASK_BEGIN as varchar)+')='+@NOW_STATUS;
                    IF(@NOW_STATUS <> ' ')
                        BEGIN
                            PRINT '@NOW_STATUS '+@NOW_STATUS;
                            PRINT @Task_Detail_ID;
                            PRINT @last_task_detail_id;
                            DECLARE @user_input VARCHAR(10);
                            SET @user_input = (
                                              SELECT
                                                  User_Input
                                              FROM Task_Detail t
                                              WHERE t.Task_Detail_ID = @last_task_detail_id
                                              );
                            IF @user_input = 'SDH' BEGIN
SET @NOW_STATUS = 'P';
END;
                            UPDATE
                                Flow
                            SET
                                Flow_Status = @NOW_STATUS,
                                [Updated_By] = 'auto_next_nckh',
                                [Updated_At] = GETDATE()
                            WHERE Process_ID     = @Process_ID
                                  AND Student_ID = @Student_ID
                                  AND Flow_ID    = @last_flow_id
                                  AND Task_ID    = @last_task_id
                                  AND use_yn     = 1;
                        END;
                END;
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            SET @ERRCODE = @@ERROR;
            SET @err_location = @err_location+ERROR_MESSAGE();
            RAISERROR(@err_location, 16, 1);
            RETURN 0;
        END CATCH;
    END;
GO

-- =============================================
-- OBJECT: spAPI_Get_FullFlow (SQL_STORED_PROCEDURE)
-- =============================================
-- [spAPI_Get_FullFlow] '917000226'
CREATE PROC [dbo].[spAPI_Get_FullFlow]
@StudentID VARCHAR(9),
@Process_ID int
AS
BEGIN
	DECLARE @TASK_BEGIN INT;

	SELECT @TASK_BEGIN = TASK_BEGIN
	FROM PROCESS_STUDENT
	WHERE STUDENT_ID= @StudentID
	and Process_ID  = @Process_ID
	AND USE_YN =1;

	WITH TREE_TASK AS(
		SELECT TASK_PARENT, F.TASK_ID, SEQ, Task_Require, 0 lv, Flow_Status, F.Flow_ID, SEQ*100000 X_SEQ, PROCESS_ID, STUDENT_ID
			FROM FLOW F 
			WHERE STUDENT_ID = @StudentID and Process_ID  = @Process_ID and F.use_yn =1 AND TASK_PARENT= @TASK_BEGIN
		UNION ALL
		SELECT F.TASK_PARENT, F.TASK_ID, F.SEQ, F.Task_Require*T.Task_Require, T.lv + 1 lv, F.Flow_Status, F.Flow_ID, T.X_SEQ+F.SEQ*100000/((T.LV+1)*10) X_SEQ, F.PROCESS_ID, F.STUDENT_ID
		FROM FLOW F 
		INNER JOIN TREE_TASK T on F.TASK_PARENT = T.TASK_ID
		WHERE  F.use_yn =1
	) 

	SELECT	PROCESS_ID, STUDENT_ID
			, A.FLOW_ID
			, A.TASK_PARENT AS Parent_Task_ID
			, B.TASK_ID AS Children_Task_ID
			, B.TASK_NAME
			, A.SEQ
			, A.Task_Require
			, A.FLOW_STATUS
			, Task_Detail_Type
			, A.LV
			----, X_SEQ,MIN(CASE WHEN FLOW_STATUS='COMPLETED' THEN 10000000 WHEN A.TASK_REQUIRE = 0 AND FLOW_STATUS ='WAIT' THEN 10000000 ELSE X_SEQ END) OVER () as MIN_SEQ
			,CASE WHEN X_SEQ = MIN(CASE WHEN FLOW_STATUS='C' THEN 10000000 WHEN A.TASK_REQUIRE = 0 AND FLOW_STATUS ='W' THEN 10000000 ELSE X_SEQ END) OVER () THEN 1 ELSE 0 END LOCK_STATUS
			, D.TASK_DETAIL_SEQ
			, D.TASK_DETAIL_DESCRIPTION
			, File_URL
			, Text_Content
			, File_Name
			, File_Type
			, C.FLOW_DETAIL_STATUS
			, USER_INPUT
			,Task_Detail_Display
			,Task_Detail_StyleDisplay
	FROM TREE_TASK A INNER JOIN TASKS B ON B.TASK_ID = A.TASK_ID
					 INNER JOIN FLOW_DETAIL C ON A.FLOW_ID = C.FLOW_ID AND A.TASK_ID = C.TASK_ID 
					 INNER JOIN TASK_DETAIL D ON C.Task_Detail_ID = D.Task_Detail_ID
	ORDER BY B.TASK_ID,A.SEQ,TASK_DETAIL_SEQ

END
GO

-- =============================================
-- OBJECT: spAPI_Get_SimiliarPaper_BK (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROC [dbo].[spAPI_Get_SimiliarPaper_BK]
@TenDeTai AS NVARCHAR(500)
AS
BEGIN

	DECLARE @tbl AS TABLE (ThesisName NVARCHAR(500), ThesisStudent NVARCHAR(500), ThesisMajor NVARCHAR(500))
	INSERT INTO @tbl(ThesisName, ThesisStudent, ThesisMajor)
	SELECT  TOP 10 ThesisName, ThesisStudent, ThesisMajor
		FROM  [dbo].[Thesises] WHERE ThesisName LIKE N'%' +  @TenDeTai +'%'
	IF (SELECT COUNT(*) FROM @tbl) >0
	BEGIN
		SELECT  ThesisName, ThesisStudent, ThesisMajor
		FROM  @tbl
	END
	ELSE
	BEGIN
		PRINT 'X'
		SELECT TOP 5 ThesisName, ThesisStudent, ThesisMajor
		FROM  [dbo].[Thesises]
		WHERE dbo.edit_distance(@TenDeTai, ThesisName) <=30
	END

END
GO

-- =============================================
-- OBJECT: spAPI_HoiDong_DeTai_Get_ThanhVien_BK (SQL_STORED_PROCEDURE)
-- =============================================
-- [dbo].[spAPI_HoiDong_DeTai_Get_ThanhVien] 37,9
create PROC [dbo].[spAPI_HoiDong_DeTai_Get_ThanhVien_BK]
@NganhID INT,
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	-- Tạo bảng tạm
	IF OBJECT_ID('tempdb..#TMPSTU') IS NOT NULL
	BEGIN
		DROP TABLE #TMPSTU
	END

	CREATE TABLE #TMPSTU  (
		Student_ID INT,
		Ho_SV NVARCHAR(255),
		Ten_SV NVARCHAR(255),
		Lop_ID VARCHAR(9),
		Nganh_ID INT,
		Ten_Nganh NVARCHAR(255),
		Nien_Khoa VARCHAR(255),
		Email VARCHAR(300),
		PhoneNumber VARCHAR(20),
		Thesis_Name NVARCHAR(255),
		Thesises_Prof1 NVARCHAR(255),
		Thesises_Prof2 NVARCHAR(255)
	);

	-- Chèn dữ liệu vào bảng tạm
	INSERT INTO #TMPSTU (Student_ID, Ho_SV, Ten_SV, Lop_ID, Nganh_ID, Ten_Nganh, Email, PhoneNumber, Nien_Khoa,  Thesis_Name, Thesises_Prof1, Thesises_Prof2)
	-- Chọn thông tin sinh viên và thông tin luận văn
	SELECT 
		d.StudentID AS Student_ID,
		HoSV AS Ho_SV,
		TenSV AS Ten_SV,
		LopID AS Lop_ID,
		NganhID AS Nganh_ID,
		TenNganh AS Ten_Nganh,
		f.Email, 
		f.PhoneNumber,
		NienKhoa AS Nien_Khoa,
		ThesisName AS Thesis_Name,
		ThesisesProf1 AS Thesises_Prof1,
		ThesisesProf2 AS Thesises_Prof2
	FROM 
		flow_detail a 
		-- Kết nối với task_detail để lấy thông tin nhiệm vụ
		INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname = 'ThesisNameDefend' --b.fieldname ='QDThanhLapHoiDongConfirm'
		-- Kết nối với flow để lấy thông tin flow
		INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
		INNER JOIN Process p ON c.Process_ID = p.Process_ID and p.Process_Action = 1

		-- Kết nối với StudentInfo để lấy thông tin sinh viên
		INNER JOIN StudentInfo d ON c.student_id = d.studentID
		-- Kết nối với truy vấn phụ để lấy thông tin luận văn
		LEFT JOIN (
			SELECT 
				c.Student_id, 
				MAX(CASE WHEN fieldname='ThesisNameDefend' THEN text_content ELSE ' ' END) ThesisName,
				--Email, PhoneNumber
				MAX(CASE WHEN fieldname='Email' THEN text_content ELSE ' ' END) Email,
				MAX(CASE WHEN fieldname='PhoneNumber' THEN text_content ELSE ' ' END) PhoneNumber,
				MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE ' ' END) ThesisesProf1,
				MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE ' ' END) ThesisesProf2
			FROM 
				flow_detail a 
				-- Kết nối với task_detail để lấy thông tin nhiệm vụ
				INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname IN ('ThesisNameDefend','Email', 'PhoneNumber', 'ThesisesProf1', 'ThesisesProf2') 
				-- Kết nối với flow để lấy thông tin flow
				INNER JOIN flow c ON a.flow_id = c.flow_id  AND c.use_yn = 1
				INNER JOIN Process p ON c.Process_ID = p.Process_ID and p.Process_Action = 1
			WHERE 
				a.use_yn = 1
			GROUP BY 
				c.student_id
		) f ON c.student_id = f.student_id
	WHERE 
		a.flow_detail_status IN ('P','C')
		AND 
		a.use_yn = 1
	UNION
	SELECT 
		d.StudentID AS Student_ID,
		HoSV AS Ho_SV,
		TenSV AS Ten_SV,
		LopID AS Lop_ID,
		NganhID AS Nganh_ID,
		TenNganh AS Ten_Nganh,
		f.Email, 
		f.PhoneNumber,
		NienKhoa AS Nien_Khoa,
		ThesisName AS Thesis_Name,
		f.ThesisesProf1 AS Thesises_Prof1,
		f.ThesisesProf2 AS Thesises_Prof2
	FROM 
		flow_detail a 
		-- Kết nối với task_detail để lấy thông tin nhiệm vụ
		INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname = 'ThesisName' --b.fieldname ='QDThanhLapHoiDongConfirm'
		-- Kết nối với flow để lấy thông tin flow
		INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
		INNER JOIN Process p ON c.Process_ID = p.Process_ID and p.Process_Action = 1

		-- Kết nối với StudentInfo để lấy thông tin sinh viên
		-- Code gốc: INNER JOIN StudentInfo d ON c.student_id = d.studentID and d.NganhID = 102
		INNER JOIN StudentInfo d ON c.student_id = d.studentID and d.NganhID IN (102, 106)
		-- Kết nối với truy vấn phụ để lấy thông tin luận văn
		LEFT JOIN (
			SELECT 
				c.Student_id, 
				MAX(CASE WHEN fieldname='ThesisName' THEN text_content ELSE ' ' END) ThesisName,
				--Email, PhoneNumber
				NULL Email,
				NULL PhoneNumber,
				MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE ' ' END) ThesisesProf1,
				MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE ' ' END) ThesisesProf2
			FROM 
				flow_detail a 
				-- Kết nối với task_detail để lấy thông tin nhiệm vụ
				INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname IN ('ThesisName', 'ThesisesProf1','ThesisesProf2') 
				-- Kết nối với flow để lấy thông tin flow
				INNER JOIN flow c ON a.flow_id = c.flow_id  AND c.use_yn = 1
				INNER JOIN Process p ON c.Process_ID = p.Process_ID and p.Process_Action = 1
			WHERE a.use_yn = 1
			GROUP BY 
				c.student_id
		) f ON c.student_id = f.student_id
			 -- Lấy thông tin ThesisesProf1 và trạng thái flow_detail_status
		LEFT JOIN (
			SELECT 
				c.student_id, 
				a.text_content AS ThesisesProf1,
				c.Flow_Status AS Flow_Status,
				a.Flow_ID
			FROM 
				flow_detail a
				INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id
				INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
			WHERE 
				b.fieldname = 'fileLyLichKhoaHoc' AND a.use_yn = 1
		) AS Prof1Data ON d.studentID = Prof1Data.student_id
	WHERE 
		Prof1Data.Flow_Status IN ('P','C')
		AND a.use_yn = 1 


	SELECT 
		ROW_NUMBER() OVER (ORDER BY Student_ID) AS 'STT'
		
		, Student_ID 
		, Ho_SV 
		, Ten_SV 
		, Lop_ID 
		, Nganh_ID 
		, Ten_Nganh 
		, Nien_Khoa 
		, Email
		, PhoneNumber
		, Thesis_Name 
		, G1.GiangVienID AS GiangVienID1
		, Thesises_Prof1 
		, G2.GiangVienID AS GiangVienID2
		, Thesises_Prof2
		, D.Decision_ID
		, D.Decision_SoQD
		, D.Decision_NgayQD
		, D.Decision_ThangQD
		, D.Decision_NamQD
		, H.HoiDongID
		, H.KetQuaHoiDong
		, H.NhanXet
		, H.DiemHoiDong
		, H.HoiDong_Status
		, D.Decision_Status
		, H.ThoiGianBaoVe
		, H.GiangVienID AS ThanhVienHoiDong_ID
		, H.HocViHocHam AS ThanhVienHoDong_HocViHocHam
		, H.HoTenGiangVien AS ThanhVienHoiDong_HoTen
		, H.ChucTrach AS ThanhVienHoiDong_ChucTrach
		FROM #TMPSTU T
			LEFT JOIN (SELECT H.HoiDongID, H.Decision_ID, H.KetQuaHoiDong, H.NhanXet, H.DiemHoiDong, H.HoiDong_Status, H.ThoiGianBaoVe, H.StudentID, TV.GiangVienID, TV.HocViHocHam, TV.HoTenGiangVien, TV.ChucTrach FROM HoiDong H INNER JOIN HoiDongThanhVien TV ON H.HoiDongID = TV.HoiDongID WHERE TV.Is_Xoa = 0 ) AS H ON H.StudentID = T.Student_ID 
			INNER JOIN Decision D ON D.Decision_ID = H.Decision_ID AND  D.Decision_Status <> 10
			LEFT JOIN GiangVien G1 ON T.Thesises_Prof1 = G1.HocViHocHam +'. ' + G1.HoTenGiangVien AND T.Nganh_ID = G1.NganhID AND G1.Is_Xoa = 0
			LEFT JOIN GiangVien G2 ON T.Thesises_Prof2 = G2.HocViHocHam +'. ' + G2.HoTenGiangVien AND T.Nganh_ID = G2.NganhID AND G2.Is_Xoa = 0
			WHERE (Nganh_ID = @NganhID) OR (@NganhID = 0)
	


END

--select * from HoiDongThanhVien where HoiDongID = 206
GO

-- =============================================
-- OBJECT: spAPI_HoiDong_Get_ByStatus (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROC [dbo].[spAPI_HoiDong_Get_ByStatus] 
AS
BEGIN
	SELECT
		[HoiDongID], [StudentID], [DeTai], [Decision_ID], [LoaiHoiDong], ThoiGianBaoVe
	FROM 
		[dbo].[HoiDong] WHERE [HoiDong_Status] = 0
END
GO

-- =============================================
-- OBJECT: spAPI_HoiDong_HocHamHocVi_Get (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROC spAPI_HoiDong_HocHamHocVi_Get
AS
BEGIN
	SELECT 'GS.'
	UNION
	SELECT 'PGS.TS.'
	UNION 
	SELECT 'TS.'
END
GO

-- =============================================
-- OBJECT: spAPI_HoiDong_Udp_TenDeTai (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROC [dbo].[spAPI_HoiDong_Udp_TenDeTai]
@Student_ID VARCHAR(9)
,@TenDeTaiMoi NVARCHAR(MAX)
,@SYS_UserID VARCHAR(9)
,@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	UPDATE HoiDong
	SET 
		DeTai = @TenDeTaiMoi
		,Updated_By = @SYS_UserID
		,Updated_At = GETDATE()
	WHERE StudentID = @Student_ID AND KetQuaHoiDong <> 2 AND Is_Xoa = 0
END
GO

-- =============================================
-- OBJECT: spAPI_Nganh_GetAll (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROC [dbo].[spAPI_Nganh_GetAll]
AS
BEGIN
	SELECT DISTINCT NganhID AS Nganh_ID, TenNganh AS Ten_Nganh FROM Nganh 

END
GO

-- =============================================
-- OBJECT: spAPI_PROCESS_STUDENT_INSERT (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROCEDURE [dbo].[spAPI_PROCESS_STUDENT_INSERT]
@Process_ID int, 
@Student_ID varchar(20),  
@Expire_Date date,
@User_Id varchar(50),
@insert_new bit
AS
BEGIN
	declare @process_student_id int; 
	declare @task_begin int;
	DECLARE @ERRCODE INT;
	DECLARE @err_location varchar(1000);
	set @err_location= 'Process['+ +cast(@Process_ID as varchar) +']-Student[' + cast(@Student_ID as varchar)+']';
	
	if(@insert_new = 1 and exists(select 1 from Process_student where Process_ID=@Process_ID and Student_id =@Student_ID and Process_Student_Status <>'STOP'))
	begin
		--RAISERROR(N'Student' + cast(@Student_ID as nvarchar) +N' đã được đăng ký trong Proceess['+cast(@Process_ID as nvarchar)+']', 16, 1);
		RAISERROR(N'Student đã được đăng ký trong Proceess', 16, 1);
		return 0;
	end

	BEGIN TRY	 
		BEGIN TRANSACTION;
		set @err_location = 'Begin Insert Process_student[0]';
		if(@insert_new <> 1)
		begin 
			 
			update Process_student
				set Process_Student_Status ='X', use_yn = 0
			 where Process_ID=@Process_ID and Student_id =@Student_ID
				and Process_Student_Status <>'C';

			 update Flow
				set Flow_Status ='X', use_yn=0
			where Process_ID=@Process_ID and Student_id =@Student_ID
				and FLOW_STATUS <>'C';			

			update FLOW_DETAIL
				set Flow_Detail_Status ='X', use_yn = 0
			where Task_id in(select TASK_ID from flow where Process_ID=@Process_ID and Student_id =@Student_ID and FLOW_STATUS ='X') 
			and Flow_Detail_Status <>'C'
			;

		end
	--Insert process_Student
		select @task_begin=task_begin from process where process_id=@Process_ID;

		INSERT INTO Process_Student
				(Process_ID ,Student_ID --,Student_Name ,Student_ClassID ,Student_DepartmentID ,Student_Major ,Student_Level ,Student_Year
				,Expire_Date ,Expire_Date_1 ,Expire_Date_2 ,Expire_Date_3
				,Process_Student_Status, use_yn, Task_Begin
				,Created_By ,Created_At ,Updated_By ,Updated_At)
			VALUES (@Process_ID, @Student_ID--, @Student_Name ,@Student_ClassID, @Student_DepartmentID, @Student_Major,@Student_Level,@Student_Year
				, @Expire_Date,null,null,null
				,'W',1, @task_begin
				,@User_Id, getdate(),@User_Id, getdate())
		;
		set @err_location = 'Ater Insert Process_student[1]';
		set @process_student_id = @@IDENTITY;		

		set @err_location = 'Begin Insert Flow[2]';
		--Insert FLOW
		with TREE_TASK as(
		select TASK_PARENT, TASK_ID, SEQ, TASK_Require, 0 lv from TASK_TASK where TASK_PARENT = @task_begin
		union all
		select a.TASK_PARENT, a.TASK_ID, a.SEQ, a.TASK_Require, b.lv + 1 lv
		from TASK_TASK a inner join TREE_TASK b on a.TASK_PARENT = b.TASK_ID
		)
		INSERT INTO Flow
				   (Process_Student_ID,Process_ID,Student_Id,TASK_PARENT, TASK_ID, Seq,Task_Require,Flow_Status,use_yn
				   ,Created_By,Created_At,Updated_By  ,Updated_At) 
		select  @process_student_id,@Process_ID,@Student_ID, a.TASK_PARENT, A.TASK_ID,A.SEQ,Task_Require,'W',1
				,@User_Id, getdate(),@User_Id, getdate()
		from TREE_TASK A
			 ;
		set @err_location = 'Begin Insert Flow_Detail[3]';
		--Insert Flow_Detail
		INSERT INTO Flow_Detail
			   (Flow_ID,Task_ID,Task_Detail_id
			   --,[File_Content],[Text_Content],[File_Name],[File_Type]
			   ,Flow_Detail_Status,use_yn
			   ,Created_By,Created_At,Updated_By,Updated_At) 
		select Flow_id, b.Task_id, b.task_detail_ID
			,'W', 1
			,@User_Id, getdate(),@User_Id, getdate()
		from flow a inner join Task_detail b on a.task_id = b.task_id
		WHERE A.Process_ID=@Process_ID AND A.Student_ID=@Student_ID
			;
		set @err_location = 'After Insert Flow_Detail[4]';
		COMMIT TRANSACTION ;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION ;
		SET @ERRCODE = @@ERROR;
		set @err_location= 'Process['+ +cast(@Process_ID as varchar) +']-Student[' + cast(@Student_ID as varchar)+']:' + @err_location;
		RAISERROR(@err_location, 16, 1);
			return 0;
	END CATCH
END
GO

-- =============================================
-- OBJECT: spAPI_SDH_DoiDeTai_FlowDetail (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROC [dbo].[spAPI_SDH_DoiDeTai_FlowDetail]
@StudentID VARCHAR(9),
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	
	DECLARE @DoiDeTai_NC_Process_ID INT = 2
	DECLARE @DoiDeTai_UD_Process_ID INT = 5
	DECLARE @DoiDeTai_NC_TaskID INT = 13
	DECLARE @DoiDeTai_UD_TaskID INT = 37
	DECLARE @ThesisName_NC_New_TaskDetail_ID INT = 122
	DECLARE @ThesisProf1_NC_New_TaskDetail_ID INT = 123
	DECLARE @ThesisProf2_NC_New_TaskDetail_ID INT = 124
	DECLARE @ThesisName_UD_New_TaskDetail_ID INT = 126
	DECLARE @ThesisProf1_UD_New_TaskDetail_ID INT = 127
	DECLARE @ThesisProf2_UD_New_TaskDetail_ID INT = 128
	DECLARE @ProcessStudentID INT
	DECLARE @FlowID INT
	
	SELECT @ProcessStudentID = Process_Stu_ID
	FROM Process_Student
	WHERE Student_ID = @StudentID 
		AND Process_ID IN (@DoiDeTai_NC_Process_ID, @DoiDeTai_UD_Process_ID)
		AND Process_Student_Status <> 'X'
	
	SELECT @FlowID = Flow_ID
	FROM Flow
	WHERE Process_Student_ID = @ProcessStudentID
	AND Task_ID IN (@DoiDeTai_NC_TaskID, @DoiDeTai_UD_TaskID)
	
	SELECT 
	    si.StudentID AS Student_ID,
	    MAX(CASE 
	        WHEN fd.Task_Detail_ID IN (@ThesisName_NC_New_TaskDetail_ID, @ThesisName_UD_New_TaskDetail_ID) 
	        THEN fd.text_content 
	    END) AS Thesis_Name_New,
	    MAX(CASE 
	        WHEN fd.Task_Detail_ID IN (@ThesisProf1_NC_New_TaskDetail_ID, @ThesisProf1_UD_New_TaskDetail_ID) 
	        THEN fd.text_content 
	    END) AS Thesises_Prof1_New,
	    MAX(CASE 
	        WHEN fd.Task_Detail_ID IN (@ThesisProf2_NC_New_TaskDetail_ID, @ThesisProf2_UD_New_TaskDetail_ID) 
	        THEN fd.text_content 
	    END) AS Thesises_Prof2_New
	FROM StudentInfo si
	LEFT JOIN flow_detail fd 
	    ON fd.Flow_ID = @FlowID
	    AND fd.use_yn = 1
	
	WHERE si.StudentID = @StudentID
	GROUP BY si.StudentID
END
GO

-- =============================================
-- OBJECT: spAPI_SDH_Get_TaskRegister_GetByStatus (SQL_STORED_PROCEDURE)
-- =============================================
-- spAPI_SDH_Get_TaskRegisterDefend  0,1,'W',9
CREATE PROC [dbo].[spAPI_SDH_Get_TaskRegister_GetByStatus]
@Nganh_Id INT,
@Process_Action INT,
@Flow_Status VARCHAR(1),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	--declare @tbl_StudentCanFilter AS TABLE (studentid VARCHAR(9))
	--insert into @tbl_StudentCanFilter(studentid)
	--select a.student_id --, c.Task_Code, b.Flow_Status
	--		from process_student a 
	--				inner join flow b on a.student_id = b.student_id and a.process_id = b.process_id and b.use_yn =1
	--				inner join Tasks c on b.Task_ID = c.Task_ID
	--		where a.use_yn = 1 and c.Task_Code IN ('ThS04','ThSUD04') and b.Flow_Status = 'W'

	DECLARE @tbl AS TABLE(Student_ID VARCHAR(9)
						, Student_Name NVARCHAR(100)
						, TenNganh NVARCHAR(200)
						, Email VARCHAR(200)
						, SoDienThoai VARCHAR(200)
						, Class_ID VARCHAR(10)
						, Nganh_ID INT
						, ThesisName NVARCHAR(500)
						, ThesisesProf1 NVARCHAR(200)
						, ThesisesProf2 NVARCHAR(200)
						, File_LyLich_ID NVARCHAR(500)
						, File_LyLich_Name NVARCHAR(500)
						, File_DangKy_ID NVARCHAR(500)
						, File_DangKy_Name NVARCHAR(500)
						, File_NhanXetGVHD1_ID NVARCHAR(500)
						, File_NhanXetGVHD1_Name NVARCHAR(500)
						, File_NhanXetGVHD2_ID NVARCHAR(500)
						, File_NhanXetGVHD2_Name NVARCHAR(500)
						, File_LuanVanPDF_ID NVARCHAR(500)
						, File_LuanVanPDF_Name NVARCHAR(500)
						, File_LuanVanWORD_ID NVARCHAR(500)
						, File_LuanVanWORD_NAME NVARCHAR(500)
						, Process_Status_Register VARCHAR(5) 
						, Process_ID INT)
		INSERT INTO @tbl(Student_ID
						, Student_Name
						, TenNganh 
						, Email
						, SoDienThoai
						, Class_ID
						, Nganh_ID
						, ThesisName
						, ThesisesProf1 
						, ThesisesProf2 
						, File_LyLich_ID
						, File_LyLich_Name
						, File_DangKy_ID
						, File_DangKy_Name
						, File_NhanXetGVHD1_ID
						, File_NhanXetGVHD1_Name
						, File_NhanXetGVHD2_ID
						, File_NhanXetGVHD2_Name
						, File_LuanVanPDF_ID
						, File_LuanVanPDF_Name
						, File_LuanVanWORD_ID
						, File_LuanVanWORD_NAME
						, Process_Status_Register
						, Process_ID)
		SELECT A.Student_ID
		, HoSV+' '+TenSV
		, N.TenNganh
		, CASE WHEN T9.FieldName = 'Email' THEN F9.Text_Content END AS Email
		, CASE WHEN T8.FieldName = 'PhoneNumber' THEN F8.Text_Content END AS PhoneNumber
		, LopID 
		, B.NganhID AS Nganh_ID
		, CASE WHEN T1.FieldName = 'ThesisNameDefend' THEN F1.Text_Content END AS ThesisName
		, CASE WHEN T10.FieldName = 'ThesisesProf1' THEN F10.Text_Content END AS ThesisesProf1
		, CASE WHEN T11.FieldName = 'ThesisesProf2' THEN F11.Text_Content END AS ThesisesProf2
		, CASE WHEN T2.FieldName = 'fileLyLichKhoaHoc' THEN F2.File_ID END AS File_LyLich_ID
		, CASE WHEN T2.FieldName = 'fileLyLichKhoaHoc' THEN F2.File_Name END AS File_LyLich_Name
		, CASE WHEN T3.FieldName = 'fileDangKyBaoVe' THEN F3.File_ID END AS File_DangKy_ID
		, CASE WHEN T3.FieldName = 'fileDangKyBaoVe' THEN F3.File_Name END AS File_DangKy_Name
		, CASE WHEN T4.FieldName = 'fileNXGVHD1' THEN F4.File_ID END AS File_NhanXetGVHD1_ID
		, CASE WHEN T4.FieldName = 'fileNXGVHD1' THEN F4.File_Name END AS File_NhanXetGVHD1_Name
		, CASE WHEN T5.FieldName = 'fileNXGVHD2' THEN F5.File_ID END AS File_NhanXetGVHD2_ID
		, CASE WHEN T5.FieldName = 'fileNXGVHD2' THEN F5.File_Name END AS File_NhanXetGVHD2_Name
		, CASE WHEN T6.FieldName = 'fileLuanVanPDF' THEN F6.File_ID END AS File_LuanVanPDF_ID
		, CASE WHEN T6.FieldName = 'fileLuanVanPDF' THEN F6.File_Name END AS File_LuanVanPDF_Name
		, CASE WHEN T7.FieldName = 'fileLuanVanWORD' THEN F7.File_ID END AS File_LuanVanWORD_ID
		, CASE WHEN T7.FieldName = 'fileLuanVanWORD' THEN F7.File_Name END AS File_LuanVanWORD_NAME
		, D.Flow_Status AS Process_Status_Register
		, A.Process_ID
	FROM Process_Student A 
			INNER JOIN StudentInfo B ON A.Student_ID = B.StudentID
			INNER JOIN Process C ON C.Process_ID = A.Process_ID AND C.Process_Action = @Process_Action 
			INNER JOIN Nganh N ON B.NganhID = N.NganhID
			INNER JOIN Flow D ON D.Process_ID = C.Process_ID 
							AND D.Student_ID = A.Student_ID  
							AND D.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Flow D1 ON D1.Process_ID = C.Process_ID 
							AND D1.Student_ID = A.Student_ID  
							AND D1.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Flow D2 ON D2.Process_ID = C.Process_ID 
							AND D2.Student_ID = A.Student_ID  
							AND D2.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Tasks E ON E.Task_ID = D.Task_ID
			INNER JOIN Flow_Detail F1 ON F1.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T1 ON T1.Task_Detail_ID = F1.Task_Detail_ID AND T1.FieldName = 'ThesisNameDefend' AND F1.Text_Content <> '' 
			INNER JOIN Flow_Detail F2 ON F2.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T2 ON T2.Task_Detail_ID = F2.Task_Detail_ID AND T2.FieldName = 'fileLyLichKhoaHoc'
			INNER JOIN Flow_Detail F3 ON F3.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T3 ON T3.Task_Detail_ID = F3.Task_Detail_ID AND T3.FieldName = 'fileDangKyBaoVe'
			INNER JOIN Flow_Detail F4 ON F4.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T4 ON T4.Task_Detail_ID = F4.Task_Detail_ID AND T4.FieldName = 'fileNXGVHD1'
			INNER JOIN Flow_Detail F5 ON F5.Flow_ID = D1.Flow_ID 
			INNER JOIN Task_Detail T5 ON T5.Task_Detail_ID = F5.Task_Detail_ID AND T5.FieldName = 'fileNXGVHD2'
			INNER JOIN Flow_Detail F6 ON F6.Flow_ID = D1.Flow_ID 
			INNER JOIN Task_Detail T6 ON T6.Task_Detail_ID = F6.Task_Detail_ID AND T6.FieldName = 'fileLuanVanPDF'
			INNER JOIN Flow_Detail F7 ON F7.Flow_ID = D1.Flow_ID 
			INNER JOIN Task_Detail T7 ON T7.Task_Detail_ID = F7.Task_Detail_ID AND T7.FieldName = 'fileLuanVanWORD'
			INNER JOIN Flow_Detail F8 ON F8.Flow_ID = D1.Flow_ID 
			INNER JOIN Task_Detail T8 ON T8.Task_Detail_ID = F8.Task_Detail_ID AND T8.FieldName = 'PhoneNumber'
			INNER JOIN Flow_Detail F9 ON F9.Flow_ID = D1.Flow_ID 
			INNER JOIN Task_Detail T9 ON T9.Task_Detail_ID = F9.Task_Detail_ID AND T9.FieldName = 'Email'
			INNER JOIN Flow_Detail F10 ON F10.Flow_ID = D2.Flow_ID 
			INNER JOIN Task_Detail T10 ON T10.Task_Detail_ID = F10.Task_Detail_ID AND T10.FieldName = 'ThesisesProf1' 
			INNER JOIN Flow_Detail F11 ON F11.Flow_ID = D2.Flow_ID 
			INNER JOIN Task_Detail T11 ON T11.Task_Detail_ID = F11.Task_Detail_ID AND T11.FieldName = 'ThesisesProf2'
			
	WHERE  A.use_yn = 1 
	AND ( @Nganh_ID = 0 OR B.NganhID = @Nganh_ID)
	--	AND (E.Task_Code = 'ThS01.1' OR E.Task_Code = 'ThSUD01.1')
		AND D.Flow_Status IN  (@Flow_Status)
		

	UNION
SELECT DISTINCT A.Student_ID
		, HoSV+' '+TenSV
		, N.TenNganh
		, NULL AS  Email
		, NULL AS  PhoneNumber
		, LopID 
		, B.NganhID AS Nganh_ID
		, CASE WHEN T1.FieldName = 'ThesisName' THEN F1.Text_Content END AS ThesisName
		, CASE WHEN T10.FieldName = 'ThesisesProf1' THEN F10.Text_Content END AS ThesisesProf1
		, CASE WHEN T11.FieldName = 'ThesisesProf2' THEN F11.Text_Content END AS ThesisesProf2
		, CASE WHEN T2.FieldName = 'fileLyLichKhoaHoc' THEN F2.File_ID END AS File_LyLich_ID
		, CASE WHEN T2.FieldName = 'fileLyLichKhoaHoc' THEN F2.File_Name END AS File_LyLich_Name
		, CASE WHEN T3.FieldName = 'fileDangKyBaoVe' THEN F3.File_ID END AS File_DangKy_ID
		, CASE WHEN T3.FieldName = 'fileDangKyBaoVe' THEN F3.File_Name END AS File_DangKy_Name
		, CASE WHEN T4.FieldName = 'fileNXGVHD1' THEN F4.File_ID END AS File_NhanXetGVHD1_ID
		, CASE WHEN T4.FieldName = 'fileNXGVHD1' THEN F4.File_Name END AS File_NhanXetGVHD1_Name
		, NULL AS File_NhanXetGVHD2_ID
		, NULL AS File_NhanXetGVHD2_Name
		, NULL AS File_LuanVanPDF_ID
		, NULL AS File_LuanVanPDF_Name
		, CASE WHEN T7.FieldName = 'fileLuanVanWORD' THEN F7.File_ID END AS File_LuanVanWORD_ID
		, CASE WHEN T7.FieldName = 'fileLuanVanWORD' THEN F7.File_Name END AS File_LuanVanWORD_NAME
		, D2.Flow_Status AS Process_Status_Register
		, A.Process_ID
	FROM Process_Student A 
			INNER JOIN StudentInfo B ON A.Student_ID = B.StudentID
			INNER JOIN Process C ON C.Process_ID = A.Process_ID AND C.Process_Action = 1 
			INNER JOIN Nganh N ON B.NganhID = N.NganhID
			INNER JOIN Flow D ON D.Process_ID = C.Process_ID 
							AND D.Student_ID = A.Student_ID  
							AND D.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Flow D1 ON D1.Process_ID = C.Process_ID 
							AND D1.Student_ID = A.Student_ID  
							AND D1.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Flow D2 ON D2.Process_ID = C.Process_ID 
							AND D2.Student_ID = A.Student_ID  
							AND D2.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Flow D3 ON D3.Process_ID = C.Process_ID 
							AND D3.Student_ID = A.Student_ID  
							AND D3.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Flow D4 ON D4.Process_ID = C.Process_ID 
							AND D4.Student_ID = A.Student_ID  
							AND D4.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Tasks E ON E.Task_ID = D.Task_ID

			INNER JOIN Flow_Detail F1 ON F1.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T1 ON T1.Task_Detail_ID = F1.Task_Detail_ID AND T1.FieldName = 'ThesisName' AND F1.Text_Content <> '' 
			INNER JOIN Flow_Detail F2 ON F2.Flow_ID = D2.Flow_ID 
			INNER JOIN Task_Detail T2 ON T2.Task_Detail_ID = F2.Task_Detail_ID AND T2.FieldName = 'fileLyLichKhoaHoc'
			INNER JOIN Flow_Detail F3 ON F3.Flow_ID = D2.Flow_ID 
			INNER JOIN Task_Detail T3 ON T3.Task_Detail_ID = F3.Task_Detail_ID AND T3.FieldName = 'fileDangKyBaoVe'
			INNER JOIN Flow_Detail F4 ON F4.Flow_ID = D2.Flow_ID 
			INNER JOIN Task_Detail T4 ON T4.Task_Detail_ID = F4.Task_Detail_ID AND T4.FieldName = 'fileNXGVHD1'
			--INNER JOIN Flow_Detail F5 ON F5.Flow_ID = D1.Flow_ID 
			--INNER JOIN Task_Detail T5 ON T5.Task_Detail_ID = F5.Task_Detail_ID AND T5.FieldName = 'fileNXGVHD2'
			--INNER JOIN Flow_Detail F6 ON F6.Flow_ID = D1.Flow_ID 
			--INNER JOIN Task_Detail T6 ON T6.Task_Detail_ID = F6.Task_Detail_ID AND T6.FieldName = 'fileLuanVanPDF'
			
			
			INNER JOIN Flow_Detail F7 ON F7.Flow_ID = D2.Flow_ID 
			INNER JOIN Task_Detail T7 ON T7.Task_Detail_ID = F7.Task_Detail_ID AND T7.FieldName = 'fileLuanVanWORD'
			--INNER JOIN Flow_Detail F8 ON F8.Flow_ID = D1.Flow_ID 
			--INNER JOIN Task_Detail T8 ON T8.Task_Detail_ID = F8.Task_Detail_ID AND T8.FieldName = 'PhoneNumber'
			--INNER JOIN Flow_Detail F9 ON F9.Flow_ID = D1.Flow_ID 
			--INNER JOIN Task_Detail T9 ON T9.Task_Detail_ID = F9.Task_Detail_ID AND T9.FieldName = 'Email'
			INNER JOIN Flow_Detail F10 ON F10.Flow_ID = D3.Flow_ID 
			INNER JOIN Task_Detail T10 ON T10.Task_Detail_ID = F10.Task_Detail_ID AND T10.FieldName = 'ThesisesProf1' 
			INNER JOIN Flow_Detail F11 ON F11.Flow_ID = D4.Flow_ID 
			INNER JOIN Task_Detail T11 ON T11.Task_Detail_ID = F11.Task_Detail_ID AND T11.FieldName = 'ThesisesProf2'
	WHERE  A.use_yn = 1
	AND (@Nganh_ID = 0 OR B.NganhID = @Nganh_ID)
	-- Nam sửa
	--AND E.Task_Code = 'ThSUD01.3'
	AND 	 D2.Flow_Status IN  (@Flow_Status)
	-- Nam thêm
	AND EXISTS (
        SELECT 1 FROM Flow F
        WHERE F.Process_ID = C.Process_ID
          AND F.Student_ID = A.Student_ID
          AND F.Process_Student_ID = A.Process_Stu_ID
		  -- Task_ID = 3 & 21 là Bước 4. Ra QĐ giao đề tài
          AND F.Task_ID IN (3, 21)
		  -- Flow_Status của Bước 4 phải là C
          AND F.Flow_Status = 'C'
	);

	-- Lọc các rows bị trùng
	WITH CTE AS (
	SELECT 
		  ROW_NUMBER() OVER (PARTITION BY Student_ID ORDER BY Student_ID DESC) AS rn
		, Student_ID
		, Student_Name
		, t2.Email
		, t2.SoDienThoai
		, Class_ID
		, Nganh_ID
		, t2.TenNganh
		, ThesisName
		, ThesisesProf1
		, ThesisesProf2
		, File_LyLich_ID
		, File_LyLich_Name
		, File_DangKy_ID
		, File_DangKy_Name
		, File_NhanXetGVHD1_ID
		, File_NhanXetGVHD1_Name
		, File_NhanXetGVHD2_ID
		, File_NhanXetGVHD2_Name
		, File_LuanVanPDF_ID
		, File_LuanVanPDF_Name
		, File_LuanVanWORD_ID
		, File_LuanVanWORD_NAME
		, Process_Status_Register
		, t2.Process_ID
		, S.NienKhoa
	FROM @tbl t2 
	INNER JOIN StudentInfo S ON S.StudentID = t2.Student_ID 
	)
	SELECT 
		  ROW_NUMBER() OVER (ORDER BY Student_ID DESC) AS STT
		, ct.Student_ID
		, Student_Name
		, ct.Email
		, ct.SoDienThoai
		, Class_ID
		, Nganh_ID
		, ct.TenNganh
		, ThesisName
		, ThesisesProf1
		, ThesisesProf2
		, File_LyLich_ID
		, File_LyLich_Name
		, File_DangKy_ID
		, File_DangKy_Name
		, File_NhanXetGVHD1_ID
		, File_NhanXetGVHD1_Name
		, File_NhanXetGVHD2_ID
		, File_NhanXetGVHD2_Name
		, File_LuanVanPDF_ID
		, File_LuanVanPDF_Name
		, File_LuanVanWORD_ID
		, File_LuanVanWORD_NAME
		, Process_Status_Register
		, Process_ID
		, ct.NienKhoa
	FROM CTE ct
	INNER JOIN StudentInfo si ON si.StudentID = ct.Student_ID
	WHERE rn = 1
	AND (si.IsXuLyHocVu = 0 OR si.IsXuLyHocVu IS NULL)
	ORDER BY Nganh_ID ASC
	
	-- Backup code 2
	--SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY  Student_ID DESC) AS STT
	--, Student_ID
	--, Student_Name
	--, t2.Email
	--, t2.SoDienThoai
	--, Class_ID
	--, Nganh_ID
	--, t2.TenNganh
	--, ThesisName
	--, ThesisesProf1
	--, ThesisesProf2
	--, File_LyLich_ID
	--, File_LyLich_Name
	--, File_DangKy_ID
	--, File_DangKy_Name
	--, File_NhanXetGVHD1_ID
	--, File_NhanXetGVHD1_Name
	--, File_NhanXetGVHD2_ID
	--, File_NhanXetGVHD2_Name
	--, File_LuanVanPDF_ID
	--, File_LuanVanPDF_Name
	--, File_LuanVanWORD_ID
	--, File_LuanVanWORD_NAME
	--, Process_Status_Register
	--, t2.Process_ID
	--, S.NienKhoa
	--FROM @tbl t2 
	--INNER JOIN StudentInfo S ON S.StudentID = t2.Student_ID 
	--ORDER BY Nganh_ID ASC

	--backup code 1
	--FROM @tbl t2 
	--ORDER BY Nganh_ID ASC
END
GO

-- =============================================
-- OBJECT: spAPI_SDH_Get_TaskRegisterTheise_X (SQL_STORED_PROCEDURE)
-- =============================================
--  [dbo].[spAPI_SDH_Get_TaskRegisterTheise_X]  0,1,'P',9
CREATE PROC [dbo].[spAPI_SDH_Get_TaskRegisterTheise_X]  -- 0,1,'P'
@Nganh_ID INT,
@Process_Action INT,
@Flow_Status VARCHAR(1),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	
	DECLARE @tbl AS TABLE(Student_ID VARCHAR(9)
						, Student_Name NVARCHAR(100)
						, Class_ID VARCHAR(10)
						, Nganh_ID INT
						, Student_Major NVARCHAR(100)
						, Student_Level NVARCHAR(20)
						, Student_Year	VARCHAR(10)
						, Task_ID INT
						, Task_Name NVARCHAR(500)
						, Flow_Status VARCHAR(5)
						, ThesisNameSuggest NVARCHAR(500)
						, ThesisesProfSuggest1 NVARCHAR(500)
						, isGVHDSigned NVARCHAR(10)
						, fileDKDeTai NVARCHAR(500)
						, ThesisesProf1 NVARCHAR(500)
						, ThesisesProf2 NVARCHAR(500)
						, NgayDangKy VARCHAR(10))
	INSERT INTO @tbl(Student_ID 
					, Student_Name 
					, Class_ID
					, Nganh_ID
					, Student_Major
					, Student_Level
					, Student_Year
					, Task_ID
					, Task_Name
					, Flow_Status
					, ThesisNameSuggest
					, ThesisesProfSuggest1
					, isGVHDSigned
					, fileDKDeTai
					, NgayDangKy)
	SELECT A.Student_ID
		, HoSV+' '+TenSV 
		, LopID 
		, B.NganhID AS Nganh_ID
		, TenNganh 
		, HeDaoTao 
		, NienKhoa 
		, D.TASK_ID
		, E.task_name
		, D.Flow_Status
		, CASE WHEN T1.FieldName = 'ThesisNameSuggest' THEN F1.Text_Content END AS ThesisNameSuggest
		, CASE WHEN T2.FieldName = 'ThesisesProfSuggest1' THEN F2.Text_Content END AS ThesisesProfSuggest1
		, CASE WHEN T4.FieldName = 'isGVHDSigned' THEN F4.Text_Content END AS isGVHDSigned
		, CASE WHEN T3.FieldName = 'fileDKDeTai' THEN F3.File_URL END AS FileDangKyDeTai
		, CONVERT(VARCHAR(10), D.Updated_At, 103) AS NgayDangKy
	FROM Process_Student A 
			INNER JOIN StudentInfo B ON A.Student_ID = B.StudentID
			INNER JOIN Process C ON C.Process_ID = A.Process_ID AND C.Process_Action = @Process_Action 
			INNER JOIN Flow D ON D.Process_ID = C.Process_ID 
							AND D.Student_ID = A.Student_ID  
							AND D.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Tasks E ON E.Task_ID = D.Task_ID
			INNER JOIN Flow_Detail F1 ON F1.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T1 ON T1.Task_Detail_ID = F1.Task_Detail_ID AND T1.FieldName = 'ThesisNameSuggest'
			INNER JOIN Flow_Detail F2 ON F2.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T2 ON T2.Task_Detail_ID = F2.Task_Detail_ID AND T2.FieldName = 'ThesisesProfSuggest1'
			INNER JOIN Flow_Detail F3 ON F3.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T3 ON T3.Task_Detail_ID = F3.Task_Detail_ID AND T3.FieldName = 'fileDKDeTai'
			INNER JOIN Flow_Detail F4 ON F4.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T4 ON T4.Task_Detail_ID = F4.Task_Detail_ID AND T4.FieldName = 'isGVHDSigned'

			
	WHERE  A.use_yn = 1  AND ( B.NganhID = @Nganh_ID OR @Nganh_ID = 0)
		AND (E.Task_Code = 'ThS01.1' OR E.Task_Code = 'ThSUD01.1')
		AND D.Flow_Status = @Flow_Status
		
	SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY  NgayDangKy DESC) AS STT
	, Student_ID 
	, Student_Name 
	, Class_ID
	, Student_Major
	, Student_Level
	, Student_Year
	, Flow_Status
	, ThesisNameSuggest
	, ThesisesProfSuggest1	
	, isGVHDSigned
	, fileDKDeTai
	, NgayDangKy
	, [DBO].[fnCheckSimilar](ThesisNameSuggest)
	FROM @tbl t2
	
END
GO

-- =============================================
-- OBJECT: spAPI_Student_Get (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROC spAPI_Student_Get
AS
BEGIN
	SELECT * FROM StudentInfo ORDER BY CREATETIME DESC
END
GO

-- =============================================
-- OBJECT: spAPI_Student_Update_StudentID_By_MaHoSo (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROC [dbo].[spAPI_Student_Update_StudentID_By_MaHoSo]
	@MaHoSo VARCHAR(20),
	@NewStudentID VARCHAR(9),
	@NienKhoa VARCHAR(10),
	@sys_UserID VARCHAR(9),
	@sys_SystemRight INT,
	@sys_GroupID INT,
	@sys_FunctionRight VARCHAR(2000)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @MsgError NVARCHAR(500);

	-- Phân quyền: FunctionRight = 2 hoặc SystemRight IN (2, 3, 9)
	IF (@sys_SystemRight NOT IN (2, 3, 9) AND CHARINDEX('[2]', ISNULL(@sys_FunctionRight, '')) = 0)
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này (Yêu cầu quyền Tiến sĩ)';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	SET @MaHoSo = LTRIM(RTRIM(@MaHoSo));
	SET @NewStudentID = LTRIM(RTRIM(@NewStudentID));
	SET @NienKhoa = LTRIM(RTRIM(@NienKhoa));

	IF (@MaHoSo IS NULL OR @MaHoSo = '')
	BEGIN
		SET @MsgError = N'Mã hồ sơ không được để trống';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	IF (@NewStudentID IS NULL OR LEN(@NewStudentID) <> 9 OR @NewStudentID LIKE '%[^0-9]%')
	BEGIN
		SET @MsgError = N'Mã học viên mới không hợp lệ. Bắt buộc phải gồm đúng 9 chữ số.';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	-- Tìm học viên theo MaHoSo hoặc StudentID (kết hợp Niên khóa nếu có)
	DECLARE @OldStudentID VARCHAR(20);
	SELECT TOP 1 @OldStudentID = StudentID
	FROM StudentInfo
	WHERE (MaHoSo = @MaHoSo OR StudentID = @MaHoSo)
	  AND (@NienKhoa IS NULL OR @NienKhoa = '' OR @NienKhoa = '0' OR NienKhoa = @NienKhoa);

	IF (@OldStudentID IS NULL)
	BEGIN
		SET @MsgError = N'Không tìm thấy học viên có mã hồ sơ: ' + @MaHoSo + CASE WHEN @NienKhoa IS NOT NULL AND @NienKhoa <> '' AND @NienKhoa <> '0' THEN N' trong niên khóa ' + @NienKhoa ELSE N'' END;
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	IF (@OldStudentID = @NewStudentID)
	BEGIN
		SET @MsgError = N'Mã học viên mới trùng với mã học viên hiện tại.';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	-- Kiểm tra NewStudentID đã tồn tại ở bản ghi khác chưa
	IF EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = @NewStudentID AND (MaHoSo <> @MaHoSo OR MaHoSo IS NULL))
	BEGIN
		SET @MsgError = N'Mã học viên ' + @NewStudentID + N' đã tồn tại trong hệ thống. Vui lòng kiểm tra lại.';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	BEGIN TRANSACTION;
	BEGIN TRY
		-- 1. Cập nhật StudentInfo (giữ nguyên MaHoSo gốc để đối soát lịch sử)
		UPDATE StudentInfo
		SET StudentID = @NewStudentID,
			UpdateUser = ISNULL(@sys_UserID, UpdateUser),
			UpdateTime = GETDATE()
		WHERE (MaHoSo = @MaHoSo OR StudentID = @OldStudentID)
		  AND (@NienKhoa IS NULL OR @NienKhoa = '' OR @NienKhoa = '0' OR NienKhoa = @NienKhoa);

		-- 2. Cập nhật Process_Student
		UPDATE Process_Student
		SET Student_ID = @NewStudentID,
			Updated_By = ISNULL(@sys_UserID, Updated_By),
			Updated_At = GETDATE()
		WHERE Student_ID = @OldStudentID;

		-- 3. Cập nhật Flow
		UPDATE Flow
		SET Student_Id = @NewStudentID
		WHERE Student_Id = @OldStudentID;

		-- 4. Cập nhật Flow_His
		UPDATE Flow_His
		SET Student_ID = @NewStudentID
		WHERE Student_ID = @OldStudentID;

		-- 5. Cập nhật Flow_Detail_His
		UPDATE Flow_Detail_His
		SET Student_ID = @NewStudentID
		WHERE Student_ID = @OldStudentID;

		-- 6. Cập nhật các bảng liên quan khác nếu có
		UPDATE Decision_Change_Thesis SET StudentID = @NewStudentID WHERE StudentID = @OldStudentID;
		UPDATE Decision_Graduate SET StudentID = @NewStudentID WHERE StudentID = @OldStudentID;
		UPDATE HoiDong SET StudentID = @NewStudentID WHERE StudentID = @OldStudentID;
		UPDATE HoiDongThanhVien SET StudentID = @NewStudentID WHERE StudentID = @OldStudentID;
		UPDATE Thesises SET StudentID = @NewStudentID WHERE StudentID = @OldStudentID;

		COMMIT TRANSACTION;

		SELECT 1 AS Success, N'Cập nhật mã học viên thành công' AS Message, @OldStudentID AS OldStudentID, @NewStudentID AS NewStudentID, @MaHoSo AS MaHoSo;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		SET @MsgError = ERROR_MESSAGE();
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END CATCH
END
GO

-- =============================================
-- OBJECT: spAPIFILE_UPLOAD_FileData (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROC [dbo].[spAPIFILE_UPLOAD_FileData]
    @sys_UserID VARCHAR(9),
    @sys_FileContent VARBINARY(MAX),
    @sys_FileName NVARCHAR(200),
    @sys_FileContentType VARCHAR(100),
    @sys_FileSize INT
AS
BEGIN
    DECLARE @FileID VARCHAR(36) = REPLACE(NEWID(), '-', '')

    INSERT INTO dbo.FileData
    (
        FileID,
        [FileName],
        BinaryContent,
        ContentType,
        Size,
        CreateUser
    )
    VALUES
    (
        @FileID,
        @sys_FileName,
        @sys_FileContent,
        @sys_FileContentType,
        @sys_FileSize,
        @sys_UserID
    )

    SELECT FILE_ID = @FileID,
           [FILE_NAME] = @sys_FileName,
           FILE_CONTENTTYPE = @sys_FileContentType,
           FILE_SIZE = @sys_FileSize,
           FILE_URL = '/FileData/' + @FileID

END
GO

-- =============================================
-- OBJECT: spJOB_DeleteFile (SQL_STORED_PROCEDURE)
-- =============================================
CREATE PROC [dbo].[spJOB_DeleteFile]
AS
BEGIN
	DECLARE @FileDangSuDung TABLE (FileID VARCHAR(100))
	
	--	Flow_Detail
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FILE_ID FROM Flow_Detail WHERE File_ID <> ''
	
	--	Decision
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  DecisionFile_ID  FROM Decision WHERE DecisionFile_ID <> ''
	
	--	HoiDong (FileNhanXetID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileNhanXetID FROM HoiDong WHERE FileNhanXetID <> ''
	
	--	HoiDong (FileKiemPhieuID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileKiemPhieuID FROM HoiDong WHERE FileKiemPhieuID <> ''
	
	--	HoiDongThanhVien (FileNhanXetID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT 	[FileNhanXetID] FROM [dbo].[HoiDongThanhVien] WHERE [FileNhanXetID] <> ''
	
	--	HoiDongThanhVien (FileDiemID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT 	 [FileDiemID] FROM [dbo].[HoiDongThanhVien] WHERE [FileDiemID] <> ''
	
	--	Decision_Detail
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  DecisionFile_ID FROM Decision_Detail WHERE DecisionFile_ID <> ''
	
	--	Flow_Detail_His
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  File_ID FROM Flow_Detail_His WHERE File_ID <> ''
	
	--	Flow_Detail_LOG
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  File_ID FROM Flow_Detail_LOG WHERE File_ID <> ''
	
	--	Flow_Detail_Old
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  File_ID FROM Flow_Detail_Old WHERE File_ID <> ''
	
	--	GiangVien (FileVanBang_ID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileVanBang_ID FROM GiangVien WHERE FileVanBang_ID <> ''
	
	--	GiangVien (FileLyLichKH_ID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileLyLichKH_ID FROM GiangVien WHERE FileLyLichKH_ID <> ''
	
	--	HoiDongThanhVien_Old (FileNhanXetID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileNhanXetID FROM HoiDongThanhVien_Old WHERE FileNhanXetID <> ''
	
	--	HoiDongThanhVien_Old (FileDiemID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileDiemID FROM HoiDongThanhVien_Old WHERE FileDiemID <> ''
	
	--	HoiDong_Old (FileNhanXetID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileNhanXetID FROM HoiDong_Old WHERE FileNhanXetID <> ''
	
	--	HoiDong_Old (FileKiemPhieuID)
	INSERT INTO @FileDangSuDung (FileID)
	SELECT  FileKiemPhieuID FROM HoiDong_Old WHERE FileKiemPhieuID <> ''

	SELECT FILEID FROM @FileDangSuDung
	SELECT FileID, FileName, CreateTime , Size
	FROM [dbo].[FileData] WHERE FileID NOT IN (SELECT FILEID FROM @FileDangSuDung)
	order by CreateTime desc
	

--	DELETE FileData WHERE FileID NOT IN (SELECT FILEID FROM @FileDangSuDung)
END
GO

-- =============================================
-- OBJECT: spSYS_Backup_Table (SQL_STORED_PROCEDURE)
-- =============================================
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
GO



    CREATE   PROCEDURE [dbo].[spAPI_WF_Instance_CreateChild]
        @sys_UserID VARCHAR(9),
        @sys_RawData NVARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ParentInstanceID BIGINT = TRY_CAST(JSON_VALUE(@sys_RawData, '$.ParentInstanceID') AS BIGINT);
        DECLARE @InstanceName NVARCHAR(200) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.InstanceName'), '')));

        IF @ParentInstanceID IS NULL OR @ParentInstanceID <= 0
        BEGIN
            RAISERROR(N'ParentInstanceID không hợp lệ.', 16, 1);
            RETURN;
        END

        IF @InstanceName = N''
        BEGIN
            RAISERROR(N'Tên nhiệm vụ con không được để trống.', 16, 1);
            RETURN;
        END

        -- Lấy thông tin từ Instance cha
        DECLARE @DefinitionID BIGINT;
        DECLARE @CategoryID INT;
        DECLARE @CreateMode VARCHAR(20);
        DECLARE @ExecutionEngine VARCHAR(20);
        DECLARE @ContractProvider VARCHAR(50);
        DECLARE @ParentName NVARCHAR(200);

        SELECT 
            @DefinitionID = DefinitionID,
            @CategoryID = CategoryID,
            @CreateMode = CreateMode,
            @ExecutionEngine = ExecutionEngine,
            @ContractProvider = ContractProvider,
            @ParentName = InstanceName
        FROM dbo.tblWF_Instance
        WHERE InstanceID = @ParentInstanceID AND [Enable] = 1;

        IF @DefinitionID IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy thông tin của nhiệm vụ cha.', 16, 1);
            RETURN;
        END

        -- Build raw data JSON cho nhiệm vụ con
        DECLARE @ChildRawData NVARCHAR(MAX);
        SET @ChildRawData = (
            SELECT 
                CreateMode = ISNULL(@CreateMode, 'TEMPLATE_FLOW'),
                InstanceName = @InstanceName,
                Description = N'Nhiệm vụ con của: ' + @ParentName,
                CategoryID = @CategoryID,
                FileMethod = 'TEMPLATE',
                ExecutionEngine = ISNULL(@ExecutionEngine, 'SMARTCA'),
                ContractProvider = ISNULL(@ContractProvider, '')
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Hứng kết quả từ Request_Create
        DECLARE @OutputTable TABLE (
            Message NVARCHAR(250),
            InstanceID BIGINT,
            InstanceName NVARCHAR(200),
            Status VARCHAR(20),
            CurrentStepOrder INT,
            CreateMode VARCHAR(20)
        );

        INSERT INTO @OutputTable (Message, InstanceID, InstanceName, Status, CurrentStepOrder, CreateMode)
        EXEC dbo.spAPI_WF_Request_Create
            @DefinitionID = @DefinitionID,
            @sys_UserID = @sys_UserID,
            @sys_RawData = @ChildRawData;

        -- Lấy ID của instance con vừa tạo
        DECLARE @ChildInstanceID BIGINT;
        SELECT TOP 1 @ChildInstanceID = InstanceID FROM @OutputTable;

        IF @ChildInstanceID IS NOT NULL AND @ChildInstanceID > 0
        BEGIN
            -- Cập nhật cột ParentInstanceID cho Instance con
            UPDATE dbo.tblWF_Instance
            SET ParentInstanceID = @ParentInstanceID
            WHERE InstanceID = @ChildInstanceID;

            -- Trả về kết quả Success cho frontend
            SELECT 
                Success = 1,
                Message = N'Tạo nhiệm vụ con thành công!',
                ChildInstanceID = @ChildInstanceID;
        END
        ELSE
        BEGIN
            RAISERROR(N'Không thể khởi tạo nhiệm vụ con.', 16, 1);
            RETURN;
        END
    END
    
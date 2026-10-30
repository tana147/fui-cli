CREATE PROCEDURE [dbo].[spAPI_WF_InstanceTask_Save]

    @sys_UserID  VARCHAR(9),

    @TaskID      BIGINT = NULL,

    @InstanceID  BIGINT,

    @StepDefID   BIGINT = NULL,

    @TaskName    NVARCHAR(250),

    @IsRequired  BIT = 0

AS

BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        -- 1. Nếu không truyền StepDefID, tự lấy StepDefID hiện hành của Instance

        IF @StepDefID IS NULL OR @StepDefID = 0

        BEGIN

            SELECT TOP (1) @StepDefID = EX.StepDefID

            FROM dbo.tblWF_StepExecution AS EX

            WHERE EX.InstanceID = @InstanceID

              AND EX.Status IN ('ACTIVE', 'SIGNING')

              AND EX.[Enable] = 1

            ORDER BY EX.ExecutionID DESC;

        END



        IF @StepDefID IS NULL

        BEGIN

            SELECT 0 AS Success, N'Không tìm thấy bước hiện tại đang hoạt động của hồ sơ này' AS Message;

            RETURN;

        END



        -- Lấy ExecutionID hiện tại

        DECLARE @ExecutionID BIGINT;

        SELECT TOP (1) @ExecutionID = EX.ExecutionID

        FROM dbo.tblWF_StepExecution AS EX

        WHERE EX.InstanceID = @InstanceID

          AND EX.Status IN ('ACTIVE', 'SIGNING')

          AND EX.[Enable] = 1

        ORDER BY EX.ExecutionID DESC;



        -- 2. Thêm mới hoặc Cập nhật

        IF @TaskID IS NULL OR @TaskID = 0

        BEGIN

            -- Thêm mới

            DECLARE @MaxSortOrder INT = 0;

            SELECT @MaxSortOrder = ISNULL(MAX(SortOrder), 0)

            FROM dbo.tblWF_InstanceTask

            WHERE InstanceID = @InstanceID

              AND StepDefID = @StepDefID

              AND [Enable] = 1;



            INSERT INTO dbo.tblWF_InstanceTask (

                ExecutionID,

                InstanceID,

                StepDefID,

                TaskName,

                Description,

                DueHours,

                IsRequired,

                Status,

                [Enable],

                CreateTime,

                CreateUser,

                UpdateTime,

                UpdateUser,

                SortOrder

            )

            VALUES (

                @ExecutionID,

                @InstanceID,

                @StepDefID,

                @TaskName,

                N'',

                24,

                @IsRequired,

                'TODO',

                1,

                GETDATE(),

                @sys_UserID,

                GETDATE(),

                @sys_UserID,

                @MaxSortOrder + 1

            );



            SELECT 1 AS Success, N'Thêm nhiệm vụ con thành công' AS Message, SCOPE_IDENTITY() AS TaskID;

        END

        ELSE

        BEGIN

            -- Cập nhật

            UPDATE dbo.tblWF_InstanceTask

            SET TaskName   = @TaskName,

                IsRequired = @IsRequired,

                UpdateTime = GETDATE(),

                UpdateUser = @sys_UserID

            WHERE TaskID   = @TaskID

              AND [Enable] = 1;



            IF @@ROWCOUNT = 0

            BEGIN

                SELECT 0 AS Success, N'Không tìm thấy nhiệm vụ con hoặc đã bị xóa' AS Message;

                RETURN;

            END



            SELECT 1 AS Success, N'Cập nhật nhiệm vụ con thành công' AS Message, @TaskID AS TaskID;

        END

    END TRY

    BEGIN CATCH

        SELECT 0 AS Success, ERROR_MESSAGE() AS Message;

    END CATCH

END



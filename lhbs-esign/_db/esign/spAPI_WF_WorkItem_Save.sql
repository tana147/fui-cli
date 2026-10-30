
CREATE PROCEDURE [dbo].[spAPI_WF_WorkItem_Save]
    @sys_UserID         VARCHAR(9),
    @WorkItemID         BIGINT           = NULL,
    @ProjectID          BIGINT,
    @ItemType           VARCHAR(20)      = 'TASK',
    @Title              NVARCHAR(500),
    @Description        NVARCHAR(MAX)    = NULL,
    @Status             VARCHAR(20)      = 'TODO',
    @Priority           VARCHAR(20)      = NULL,
    @AssigneeCode       VARCHAR(9)       = NULL,
    @DueDate            DATETIME         = NULL,
    @ParentWorkItemID   BIGINT           = NULL
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        -- Validate
        IF @ProjectID IS NULL OR @Title IS NULL OR LTRIM(RTRIM(@Title)) = ''
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'ProjectID và Title không được trống.' AS Message, NULL AS WorkItemID
            RETURN
        END

        -- Validate status
        IF @Status NOT IN ('BACKLOG', 'TODO', 'IN_PROGRESS', 'DONE', 'BLOCKED')
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Status không hợp lệ.' AS Message, NULL AS WorkItemID
            RETURN
        END

        -- Check project exists
        IF NOT EXISTS (SELECT 1 FROM dbo.tblWF_Project WHERE ProjectID = @ProjectID AND [Enable] = 1)
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Project không tồn tại.' AS Message, NULL AS WorkItemID
            RETURN
        END

        -- Check permission: phải là thành viên project hoặc admin
        IF dbo.fnWF_CheckPermission(@sys_UserID, 'admin-all,project-manage') = 0
           AND NOT EXISTS (
               SELECT 1 FROM dbo.tblWF_ProjectMember
               WHERE ProjectID = @ProjectID AND EmployeeCode = @sys_UserID AND [Enable] = 1
           )
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Bạn không có quyền thao tác trong project này.' AS Message, NULL AS WorkItemID
            RETURN
        END

        IF @WorkItemID IS NULL OR @WorkItemID = 0
        BEGIN
            -- ────── INSERT ──────
            BEGIN TRANSACTION

            -- Auto-gen IssueKey: ProjectCode-NextSeq
            DECLARE @IssueKey NVARCHAR(30) = NULL
            DECLARE @ProjectCode VARCHAR(20)
            SELECT @ProjectCode = Code FROM dbo.tblWF_Project WHERE ProjectID = @ProjectID AND [Enable] = 1

            IF @ProjectCode IS NOT NULL
            BEGIN
                DECLARE @NextSeq INT
                UPDATE dbo.tblWF_Project SET IssueSeq = ISNULL(IssueSeq, 0) + 1 WHERE ProjectID = @ProjectID
                SELECT @NextSeq = IssueSeq FROM dbo.tblWF_Project WHERE ProjectID = @ProjectID
                SET @IssueKey = @ProjectCode + '-' + CAST(@NextSeq AS VARCHAR(10))
            END

            -- Default SortOrder = max + 1
            DECLARE @MaxSort INT = 0
            SELECT @MaxSort = ISNULL(MAX(SortOrder), 0) FROM dbo.tblWF_WorkItem
            WHERE ProjectID = @ProjectID AND Status = @Status AND [Enable] = 1

            INSERT INTO dbo.tblWF_WorkItem
            (
                ProjectID, ItemType, Title, Description, Status, Priority,
                AssigneeCode, DueDate, SortOrder, ParentWorkItemID, IssueKey,
                CreateUser, CreateTime, Enable
            )
            VALUES
            (
                @ProjectID, ISNULL(@ItemType, 'TASK'), LTRIM(RTRIM(@Title)), @Description,
                ISNULL(@Status, 'TODO'), @Priority, @AssigneeCode, @DueDate,
                @MaxSort + 1, @ParentWorkItemID, @IssueKey,
                @sys_UserID, GETDATE(), 1
            )

            DECLARE @NewID BIGINT = SCOPE_IDENTITY()
            COMMIT TRANSACTION

            SELECT CAST(1 AS BIT) AS Success, N'Đã tạo nhiệm vụ.' AS Message, @NewID AS WorkItemID, @IssueKey AS IssueKey
        END
        ELSE
        BEGIN
            -- ────── UPDATE ──────
            IF NOT EXISTS (SELECT 1 FROM dbo.tblWF_WorkItem WHERE WorkItemID = @WorkItemID AND [Enable] = 1)
            BEGIN
                SELECT CAST(0 AS BIT) AS Success, N'Nhiệm vụ không tồn tại.' AS Message, @WorkItemID AS WorkItemID
                RETURN
            END

            UPDATE dbo.tblWF_WorkItem
            SET Title            = LTRIM(RTRIM(@Title)),
                Description      = @Description,
                Status           = ISNULL(@Status, Status),
                Priority         = @Priority,
                AssigneeCode     = @AssigneeCode,
                DueDate          = @DueDate,
                ParentWorkItemID = @ParentWorkItemID,
                UpdateUser       = @sys_UserID,
                UpdateTime       = GETDATE()
            WHERE WorkItemID = @WorkItemID AND [Enable] = 1

            SELECT CAST(1 AS BIT) AS Success, N'Đã cập nhật nhiệm vụ.' AS Message, @WorkItemID AS WorkItemID
        END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message, NULL AS WorkItemID
    END CATCH
END
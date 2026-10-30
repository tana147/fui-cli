
-- 7.2 Project_Save — Insert (cần quyền project-create) / Update (LEAD hoặc project-manage)
CREATE   PROCEDURE [dbo].[spAPI_WF_Project_Save]
    @sys_UserID  VARCHAR(9),
    @ProjectID   BIGINT        = NULL,   -- NULL = tạo mới
    @Code        VARCHAR(20),
    @Name        NVARCHAR(200),
    @Description NVARCHAR(500) = NULL,
    @Icon        VARCHAR(100)  = NULL,
    @Color       VARCHAR(20)   = NULL,
    @Status      VARCHAR(20)   = 'ACTIVE'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @Code = UPPER(LTRIM(RTRIM(@Code)));
        IF @Code = '' OR @Name IS NULL OR LTRIM(RTRIM(@Name)) = ''
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Mã và tên project không được trống.' AS Message, NULL AS ProjectID;
            RETURN;
        END
        -- Mã chỉ gồm chữ hoa, số, gạch dưới (_) và gạch nối (-)
        IF @Code LIKE '%[^A-Z0-9_-]%'
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Mã project chỉ gồm chữ hoa, số, _ và - (vd HD, N_TD_01, LHBS-TD01).' AS Message, NULL AS ProjectID;
            RETURN;
        END

        IF @ProjectID IS NULL
        BEGIN
            -- INSERT — cần quyền tạo
            IF dbo.fnWF_CheckPermission(@sys_UserID, 'admin-all,project-create') = 0
            BEGIN
                SELECT CAST(0 AS BIT) AS Success, N'Bạn không có quyền tạo project.' AS Message, NULL AS ProjectID;
                RETURN;
            END
            IF EXISTS (SELECT 1 FROM dbo.tblWF_Project WHERE Code = @Code AND [Enable] = 1)
            BEGIN
                SELECT CAST(0 AS BIT) AS Success, N'Mã project đã tồn tại.' AS Message, NULL AS ProjectID;
                RETURN;
            END

            BEGIN TRANSACTION;
            INSERT INTO dbo.tblWF_Project (Code, Name, Description, Icon, Color, OwnerCode, IssueSeq, Status, [Enable], CreateUser, CreateTime)
            VALUES (@Code, @Name, @Description, @Icon, @Color, @sys_UserID, 0, ISNULL(@Status, 'ACTIVE'), 1, @sys_UserID, GETDATE());
            DECLARE @NewID BIGINT = SCOPE_IDENTITY();
            -- Người tạo = LEAD
            EXEC dbo.spWF_ProjectMember_AutoAdd @ProjectID = @NewID, @EmployeeCode = @sys_UserID, @Role = 'LEAD', @sys_UserID = @sys_UserID;
            COMMIT TRANSACTION;

            SELECT CAST(1 AS BIT) AS Success, N'Đã tạo project.' AS Message, @NewID AS ProjectID;
        END
        ELSE
        BEGIN
            -- UPDATE — LEAD của project hoặc có quyền quản trị
            DECLARE @IsLead INT = CASE WHEN EXISTS (
                SELECT 1 FROM dbo.tblWF_ProjectMember
                WHERE ProjectID = @ProjectID AND EmployeeCode = @sys_UserID AND Role = 'LEAD' AND [Enable] = 1
            ) THEN 1 ELSE 0 END;
            IF @IsLead = 0 AND dbo.fnWF_CheckPermission(@sys_UserID, 'admin-all,project-manage') = 0
            BEGIN
                SELECT CAST(0 AS BIT) AS Success, N'Bạn không có quyền sửa project này.' AS Message, @ProjectID AS ProjectID;
                RETURN;
            END
            IF EXISTS (SELECT 1 FROM dbo.tblWF_Project WHERE Code = @Code AND ProjectID <> @ProjectID AND [Enable] = 1)
            BEGIN
                SELECT CAST(0 AS BIT) AS Success, N'Mã project đã tồn tại.' AS Message, @ProjectID AS ProjectID;
                RETURN;
            END

            UPDATE dbo.tblWF_Project
            SET Code = @Code, Name = @Name, Description = @Description, Icon = @Icon, Color = @Color,
                Status = ISNULL(@Status, Status), UpdateUser = @sys_UserID, UpdateTime = GETDATE()
            WHERE ProjectID = @ProjectID AND [Enable] = 1;

            SELECT CAST(1 AS BIT) AS Success, N'Đã cập nhật project.' AS Message, @ProjectID AS ProjectID;
        END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message, NULL AS ProjectID;
    END CATCH
END
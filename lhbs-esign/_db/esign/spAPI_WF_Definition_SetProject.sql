
-- 9.1 Definition_SetProject — gán/gỡ 1 workflow vào project (LEAD hoặc project-manage)
CREATE   PROCEDURE [dbo].[spAPI_WF_Definition_SetProject]
    @sys_UserID   VARCHAR(9),
    @DefinitionID BIGINT,
    @ProjectID    BIGINT = NULL   -- NULL = gỡ khỏi project
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @ProjectID IS NOT NULL
        BEGIN
            DECLARE @IsLead INT = CASE WHEN EXISTS (
                SELECT 1 FROM dbo.tblWF_ProjectMember
                WHERE ProjectID = @ProjectID AND EmployeeCode = @sys_UserID AND Role = 'LEAD' AND [Enable] = 1
            ) THEN 1 ELSE 0 END;
            IF @IsLead = 0 AND dbo.fnWF_CheckPermission(@sys_UserID, 'admin-all,project-manage') = 0
            BEGIN
                SELECT CAST(0 AS BIT) AS Success, N'Bạn không có quyền gắn workflow vào project này.' AS Message;
                RETURN;
            END
            IF NOT EXISTS (SELECT 1 FROM dbo.tblWF_Project WHERE ProjectID = @ProjectID AND [Enable] = 1)
            BEGIN
                SELECT CAST(0 AS BIT) AS Success, N'Project không tồn tại.' AS Message;
                RETURN;
            END
        END

        UPDATE dbo.tblWF_Definition
        SET ProjectID = @ProjectID, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE DefinitionID = @DefinitionID AND [Enable] = 1;

        SELECT CAST(1 AS BIT) AS Success,
               CASE WHEN @ProjectID IS NULL THEN N'Đã gỡ workflow khỏi project.' ELSE N'Đã gắn workflow vào project.' END AS Message;
    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END

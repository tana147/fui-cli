CREATE   PROCEDURE [dbo].[spAPI_WF_Definition_SetProjectOrder]
    @sys_UserID VARCHAR(9),
    @ProjectID  BIGINT,
    @OrderJSON  NVARCHAR(MAX)   -- [{"DefinitionID":123,"SortOrder":0}, ...]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Quyền: LEAD của project HOẶC admin-all/project-manage (giống SetProject)
        DECLARE @IsLead INT = CASE WHEN EXISTS (
            SELECT 1 FROM dbo.tblWF_ProjectMember
            WHERE ProjectID = @ProjectID AND EmployeeCode = @sys_UserID AND Role = 'LEAD' AND [Enable] = 1
        ) THEN 1 ELSE 0 END;

        IF @IsLead = 0 AND dbo.fnWF_CheckPermission(@sys_UserID, 'admin-all,project-manage') = 0
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Bạn không có quyền sắp xếp quy trình trong project này.' AS Message;
            RETURN;
        END

        UPDATE D
        SET D.ProjectSortOrder = J.SortOrder,
            D.UpdateUser = @sys_UserID,
            D.UpdateTime = GETDATE()
        FROM dbo.tblWF_Definition AS D
        INNER JOIN OPENJSON(@OrderJSON)
            WITH (DefinitionID BIGINT '$.DefinitionID', SortOrder INT '$.SortOrder') AS J
            ON J.DefinitionID = D.DefinitionID
        WHERE D.ProjectID = @ProjectID AND D.[Enable] = 1;

        SELECT CAST(1 AS BIT) AS Success, N'Đã lưu thứ tự quy trình.' AS Message;
    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END
CREATE PROCEDURE [dbo].[spAPI_WF_Template_GetList]
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền truy cập mẫu
    IF dbo.fnWF_CheckPermission(@sys_UserID, 'template-view,workflow-create') = 0
    BEGIN
        RAISERROR(N'Bạn không có quyền lấy danh sách mẫu.', 16, 1);
        RETURN;
    END

    SELECT
        T.TemplateID,
        T.TemplateName,
        T.FileName,
        T.FileUrl,
        T.FileType,
        T.VersionNo,
        T.PlaceholderJSON,
        T.SignatureSlotsJSON,
        T.Description,
        T.IsActive,
        (
            SELECT COUNT(1)
            FROM dbo.tblWF_StepDefinition AS S
            WHERE S.TemplateID = T.TemplateID
              AND S.[Enable] = 1
        ) AS WorkflowCount,
        T.CreateUser,
        T.CreateTime,
        T.UpdateUser,
        T.UpdateTime
    FROM dbo.tblWF_Template AS T
    WHERE T.[Enable] = 1
    ORDER BY T.CreateTime DESC, T.TemplateID DESC;
END

CREATE PROCEDURE [dbo].[spAPI_WF_Template_Delete]
    @TemplateID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.tblWF_StepDefinition AS S
        WHERE S.TemplateID = @TemplateID
          AND S.[Enable] = 1
    )
    BEGIN
        RAISERROR(N'Không thể xóa template đang được dùng trong workflow.', 16, 1);
        RETURN;
    END

    UPDATE dbo.tblWF_Template
    SET [Enable] = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE TemplateID = @TemplateID
      AND [Enable] = 1;

    SELECT
        Message = N'Đã xóa mềm template thành công.',
        TemplateID = @TemplateID;
END

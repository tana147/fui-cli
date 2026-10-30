CREATE PROCEDURE [dbo].[spAPI_WF_Definition_Delete]
    @DefinitionID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.tblWF_Instance AS I
        WHERE I.DefinitionID = @DefinitionID
          AND I.Status IN ('RUNNING', 'WAITING_ME')
          AND I.[Enable] = 1
    )
    BEGIN
        RAISERROR(N'Không thể xóa luồng đang có phiên chạy.', 16, 1);
        RETURN;
    END

    UPDATE dbo.tblWF_Definition
    SET [Enable] = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE DefinitionID = @DefinitionID
      AND [Enable] = 1;

    SELECT
        Message = N'Đã xóa mềm workflow thành công.',
        DefinitionID = @DefinitionID;
END

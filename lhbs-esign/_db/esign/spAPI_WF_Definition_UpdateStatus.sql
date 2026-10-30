CREATE PROCEDURE [dbo].[spAPI_WF_Definition_UpdateStatus]
    @DefinitionID BIGINT,
    @IsActive BIT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblWF_Definition
    SET IsActive = @IsActive,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE DefinitionID = @DefinitionID
      AND [Enable] = 0;

    SELECT
        Message = CASE WHEN @IsActive = 1 THEN N'Đã kích hoạt workflow thành công.' ELSE N'Đã tắt workflow thành công.' END,
        DefinitionID = @DefinitionID,
        IsActive = @IsActive;
END

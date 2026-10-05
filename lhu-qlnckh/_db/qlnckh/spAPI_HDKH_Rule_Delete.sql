CREATE  PROCEDURE spAPI_HDKH_Rule_Delete
    @RuleID INT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY

        -- B1: Xóa (mềm) các điều kiện con trước
        UPDATE dbo.tblHDKH_Rule_Condition
        SET 
            IsDeleted = 1,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
        WHERE RuleID = @RuleID AND IsDeleted = 0;

        -- B2: Xóa (mềm) bản ghi quy tắc cha
        UPDATE dbo.tblHDKH_Rule_Definition
        SET 
            IsDeleted = 1,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
        WHERE RuleID = @RuleID AND IsDeleted = 0;

        COMMIT TRANSACTION;
        SELECT Message = N'Xóa Quy tắc thành công.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;

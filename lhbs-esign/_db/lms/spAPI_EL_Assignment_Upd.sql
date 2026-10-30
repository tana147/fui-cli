

-- Cập nhật spAPI_EL_Assignment_Upd để hỗ trợ cập nhật liên kết chương trình học
CREATE PROC [dbo].[spAPI_EL_Assignment_Upd]
    @AssignmentID INT,
    @Title NVARCHAR(500),
    @Instructions NVARCHAR(2000),
    @IsPublic BIT,
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET @SYS_USERID = [dbo].[fn_GetUser_LMS](@SYS_USERID);
    
    UPDATE dbo.tblEL_Assignments
    SET
        Title = @Title,
        Instructions = @Instructions,
        IsPublic = @IsPublic,
        UpdateUser = @SYS_USERID,
        UpdateTime = GETDATE()
    WHERE AssignmentID = @AssignmentID;END;


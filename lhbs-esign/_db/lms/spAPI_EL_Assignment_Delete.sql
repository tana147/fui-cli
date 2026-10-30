 --  [dbo].[spAPI_EL_Assignment_Delete] '994', 'NA0000022'
CREATE PROC [dbo].[spAPI_EL_Assignment_Delete]
    @AssignmentID INT,
    @SYS_USERID VARCHAR(9)
AS
BEGIN
   SET @SYS_USERID = [dbo].[fn_GetUser_LMS](@SYS_USERID);
    IF ( 
         @SYS_USERID <> (
			SELECT TOP 1 CreateUser FROM dbo.tblEL_Assignments WHERE AssignmentID = @AssignmentID AND IsDeleted = 0
		 )
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền xóa bài tập này. Chỉ người tạo bài mới có thể thực hiện thao tác xóa.', 16, 1)
        RETURN
    END

    -- Xóa mềm bài tập
    UPDATE dbo.tblEL_Assignments
    SET 
        IsDeleted = 1,
        UpdateTime = GETDATE(),
        UpdateUser = @SYS_USERID
    WHERE AssignmentID = @AssignmentID
END
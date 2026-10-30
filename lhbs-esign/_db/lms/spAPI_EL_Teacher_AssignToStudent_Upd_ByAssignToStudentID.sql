CREATE PROC [dbo].[spAPI_EL_Teacher_AssignToStudent_Upd_ByAssignToStudentID]
    @AssignToStudentID INT
  , @DueDate         DATETIME
  , @LimitAssigned   INT
  , @SYS_USERID      VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblEL_AssignToStudent
    SET    DueDate = @DueDate
         , LimitAssigned = @LimitAssigned
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           AssignToStudentID = @AssignToStudentID;
END;
CREATE PROC spAPI_EL_Teacher_AssignToClass_Upd_ByAssignToClassID
    @AssignToClassID INT
  , @DueDate         DATETIME
  , @LimitAssigned   INT
  , @SYS_USERID      VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblEL_AssignToClass
    SET    DueDate = @DueDate
         , LimitAssigned = @LimitAssigned
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           AssignToClassID = @AssignToClassID;
END;
CREATE PROC [dbo].[spAPI_EL_Assignment_Get_By_KhoiID_MonHocID]
    @KhoiID     INT
  , @MonHocID   INT
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    SELECT AssignmentID
         , MonHocID
         , KhoiID
         , Tuan
         , TuanHocID
         , Chuong
         , Title
         , Instructions
         , AssignmentConfig
         , AssignmentConfig_NoAnswer
         , MaxScore
         , NienKhoa
         , HocKi
         , IsDev
         , IsDeleted
         , IsBlockCopy_Paste
         , IsPublic
         , IsCopy
         , CopyFromAssignmentID
         , CopyFromUserID
         , CopyTime
         , CreateTime
         , CreateUser
         , UpdateTime
         , UpdateUser
		 , IntegrationSource
    FROM
           dbo.tblEL_Assignments
    WHERE
           IsDeleted = 0
      AND  KhoiID     = @KhoiID
      AND  MonHocID   = @MonHocID;
END;
CREATE PROC [dbo].[spAPI_PH_Thang_Parent_Confirm_Ins]
    @Lop_NhanXetThangID INT
  , @HSLopID            INT
  , @Parent_Comment     NVARCHAR(2000)
  , @SYS_USERID         VARCHAR(9)
AS
BEGIN

    UPDATE dbo.tblNhanXetThang
    SET    Parent_Comment = @Parent_Comment
         , ParentConfirmUser = @SYS_USERID
         , ParentConfirmTime = GETDATE()
    WHERE
           HSLopID           = @HSLopID
      AND  Lop_NhanXetThangID = @Lop_NhanXetThangID;


    UPDATE [dbo].[tblHocSinhYKienThang]
    SET    YKienPhuHuynh = @Parent_Comment
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           HSLopID           = @HSLopID
      AND  Lop_NhanXetThangID = @Lop_NhanXetThangID;

END;

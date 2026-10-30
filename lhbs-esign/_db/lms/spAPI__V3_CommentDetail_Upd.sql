CREATE PROC [dbo].[spAPI__V3_CommentDetail_Upd]
    @CommentDetailID      INT
  , @CommentDetailName_VI NVARCHAR(500)
  , @CommentDetailName_EN NVARCHAR(500)
  , @SYS_USERID           VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblCommentDetail
    SET    CommentDetailName_VI = @CommentDetailName_VI
         , CommentDetailName_EN = @CommentDetailName_EN
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           CommentDetailID = @CommentDetailID;

   
END;

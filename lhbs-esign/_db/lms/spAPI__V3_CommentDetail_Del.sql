CREATE PROC [dbo].[spAPI__V3_CommentDetail_Del]
    @CommentDetailID INT
  , @SYS_USERID      VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblCommentDetail
    SET    Enable = 0
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           CommentDetailID = @CommentDetailID;

   
END;

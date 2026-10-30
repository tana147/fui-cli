CREATE PROC [dbo].[spAPI__V3_CommentGroup_Del]
    @CommentGroupID INT
  , @SYS_USERID     VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblCommentGroup
    SET    [Enable] = 0
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           CommentGroupID = @CommentGroupID;

END;

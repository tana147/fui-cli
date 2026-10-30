CREATE PROC [dbo].[spAPI__V3_CommentGroup_Upd]
    @CommentGroupID      INT
  , @MonHocID            INT
  , @CommentGroupName_VI NVARCHAR(500)
  , @CommentGroupName_EN NVARCHAR(500)
  , @SYS_USERID          VARCHAR(9)
AS
BEGIN

    UPDATE dbo.tblCommentGroup
    SET    CommentGroupName_VI = @CommentGroupName_VI
         , CommentGroupName_EN = @CommentGroupName_EN
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           CommentGroupID = @CommentGroupID
      AND  MonHocID        = @MonHocID;

  
END;

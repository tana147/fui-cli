CREATE PROC [dbo].[spAPI__V3_CommentDetail_Ins]
    @CommentGroupID       INT
  , @CommentDetailName_VI NVARCHAR(500)
  , @CommentDetailName_EN NVARCHAR(500)
  , @SYS_USERID           VARCHAR(9)
AS
BEGIN
    INSERT INTO dbo.tblCommentDetail
    (
        CommentGroupID
      , CommentDetailName_VI
      , CommentDetailName_EN
      , Enable
      , CreateUser
      , CreateTime
    )
    VALUES
    (
        @CommentGroupID       -- CommentGroupID - int
      , @CommentDetailName_VI -- CommentDetailName_VI - nvarchar(500)
      , @CommentDetailName_EN -- CommentDetailName_EN - nvarchar(500)
      , 1                     -- Enable - bit
      , @SYS_USERID           -- CreateUser - varchar(20)
      , GETDATE()             -- CreateTime - datetime
    );



END;

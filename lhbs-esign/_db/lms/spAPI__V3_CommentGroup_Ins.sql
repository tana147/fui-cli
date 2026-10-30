CREATE PROC [dbo].[spAPI__V3_CommentGroup_Ins]
    @MonHocID            INT
  , @CommentGroupName_VI NVARCHAR(500)
  , @CommentGroupName_EN NVARCHAR(500)
  , @SYS_USERID          VARCHAR(9)
AS
BEGIN


    INSERT INTO dbo.tblCommentGroup
    (
        CommentGroupName_VI
      , CommentGroupName_EN
      , MonHocID
      , Enable
      , CreateUser
      , CreateTime
    )
    VALUES
    (
        @CommentGroupName_VI
      , @CommentGroupName_EN -- CommentGroupName_EN - nvarchar(300)
      , @MonHocID            -- MonHocID - int
      , 1                    -- Enable - bit
      , @SYS_USERID          -- CreateUser - varchar(20)
      , GETDATE()            -- CreateTime - datetime
    );


  
END;

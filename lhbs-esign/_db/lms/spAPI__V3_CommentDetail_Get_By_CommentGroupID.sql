CREATE PROC [dbo].[spAPI__V3_CommentDetail_Get_By_CommentGroupID] @CommentGroupID INT
AS
BEGIN
   SELECT CommentDetailID
                     , CommentGroupID
                     , CommentDetailName_VI
                     , CommentDetailName_EN
                FROM
                       dbo.tblCommentDetail
                WHERE
                       [Enable]      = 1
                  AND  CommentGroupID = @CommentGroupID
              

END;

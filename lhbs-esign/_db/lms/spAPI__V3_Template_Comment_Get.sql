
CREATE PROCEDURE [dbo].[spAPI__V3_Template_Comment_Get]
	@MonHocID int
	AS 
	BEGIN
		SELECT * FROM tblCommentGroup where MonHocID = @MonHocID and Enable= 1

		SELECT * FROM tblCommentDetail dt
			inner join tblCommentGroup cmg on cmg.CommentGroupID = dt.CommentGroupID
		where cmg.MonHocID = @MonHocID AND dt.Enable = 1
	END


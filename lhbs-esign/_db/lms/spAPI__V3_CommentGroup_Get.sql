CREATE PROC [dbo].[spAPI__V3_CommentGroup_Get] @MonHocID INT
AS
BEGIN
     SELECT             cm.CommentGroupID
                     , cm.CommentGroupName_VI
                     , cm.CommentGroupName_EN
                     , cm.MonHocID
                     , mh.MonHocName
                     , COUNT(dt.CommentDetailID) as SoLuongMau
                FROM
                       dbo.tblCommentGroup cm
                       INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = cm.MonHocID
                       LEFT JOIN [dbo].[tblCommentDetail] dt on dt.CommentGroupID = cm.CommentGroupID and dt.Enable = 1
                WHERE
                       cm.[Enable] = 1
                  AND  cm.MonHocID  = @MonHocID
                GROUP BY    cm.CommentGroupID
                     , cm.CommentGroupName_VI
                     , cm.CommentGroupName_EN
                     , cm.MonHocID
                     , mh.MonHocName
                ORDER BY
                       cm.CommentGroupID DESC
END;

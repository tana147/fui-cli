CREATE PROC [dbo].[spAPI_Get_FlowDetail_OldTree] @Flow_ID INT
AS
BEGIN
    SELECT 
           A.Flow_Detail_ID
         , A.Flow_ID
         , A.Task_ID
         , B.Task_Detail_Seq
         , B.Task_Detail_ID
         , B.Task_Detail_Description
         , B.Task_Detail_Type
         , A.File_URL
         , A.File_ID
         , A.Text_Content
         , A.File_Name
         , A.File_Type
         , B.FieldName
         , A.Flow_Detail_Status
         , B.User_Input
         , B.Task_Detail_Display
         , B.Task_Detail_StyleDisplay
         , B.Data_Exp
         , B.UI_Component
         , B.FN_Check
         , B.[AllowNull]
         , B.AllowFileType
         , B.Task_Help
    FROM
           dbo.Flow_Detail            A
           INNER JOIN dbo.Task_Detail B ON A.Task_Detail_ID = B.Task_Detail_ID
    WHERE
           A.Flow_ID = @Flow_ID
      AND A.USE_YN = 0
    ORDER BY
           B.Task_Detail_Seq, A.Flow_Detail_ID ASC;
END;
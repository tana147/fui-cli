
 -- [dbo].[spAPI_Get_FlowDetail] 6932
CREATE PROC [dbo].[spAPI_Get_FlowDetail]
@Flow_ID int
AS
BEGIN

	 SELECT Flow_Detail_ID
			, Flow_ID
			, A.Task_ID
			, B.Task_Detail_Seq
			, B.Task_Detail_ID
			, B.Task_Detail_Description
			, B.Task_Detail_Type
			, File_URL
			, File_ID
			, Text_Content
			, File_Name
			, File_Type
			, Flow_Detail_Status
			, B.FieldName
			, B.User_Input
			, B.Task_Detail_Display
			, B.Task_Detail_StyleDisplay
			, B.Data_Exp
			, B.UI_Component
			, B.FN_Check
			, B.[AllowNull]
			, B.AllowFileType
			, B.Task_Help
            , B.SubGroup
	 FROM FLOW_DETAIL A 
		INNER JOIN TASK_DETAIL B ON A.TASK_DETAIL_ID = B.TASK_DETAIL_ID
	 WHERE A.FLOW_ID= @Flow_ID 
			AND A.USE_YN =1 AND B.USE_YN = 1
			AND B.Task_Detail_Display = 1
	 ORDER BY B.TASK_DETAIL_SEQ

END

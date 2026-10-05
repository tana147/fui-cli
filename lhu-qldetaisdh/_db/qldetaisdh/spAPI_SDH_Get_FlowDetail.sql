CREATE PROC [dbo].[spAPI_SDH_Get_FlowDetail]
@Flow_ID int
AS
BEGIN
	;WITH RankedFlowDetail AS (
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
			, FieldName
			, B.User_Input
			, B.Task_Detail_Display
			, B.Task_Detail_StyleDisplay
			, B.Data_Exp
			, B.UI_Component
			, B.FN_Check
			, B.[AllowNull]
			, B.AllowFileType
			, B.Task_Help
			, ROW_NUMBER() OVER (
				PARTITION BY A.Task_Detail_ID 
				ORDER BY 
					CASE WHEN (A.Text_Content IS NOT NULL AND RTRIM(LTRIM(A.Text_Content)) <> '') OR (A.File_ID IS NOT NULL AND RTRIM(LTRIM(A.File_ID)) <> '') THEN 1 ELSE 2 END,
					A.USE_YN DESC,
					A.Flow_Detail_ID DESC
			) AS rn
		FROM FLOW_DETAIL A 
			INNER JOIN TASK_DETAIL B ON A.TASK_DETAIL_ID = B.TASK_DETAIL_ID
		WHERE A.FLOW_ID = @Flow_ID 
			AND B.USE_YN = 1
	)
	SELECT Flow_Detail_ID
		, Flow_ID
		, Task_ID
		, Task_Detail_Seq
		, Task_Detail_ID
		, Task_Detail_Description
		, Task_Detail_Type
		, File_URL
		, File_ID
		, Text_Content
		, File_Name
		, File_Type
		, Flow_Detail_Status
		, FieldName
		, User_Input
		, Task_Detail_Display
		, Task_Detail_StyleDisplay
		, Data_Exp
		, UI_Component
		, FN_Check
		, [AllowNull]
		, AllowFileType
		, Task_Help
	FROM RankedFlowDetail
	WHERE rn = 1
	ORDER BY Task_Detail_Seq;
END
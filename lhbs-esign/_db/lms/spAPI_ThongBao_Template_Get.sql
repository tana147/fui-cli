CREATE PROC [dbo].[spAPI_ThongBao_Template_Get]
AS
BEGIN
    SELECT  
		tt_b.ThongBao_TemplateID,
		ttt.TypeTitle	as 	Title	,
		tt_b.TemplateContent	,
		tt_b.List_ParamContentID,
		tt_b.ThongBao_TypeID,
		IsSendME
	FROM dbo.tblEL_ThongBao_Template AS tt_b
	INNER JOIN dbo.tblEL_ThongBao_Template_Type ttt on ttt.ThongBao_TypeID = tt_b.ThongBao_TypeID
	WHERE tt_b.IsDeleted = 0
END
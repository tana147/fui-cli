CREATE PROC spAPI_ThongBao_Template_Del
 @ThongBao_TemplateID	int
	,@SYS_USERID				VARCHAR(9)
AS
BEGIN
    UPDATE tblEL_ThongBao_Template
	SET
		IsDeleted = 1,
		UpdateUser = @SYS_USERID,
		UpdateTime = GETDATE()
    WHERE ThongBao_TemplateID = @ThongBao_TemplateID
END
CREATE PROC [dbo].[spAPI_ThongBao_Template_Upd_ByThongBao_TemplateID]
    @ThongBao_TemplateID INT
  , @Title               NVARCHAR(200)
  , @TemplateContent     NVARCHAR(MAX)
  , @List_ParamContentID NVARCHAR(200)
  , @ThongBao_TypeID     INT
  , @IsSendME            BIT
  , @SYS_USERID          VARCHAR(9)
AS
BEGIN
    UPDATE tb_t
    SET    TemplateContent = @TemplateContent
         , List_ParamContentID = @List_ParamContentID
         , ThongBao_TypeID = @ThongBao_TypeID
         , IsSendME = @IsSendME
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    FROM
           dbo.tblEL_ThongBao_Template AS tb_t
    WHERE
           ThongBao_TemplateID = @ThongBao_TemplateID;
END;
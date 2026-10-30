CREATE PROC [dbo].[spAPI_ThongBao_Template_Ins]
    @Title               NVARCHAR(200)
  , @TemplateContent     NVARCHAR(MAX)
  , @List_ParamContentID NVARCHAR(1000)
  , @ThongBao_TypeID     INT
  , @IsSendME			 BIT
  , @SYS_USERID          VARCHAR(9)
AS
BEGIN
    INSERT INTO tblEL_ThongBao_Template
    (
       TemplateContent
      , List_ParamContentID
      , ThongBao_TypeID
	  , IsSendME
      , CreateUser
      , CreateTime
      , IsDeleted
    )
    VALUES
    (
        @TemplateContent
      , @List_ParamContentID
      , @ThongBao_TypeID
	  , @IsSendME
      , @SYS_USERID
      , GETDATE()
      , 0
    );
END;
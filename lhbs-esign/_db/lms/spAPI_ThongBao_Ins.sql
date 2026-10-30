CREATE PROC [dbo].[spAPI_ThongBao_Ins]
    @ResourceID        INT
  , @ResourceType VARCHAR(20)
  , @ThongBao_TemplateID INT
  , @NguoiNhan           VARCHAR(9)
  , @SYS_USERID			VARCHAR(9)
AS
BEGIN 
	SET @SYS_USERID = dbo.fn_GetUser_LMS(@SYS_USERID)

    INSERT INTO dbo.tblEL_ThongBao
    (
       ThongBao_TemplateID
	  , ResourceID
	  , ResourceType
      , NguoiNhan
      , ThoiGianNhan
	  , NguoiGiao
	  , ThoiGianGiao
    )
    VALUES
    (
        @ThongBao_TemplateID -- ThongBao_TemplateID - int 
	  , @ResourceID
	  , @ResourceType
      , @NguoiNhan           -- ThoiGianNhan - datetime
      , GETDATE()            -- IsDeleted - bit
	  , @SYS_USERID
	  , GETDATE()
    );
END;
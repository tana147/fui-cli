-- EXEC [dbo].[spAPI_PhuHuynh_View] 37412, 2167,'23300048'
CREATE PROC [dbo].[spAPI_PhuHuynh_View] --37412, 2167,'23300048'
    @HSLopID            INT
  , @Lop_NhanXetThangID INT
  , @SYS_USERID         VARCHAR(9)
AS
BEGIN
    UPDATE [dbo].[tblHocSinhYKienThang]
    SET    LuotXem = ISNULL(LuotXem, 0) + 1
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           @HSLopID          = @HSLopID
      AND  Lop_NhanXetThangID = @Lop_NhanXetThangID;

    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO [dbo].[tblHocSinhYKienThang]
        (
            HSLopID
          , Lop_NhanXetThangID
          , LuotXem
          , TrangThai
          , Enable
          , PHConfirm
          , PHConfirmTime
          , CreateUser
          , CreateTime
        )
        VALUES
        (
            @HSLopID
          , @Lop_NhanXetThangID
          , 1
          , 0
          , 1
          , @SYS_USERID
          , GETDATE()
          , @SYS_USERID
          , GETDATE()
        );
    END;

    --Set lại Is_Viewed
    --DECLARE @Is_Viewed BIT = 0;
    --SELECT @Is_Viewed = Is_Viewed
    --FROM
    --       dbo.tblNhanXetThang
    --WHERE
    --       HSLopID           = @HSLopID
    --  AND  Lop_NhanXetThangID = @Lop_NhanXetThangID;

    --IF (
    --       @Is_Viewed = 0
    --  OR   @Is_Viewed IS NULL
    --   )
    --BEGIN
        UPDATE dbo.tblNhanXetThang
        SET    Is_Viewed = 1
             , ParentConfirmUser = @SYS_USERID
             , ParentConfirmTime = GETDATE()
        WHERE
               HSLopID           = @HSLopID
          AND  Lop_NhanXetThangID = @Lop_NhanXetThangID;
   -- END;
END;


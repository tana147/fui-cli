CREATE PROC spAPI_KhoaCotDiem_TinhTrang_Upd_ByKhoaCotDiem
    @KhoaCotDiemID INT
  , @TinhTrang     BIT
  , @LyDo          NVARCHAR(1000)
  , @SYS_USERID    VARCHAR(9)
AS
BEGIN
    DECLARE @OldTinhTrang BIT;

    -- Lấy trạng thái cũ
    SELECT @OldTinhTrang = TinhTrang
    FROM
           dbo.tblKhoaCotDiem
    WHERE
           KhoaCotDiemID = @KhoaCotDiemID;

    -- Kiểm tra: nếu đang khóa mà mở khóa lại thì phải nhập lý do
    IF (
           @OldTinhTrang = 1
     AND   @TinhTrang = 0
       )
    BEGIN
        IF (
               @LyDo IS NULL
          OR   LTRIM(RTRIM(@LyDo)) = ''
           )
        BEGIN
            RAISERROR(N'Vui lòng nhập lý do khi mở khóa.', 16, 1);
            RETURN;
        END;
    END;

    DECLARE @Table_Log_KCD TABLE
    (
        KhoaCotDiemID INT
    );

    -- Insert log
    INSERT INTO dbo.tbl_LOG_KhoaCotDiem
    (
        KhoaCotDiemID
      , TinhTrang
      , LyDo
      , Enable
      , CreateUser
      , CreateTime
    )
    OUTPUT Inserted.Log_KhoaCotDiemID
    INTO @Table_Log_KCD
    VALUES
    (
        @KhoaCotDiemID
      , @TinhTrang
      , @LyDo
      , 1
      , @SYS_USERID
      , GETDATE()
    );

    -- Update
    UPDATE dbo.tblKhoaCotDiem
    SET    TinhTrang = @TinhTrang
         , Log_KhoaCotDiemID =
           (
               SELECT TOP 1
                      KhoaCotDiemID
               FROM
                      @Table_Log_KCD
           )
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           KhoaCotDiemID = @KhoaCotDiemID;
END;
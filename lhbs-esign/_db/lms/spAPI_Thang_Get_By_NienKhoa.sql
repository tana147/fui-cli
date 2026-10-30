CREATE PROC spAPI_Thang_Get_By_NienKhoa
AS
BEGIN
    DECLARE @Thang_BatDau INT = 8;
    DECLARE @Thang_KetThuc INT = 5;
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();
    DECLARE @Index INT = 0;
    DECLARE @Thang INT;
    DECLARE @Nam INT;

    DECLARE @Table_Thang TABLE
    (
        Thang_HienThi NVARCHAR(200)
      , Thang         INT
      , Nam           INT
      , NienKhoa      INT
    );

    WHILE (@Index < 10) -- 10 tháng từ tháng 8 năm hiện tại đến tháng 5 năm sau
    BEGIN
        SET @Thang = @Thang_BatDau + @Index;
        SET @Nam = @NienKhoa;

        -- Nếu tháng vượt quá 12, chuyển sang năm sau
        IF @Thang > 12
        BEGIN
            SET @Thang = @Thang - 12;
            SET @Nam = @NienKhoa + 1;
        END;

        INSERT INTO @Table_Thang
        (
            Thang_HienThi
          , Thang
          , Nam
          , NienKhoa
        )
        VALUES
        (
            FORMAT(@Thang, '00') + '/' + CAST(@Nam AS NVARCHAR) -- Hiển thị dạng MM/YYYY
          , @Thang
          , @Nam
          , @NienKhoa
        );

        SET @Index = @Index + 1;
END;

    -- Trả kết quả
    SELECT Thang_HienThi
         , Thang
         , Nam
         , NienKhoa
    FROM
           @Table_Thang;
END;

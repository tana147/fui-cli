
CREATE PROCEDURE [dbo].[fn_CalFomular]
(
    @formular NVARCHAR(MAX), 
    @studentId VARCHAR(50), 
    @lopid INT, 
    @monhoclopid INT,
    @Result NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
    DECLARE @ResultString NVARCHAR(MAX) = @formular;

    -- Thay thế các mã cột điểm bằng giá trị thực tế
    SELECT @ResultString = REPLACE(@ResultString, MaCotDiem, CAST(KetQuaDanhGia_VI AS NVARCHAR))
    FROM  
    (
        SELECT 
            KetQuaDanhGia_VI, 
            MaCotDiem
        FROM 
            [tblKetQuaHocTap] a 
        INNER JOIN 
            [TemplateBangDiemChiTiet] b 
        ON 
            a.CotDiemID = b.CotDiemID 
            AND b.GiaTriCotDiem = 'number'
        WHERE 
            a.HocSinhID = @studentId
            AND a.lopid = @lopid
            AND a.monhoclopid = @monhoclopid
            AND CHARINDEX(MaCotDiem, @formular) > 0
    ) kq;

    -- Thực thi biểu thức động
    DECLARE @DynamicSQL NVARCHAR(MAX) = N'SELECT @ResultOut = ' + @ResultString;

    BEGIN TRY
        EXEC sp_executesql @DynamicSQL, N'@ResultOut NVARCHAR(MAX) OUTPUT', @ResultOut = @Result OUTPUT;
    END TRY
    BEGIN CATCH
        SET @Result = 'Error in formula: ' + ERROR_MESSAGE();
    END CATCH;
END;

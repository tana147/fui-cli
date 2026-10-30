CREATE FUNCTION fn_GetNienKhoa_HienTai ()
RETURNS INT
AS
BEGIN
    DECLARE @NienKhoa INT;

    SELECT TOP 1 @NienKhoa = NienKhoa 
    FROM [dbo].[tblNienKhoa] 
    WHERE [IsActive] = 1 
    ORDER BY NienKhoa DESC;

    RETURN @NienKhoa
END;

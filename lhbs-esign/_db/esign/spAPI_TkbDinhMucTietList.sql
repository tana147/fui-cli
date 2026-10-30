CREATE PROCEDURE spAPI_TkbDinhMucTietList
    @Khoi VARCHAR(2) = '',
    @Keyword NVARCHAR(100) = '',
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT dm.ID, dm.MaMon, m.TenMon, dm.Khoi, dm.SoTietTuan
    FROM tblTKB_DinhMucTiet dm
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = dm.MaMon
    WHERE dm.Enable = 1
      AND (@Khoi = '' OR dm.Khoi = @Khoi)
      AND (@Keyword = '' OR m.TenMon LIKE '%' + @Keyword + '%' OR dm.MaMon LIKE '%' + @Keyword + '%')
    ORDER BY dm.Khoi, m.TenMon;
END
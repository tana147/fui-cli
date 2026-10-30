CREATE PROCEDURE spAPI_TkbMonHocList
    @Keyword    nvarchar(100),
    @sys_UserID varchar(9)
AS
BEGIN
    SELECT MaMon, TenMon, HeSo, BatBuocXepDoi, UuTienXepDoi
    FROM tblTKB_MonHoc
    WHERE Enable = 1
      AND (@Keyword = '' OR TenMon LIKE '%' + @Keyword + '%' OR MaMon LIKE '%' + @Keyword + '%')
    ORDER BY TenMon
END

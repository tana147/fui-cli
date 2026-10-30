CREATE PROCEDURE spAPI_TkbMonQuyTacList
    @Keyword    nvarchar(100),
    @sys_UserID varchar(9)
AS
BEGIN
    SELECT q.ID, q.MaMon, m.TenMon, q.Khoi, q.LoaiQuyTac, q.ThamSo, q.GhiChu, q.Enable
    FROM tblTKB_MonQuyTac q
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = q.MaMon
    WHERE (@Keyword = '' OR q.MaMon LIKE '%' + @Keyword + '%' OR q.LoaiQuyTac LIKE '%' + @Keyword + '%' OR m.TenMon LIKE '%' + @Keyword + '%')
    ORDER BY q.MaMon, q.Khoi
END

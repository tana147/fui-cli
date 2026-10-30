CREATE PROCEDURE spAPI_TkbLopList
    @Khoi       varchar(2),
    @Keyword    nvarchar(100),
    @sys_UserID varchar(9)
AS
BEGIN
    SELECT MaLop, Khoi, ChuongTrinhDaoTao, CoPhongTruyenThong, LaLopGoc, LopGocMa
    FROM tblTKB_Lop
    WHERE Enable = 1
      AND (@Khoi = '' OR Khoi = @Khoi)
      AND (@Keyword = '' OR MaLop LIKE '%' + @Keyword + '%')
    ORDER BY Khoi, MaLop
END

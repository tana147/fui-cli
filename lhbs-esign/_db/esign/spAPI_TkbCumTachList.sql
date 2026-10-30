CREATE PROCEDURE spAPI_TkbCumTachList
    @Keyword NVARCHAR(100) = '',
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ct.ID, ct.MaCumTach, ct.Khoi, ct.TenCum, ct.GhiChu, ct.Enable,
           (SELECT COUNT(*) FROM tblTKB_CumTach_LopNguon WHERE CumTachID = ct.ID) AS SoLopNguon,
           (SELECT COUNT(*) FROM tblTKB_CumTach_NhomCon WHERE CumTachID = ct.ID) AS SoNhomCon,
           (SELECT STRING_AGG(MaLop, ',') FROM tblTKB_CumTach_LopNguon WHERE CumTachID = ct.ID) AS LopNguonCsv,
           (SELECT STRING_AGG(MaLop, ',') FROM tblTKB_CumTach_NhomCon WHERE CumTachID = ct.ID) AS NhomConCsv
    FROM tblTKB_CumTach ct
    WHERE ct.Enable = 1
      AND (@Keyword = '' OR ct.MaCumTach LIKE '%' + @Keyword + '%' OR ct.TenCum LIKE '%' + @Keyword + '%')
    ORDER BY ct.Khoi, ct.MaCumTach;
END

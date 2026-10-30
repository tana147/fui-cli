CREATE PROCEDURE spAPI_TkbGVCamTuyetDoiTuanList
    @MaGV VARCHAR(9) = '',
    @TuanTu INT = NULL,
    @TuanDen INT = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT g.ID, g.Tuan, g.MaGV, gv.HoTen, g.Thu, g.Buoi, g.Tiet, g.LyDo
    FROM tblTKB_GVCamTuyetDoi_Tuan g
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = g.MaGV
    WHERE (@MaGV = '' OR g.MaGV = @MaGV)
      AND (@TuanTu IS NULL OR g.Tuan >= @TuanTu)
      AND (@TuanDen IS NULL OR g.Tuan <= @TuanDen)
    ORDER BY g.Tuan DESC, gv.HoTen, g.Thu;
END

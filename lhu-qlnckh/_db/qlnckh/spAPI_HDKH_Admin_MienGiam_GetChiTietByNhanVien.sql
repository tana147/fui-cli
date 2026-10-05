CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_MienGiam_GetChiTietByNhanVien]
    @NamHoc INT,
    @NhanVienID VARCHAR(9),
    @sys_UserID VARCHAR(9)
AS
    BEGIN
        SET NOCOUNT ON;
        SELECT
            mg.MienGiamID,
            mg.NhanVienID,
            mg.NamHoc,
            mg.SoGioMienGiam,
            mg.LyDo,
            mg.SoQuyetDinh,
            mg.FileID,
            f.FileName,
            mg.CreateTime,
            mg.CreateUser
        FROM dbo.tblHDKH_MienGiam mg
             LEFT JOIN dbo.FileData f ON f.FileID = mg.FileID
        WHERE mg.NamHoc         = @NamHoc
              AND mg.NhanVienID = @NhanVienID
              AND mg.IsDeleted  = 0
        ORDER BY mg.MienGiamID;
    END;

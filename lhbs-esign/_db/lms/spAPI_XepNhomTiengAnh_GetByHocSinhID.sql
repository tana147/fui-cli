
CREATE PROCEDURE [dbo].[spAPI_XepNhomTiengAnh_GetByHocSinhID]
    @HocSinhID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ID,
        HocSinhID,
        LopCu,
        Ho,
        Ten,
        NgaySinh,
        Phai,
        SDT,
        CASE WHEN LoaiHocSinh = 'moi' THEN Doc ELSE NULL END NgonNgu,
		CASE WHEN LoaiHocSinh = 'cu' THEN Doc ELSE NULL END Doc,
        Nghe,
        Noi,
        Viet,
        Chung,
        TongDiem,
        Diem_Cambridge,
        CEFR_Nghe,
        CEFR_Language,
        CEFR_Viet,
        CEFR_Noi,
        CEFR_Tong,
        GhiChu,
        XepNhomTiengAnh,
        LoaiHocSinh
    FROM dbo.tbl_XepNhomTiengAnh
    WHERE HocSinhID = @HocSinhID;
END;

CREATE PROCEDURE [dbo].[spAPI_HocLieu_GetTree_ByMonHocLop]
    @MonHocLopID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        HocLieuID,
        TenHocLieu,
        LoaiHocLieu,
        ParentID,
        NoiDung,
		ThuTu,
		@MonHocLopID as MonHocLopID
    FROM 
        dbo.tblHocLieu
    WHERE 
        MonHocLopID = @MonHocLopID
    ORDER BY 
        -- Sắp xếp để các mục gốc (ParentID IS NULL) lên đầu
        -- Sau đó sắp xếp theo ThuTu và TenHocLieu
        ISNULL(ParentID, 0), ThuTu, TenHocLieu;
END
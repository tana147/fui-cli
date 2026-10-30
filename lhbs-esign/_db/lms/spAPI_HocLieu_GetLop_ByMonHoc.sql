
CREATE PROCEDURE [dbo].[spAPI_HocLieu_GetLop_ByMonHoc] --44,''
    @MonHocID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Giả sử bạn có bảng tblMonHocLop liên kết giữa Môn và Lớp
    -- Query này cần được điều chỉnh theo cấu trúc DB thực tế của bạn
    SELECT DISTINCT
        k.KhoiID LopID,
        k.KhoiID TenLop,
        @MonHocID MonHocLopID -- ID này rất quan trọng để lấy cây học liệu
    FROM 
        dbo.tblLop l
    INNER JOIN 
        dbo.tblMonHocLop mhl ON l.LopID = mhl.LopNhomID AND l.NienKhoa = mhl.NienKhoa
	INNER JOIN 
        dbo.tblKhoi k ON k.KhoiID = l.KhoiID
    WHERE 
        mhl.MonHocID = @MonHocID
    ORDER BY 
        k.KhoiID 
END